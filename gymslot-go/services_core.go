package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
)

// jsonMarshal helper (dipakai audit).
func jsonMarshal(v interface{}) ([]byte, error) { return json.Marshal(v) }

// resolveSpreadsheetID — nama fungsi sengaja sama dengan Apps Script.
// Mengembalikan nama DATABASE per-gym (padanan spreadsheet_id).
func (h *Handler) resolveSpreadsheetID(userID string, payload map[string]interface{}) (string, *APIError) {
	gymID, _ := payload["gym_id"].(string)
	if gymID == "" {
		return "", apiErr(CodeValidationError, "gym_id wajib ada")
	}
	gym, aerr := h.gymByID(gymID)
	if aerr != nil {
		return "", aerr
	}
	m, err := h.queryRow(`SELECT role, status FROM `+h.cfg.ControlDB+`.memberships WHERE user_id = ? AND gym_id = ?`, userID, gymID)
	if err != nil {
		return "", apiErr(CodeTenantAccess, "Anda bukan anggota gym ini")
	}
	status, _ := m["status"].(string)
	if status != "Active" {
		return "", apiErr(CodeTenantAccess, "Keanggotaan tidak aktif")
	}
	role, _ := m["role"].(string)
	if gymDB, ok := gym["database"].(string); ok && gymDB != "" {
		h.role = role
		return gymDB, nil
	}
	return "", apiErr(CodeGoogleDisconnect, "Database gym belum dibuat")
}

// gymByID mengembalikan baris gym atau GYM_NOT_FOUND.
func (h *Handler) gymByID(gymID string) (map[string]interface{}, *APIError) {
	row, err := h.queryRow(`SELECT gym_id, owner_user_id, name, address, phone, contact_email, description,
		logo_url, timezone, status, `+"`database`"+`, created_at, updated_at
		FROM `+h.cfg.ControlDB+`.gyms WHERE gym_id = ?`, gymID)
	if err != nil {
		return nil, apiErr(CodeGymNotFound, "Gym tidak ditemukan")
	}
	return row, nil
}

// audit menulis audit log (gagal log tidak boleh memutus alur utama).
func (h *Handler) audit(gymID, actor, action, resourceType, resourceID string, detail map[string]interface{}) {
	dj := ""
	if detail != nil {
		if b, err := json.Marshal(detail); err == nil {
			dj = string(b)
		}
	}
	table := h.cfg.ControlDB + ".audit_logs"
	if h.gymDB != "" && gymID != "" && gymID != "control" {
		table = h.gymDB + ".audit_logs"
	}
	_, _ = h.db.Exec(`INSERT INTO `+table+` (gym_id, actor_user_id, action, resource_type, resource_id, detail, created_at)
		VALUES (?,?,?,?,?,?,?)`, gymID, actor, action, resourceType, resourceID, dj, NowUTC())
}

// ============ auth.google / auth.me / auth.logout ============

func (h *Handler) handleAuthGoogle(req *apiRequest) (map[string]interface{}, string, *APIError) {
	claims, aerr := h.verifyIDToken(req.Auth.IDToken)
	if aerr != nil {
		return nil, "", aerr
	}
	user, aerr := h.upsertUser(claims)
	if aerr != nil {
		return nil, "", aerr
	}
	tok, aerr := h.createSession(user["user_id"].(string))
	if aerr != nil {
		return nil, "", aerr
	}
	user["session_token"] = tok
	return user, "Login berhasil", nil
}

func (h *Handler) handleAuthMe(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	user := h.userByID(uid)
	if user == nil {
		return nil, "", apiErr(CodeAuthInvalid, "Pengguna tidak ditemukan")
	}
	return user, "", nil
}

func (h *Handler) handleAuthLogout(req *apiRequest) (map[string]interface{}, string, *APIError) {
	if _, aerr := h.requireSession(req); aerr != nil {
		return nil, "", aerr
	}
	h.revokeSession(req.Auth.SessionToken)
	return map[string]interface{}{"success": true}, "Logout berhasil", nil
}

// ============ gyms.* ============

func (h *Handler) handleGymsCreate(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	p := req.Payload
	name := str(p, "name", 255)
	if name == "" {
		return nil, "", validation("Nama gym wajib diisi")
	}
	now := NowUTC()
	gymID := fmtID("gym")
	dbName := "gymslot_gym_" + newUUID()
	// Provisioning DB per-gym (padanan buat spreadsheet, idempotent per gym baru).
	if err := ensureGymDB(h.db, dbName); err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal menyiapkan database gym")
	}
	_, err := h.db.Exec(`INSERT INTO `+h.cfg.ControlDB+`.gyms
		(gym_id, owner_user_id, name, address, phone, contact_email, description, logo_url, timezone, status, `+"`database`"+`, created_at, updated_at)
		VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)`,
		gymID, uid, name, str(p, "address", 512), str(p, "phone", 64), str(p, "contact_email", 255),
		str(p, "description", 2000), str(p, "logo_url", 512),
		strOrDefault(str(p, "timezone", 64), "Asia/Jakarta"), "Active", dbName, now, now)
	if err != nil {
		_ = dropGymDB(h.db, dbName)
		return nil, "", apiErr(CodeInternal, "Gagal membuat gym")
	}
	// Owner otomatis jadi member role owner.
	_, _ = h.db.Exec(`INSERT INTO `+h.cfg.ControlDB+`.memberships
		(membership_id, user_id, gym_id, role, status, created_at, updated_at) VALUES (?,?,?,?,?,?)`,
		fmtID("mem"), uid, gymID, "owner", "Active", now, now)
	// Default settings per-gym.
	_, _ = h.db.Exec(`INSERT INTO `+dbName+`.settings (skey, svalue, updated_at) VALUES
		(?,?,?),(?,?,?),(?,?,?),(?,?,?)`,
		"timezone", strOrDefault(str(p, "timezone", 64), "Asia/Jakarta"), now,
		"attendance_device_mode", "gym_camera", now,
		"attendance_booking_policy", "booking_required", now,
		"manual_attendance_enabled", "false", now)
	h.audit(gymID, uid, "gyms.create", "gym", gymID, map[string]interface{}{"name": name})
	gym, _ := h.gymByID(gymID)
	return gym, "Gym berhasil dibuat", nil
}

func (h *Handler) handleGymsList(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	rows, err := h.queryRows(`SELECT g.gym_id, g.owner_user_id, g.name, g.address, g.phone, g.contact_email,
		g.description, g.logo_url, g.timezone, g.status, g.created_at, g.updated_at, m.role
		FROM `+h.cfg.ControlDB+`.gyms g
		JOIN `+h.cfg.ControlDB+`.memberships m ON m.gym_id = g.gym_id
		WHERE m.user_id = ? AND m.status = 'Active'`, uid)
	if err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal membaca daftar gym")
	}
	return map[string]interface{}{"gyms": rows, "count": len(rows)}, "", nil
}

func (h *Handler) handleGymsDetail(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	gymID, _ := req.Payload["gym_id"].(string)
	gym, aerr := h.gymByID(gymID)
	if aerr != nil {
		return nil, "", aerr
	}
	if _, err := h.queryRow(`SELECT role FROM `+h.cfg.ControlDB+`.memberships WHERE user_id=? AND gym_id=? AND status='Active'`, uid, gymID); err != nil {
		return nil, "", apiErr(CodeTenantAccess, "Anda bukan anggota gym ini")
	}
	return gym, "", nil
}

func (h *Handler) handleGymsUpdate(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	gymID, _ := req.Payload["gym_id"].(string)
	if aerr := h.requireRole(uid, gymID, "owner", "admin"); aerr != nil {
		return nil, "", aerr
	}
	allowed := []string{"name", "address", "phone", "contact_email", "description", "logo_url", "timezone"}
	updates := map[string]interface{}{}
	for _, k := range allowed {
		if v, okk := req.Payload[k]; okk {
			if _, isS := v.(string); isS {
				updates[k] = str(req.Payload, k, 512)
			}
		}
	}
	if len(updates) == 0 {
		return nil, "", validation("Tidak ada field yang bisa diperbarui")
	}
	setClause := ""
	vals := []interface{}{}
	for k, v := range updates {
		setClause += k + " = ?, "
		vals = append(vals, v)
	}
	setClause += "updated_at = ?"
	vals = append(vals, NowUTC(), gymID)
	if err := h.exec(`UPDATE `+h.cfg.ControlDB+`.gyms SET `+setClause+` WHERE gym_id = ?`, vals...); err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal memperbarui gym")
	}
	h.audit(gymID, uid, "gyms.update", "gym", gymID, updates)
	gym, _ := h.gymByID(gymID)
	return gym, "Gym diperbarui", nil
}

func (h *Handler) handleMembershipsList(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	rows, err := h.queryRows(`SELECT membership_id, user_id, gym_id, role, status, created_at
		FROM `+h.cfg.ControlDB+`.memberships WHERE user_id = ?`, uid)
	if err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal membaca membership")
	}
	return map[string]interface{}{"memberships": rows, "count": len(rows)}, "", nil
}

// ============ Role helper ============

func (h *Handler) requireRole(uid, gymID string, roles ...string) *APIError {
	row, err := h.queryRow(`SELECT role, status FROM `+h.cfg.ControlDB+`.memberships WHERE user_id=? AND gym_id=?`, uid, gymID)
	if err != nil {
		return apiErr(CodeTenantAccess, "Anda bukan anggota gym ini")
	}
	status, _ := row["status"].(string)
	if status != "Active" {
		return apiErr(CodeTenantAccess, "Keanggotaan tidak aktif")
	}
	role, _ := row["role"].(string)
	for _, r := range roles {
		if r == role {
			h.role = role
			return nil
		}
	}
	return apiErr(CodePermissionDenied, "Role tidak diizinkan")
}

func str(p map[string]interface{}, key string, maxLen int) string {
	v, _ := p[key].(string)
	return sanitize(v, maxLen)
}

func strOrDefault(v, def string) string {
	if v == "" {
		return def
	}
	return v
}

// dropGymDB dipakai saat rollback gagal create gym.
func dropGymDB(db *sql.DB, dbname string) error {
	if !validDBName(dbname) {
		return fmt.Errorf("invalid db name")
	}
	_, err := db.Exec("DROP DATABASE IF EXISTS `" + dbname + "`")
	return err
}

var _ = fmt.Sprintf

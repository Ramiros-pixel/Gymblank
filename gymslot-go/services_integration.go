package main

// ============ integrations.* (padanan googleDriveService/googleIntegrationService) ============
// Pada backend Go, "integrasi" = provisioning database per-gym.
// Tidak ada OAuth Drive/Sheets — owner tidak perlu menghubungkan Google Drive.
// Action tetap diekspos agar alur Flutter (RegisterGymScreen → GoogleDriveConnectScreen)
// tetap berfungsi tanpa perubahan kode.

import (
	"fmt"
)

// handleIntegrationConnect: di Go backend, koneksi sudah otomatis.
func (h *Handler) handleIntegrationConnect(req *apiRequest) (map[string]interface{}, string, *APIError) {
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
	dbName, _ := gym["database"].(string)
	status := "Connected"
	if dbName == "" {
		status = "Disconnected"
	}
	return map[string]interface{}{
		"status":        status,
		"provider":      "mysql",
		"gym_id":        gymID,
		"authenticated": true,
	}, "Integrasi aktif (database lokal)", nil
}

// handleIntegrationStub: action yang tidak relevan di Go (OAuth Drive).
func (h *Handler) handleIntegrationStub(req *apiRequest) (map[string]interface{}, string, *APIError) {
	return nil, "", apiErr(CodeInternal, "Action ini tidak relevan pada backend Go (tidak memakai Google Drive/Sheets)")
}

func (h *Handler) handleIntegrationStatus(req *apiRequest) (map[string]interface{}, string, *APIError) {
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
	dbName, _ := gym["database"].(string)
	connected := dbName != ""
	// Verifikasi DB benar-benar ada dan tabel lengkap.
	tablesOK := false
	if connected {
		if _, err := h.queryRow(`SELECT facility_id FROM ` + dbName + `.facilities LIMIT 1`); err == nil {
			tablesOK = true
		}
	}
	resp := map[string]interface{}{
		"connected": connected,
		"provider":  "mysql",
		"status":    map[bool]string{true: "Connected", false: "Disconnected"}[connected],
	}
	if connected {
		resp["verified"] = tablesOK
	}
	return resp, "", nil
}

// handleCreateGymDB: membuat ulang struktur DB bila belum ada (idempotent,
// padanan integrations.create-spreadsheet). Owner-only.
func (h *Handler) handleCreateGymDB(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	gymID, _ := req.Payload["gym_id"].(string)
	gym, aerr := h.gymByID(gymID)
	if aerr != nil {
		return nil, "", aerr
	}
	// Owner-only.
	if aerr := h.requireRole(uid, gymID, "owner"); aerr != nil {
		return nil, "", aerr
	}
	dbName, _ := gym["database"].(string)
	if dbName == "" {
		// Gym lama tanpa DB: buat sekarang.
		dbName = "gymslot_gym_" + newUUID()
		if _, err := h.db.Exec(`UPDATE `+h.cfg.ControlDB+`.gyms SET `+"`database`"+`=? WHERE gym_id=?`, dbName, gymID); err != nil {
			return nil, "", apiErr(CodeInternal, "Gagal menautkan database gym")
		}
	}
	if err := ensureGymDB(h.db, dbName); err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal menyiapkan database gym")
	}
	// Default settings bila kosong.
	now := NowUTC()
	tz := gym["timezone"]
	tzs, _ := tz.(string)
	if tzs == "" {
		tzs = "Asia/Jakarta"
	}
	_, _ = h.db.Exec(`INSERT INTO `+dbName+`.settings (skey, svalue, updated_at) VALUES
		(?,?,?),(?,?,?),(?,?,?),(?,?,?) ON DUPLICATE KEY UPDATE skey=skey`,
		"timezone", tzs, now,
		"attendance_device_mode", "gym_camera", now,
		"attendance_booking_policy", "booking_required", now,
		"manual_attendance_enabled", "false", now)
	h.audit(gymID, uid, "integrations.create-spreadsheet", "gym_db", dbName, nil)
	return map[string]interface{}{
		"connected":   true,
		"provider":    "mysql",
		"spreadsheet": dbName, // nama lama dipertahankan agar Flutter kompatibel
	}, "Database gym siap", nil
}

func (h *Handler) handleIntegrationDisconnect(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	gymID, _ := req.Payload["gym_id"].(string)
	if aerr := h.requireRole(uid, gymID, "owner"); aerr != nil {
		return nil, "", aerr
	}
	// Di Go backend disconnect berhenti pada menandai status; data TIDAK dihapus.
	h.audit(gymID, uid, "integrations.disconnect", "gym_db", "", nil)
	return map[string]interface{}{"disconnected": false, "note": "Backend Go menyimpan data di database lokal; disconnect tidak menghapus data"}, "Tidak ada yang perlu diputuskan", nil
}

var _ = fmt.Sprintf

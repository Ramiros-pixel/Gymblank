package main

import (
	"time"
)

// ============ members.* ============
// Padanan memberService.gs: duplikat check per gym, soft delete via status Inactive.

func (h *Handler) handleMembersList(req *apiRequest) (map[string]interface{}, string, *APIError) {
	rows, err := h.queryRows(`SELECT member_id, user_id, full_name, email, phone, join_date, membership_status, created_at, updated_at
		FROM ` + h.gymDB + `.members ORDER BY created_at DESC`)
	if err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal membaca anggota")
	}
	return map[string]interface{}{"members": rows, "count": len(rows)}, "", nil
}

func (h *Handler) handleMembersCreate(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	p := req.Payload
	fullName := str(p, "full_name", 255)
	if fullName == "" {
		return nil, "", validation("Nama anggota wajib diisi")
	}
	email := str(p, "email", 255)
	// Duplikat check per gym (email).
	if email != "" {
		if _, err := h.queryRow(`SELECT member_id FROM `+h.gymDB+`.members WHERE email = ? AND membership_status != 'Inactive'`, email); err == nil {
			return nil, "", validation("Email sudah terdaftar sebagai anggota aktif")
		}
	}
	now := NowUTC()
	memberID := fmtID("mbr")
	joinDate := str(p, "join_date", 10)
	_, err := h.db.Exec(`INSERT INTO `+h.gymDB+`.members
		(member_id, user_id, full_name, email, phone, join_date, membership_status, created_at, updated_at)
		VALUES (?,?,?,?,?,?,?,?,?)`,
		memberID, str(p, "user_id", 64), fullName, email, str(p, "phone", 32),
		nullDate(joinDate), strOrDefault(str(p, "membership_status", 32), "Active"), now, now)
	if err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal membuat anggota")
	}
	h.audit(gymIDFromReq(p), uid, "members.create", "member", memberID, map[string]interface{}{"full_name": fullName})
	row, _ := h.queryRow(`SELECT * FROM `+h.gymDB+`.members WHERE member_id = ?`, memberID)
	return row, "Anggota ditambahkan", nil
}

func (h *Handler) handleMembersUpdate(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	p := req.Payload
	memberID, _ := p["member_id"].(string)
	row, err := h.queryRow(`SELECT * FROM `+h.gymDB+`.members WHERE member_id = ?`, memberID)
	if err != nil {
		return nil, "", apiErr(CodeMemberNotFound, "Anggota tidak ditemukan")
	}
	_ = row
	allowed := []string{"full_name", "email", "phone", "membership_status"}
	setClause, vals := buildUpdate(p, allowed, 255)
	if setClause == "" {
		return nil, "", validation("Tidak ada field yang bisa diperbarui")
	}
	q := `UPDATE ` + h.gymDB + `.members SET ` + setClause + `, updated_at = ? WHERE member_id = ?`
	vals = append(vals, NowUTC(), memberID)
	if err := h.exec(q, vals...); err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal memperbarui anggota")
	}
	h.audit(gymIDFromReq(p), uid, "members.update", "member", memberID, nil)
	out, _ := h.queryRow(`SELECT * FROM `+h.gymDB+`.members WHERE member_id = ?`, memberID)
	return out, "Anggota diperbarui", nil
}

// Soft delete: status jadi Inactive, data tidak dihapus (PRD 10).
func (h *Handler) handleMembersDeactivate(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	memberID, _ := req.Payload["member_id"].(string)
	res, err := h.db.Exec(`UPDATE `+h.gymDB+`.members SET membership_status='Inactive', updated_at=? WHERE member_id=?`, NowUTC(), memberID)
	if err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal menonaktifkan anggota")
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return nil, "", apiErr(CodeMemberNotFound, "Anggota tidak ditemukan")
	}
	h.audit(gymIDFromReq(req.Payload), uid, "members.deactivate", "member", memberID, nil)
	return map[string]interface{}{"member_id": memberID, "membership_status": "Inactive"}, "Anggota dinonaktifkan", nil
}

// ============ facilities.* ============

func (h *Handler) handleFacilitiesList(req *apiRequest) (map[string]interface{}, string, *APIError) {
	rows, err := h.queryRows(`SELECT * FROM ` + h.gymDB + `.facilities ORDER BY created_at DESC`)
	if err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal membaca fasilitas")
	}
	return map[string]interface{}{"facilities": rows, "count": len(rows)}, "", nil
}

func (h *Handler) handleFacilitiesCreate(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	p := req.Payload
	name := str(p, "facility_name", 255)
	if name == "" {
		return nil, "", validation("Nama fasilitas wajib diisi")
	}
	status := strOrDefault(str(p, "status", 32), "Active")
	if status != "Active" && status != "Inactive" && status != "Maintenance" {
		return nil, "", validation("Status fasilitas tidak valid")
	}
	now := NowUTC()
	id := fmtID("fac")
	_, err := h.db.Exec(`INSERT INTO `+h.gymDB+`.facilities
		(facility_id, gym_id, facility_name, description, capacity, status, created_at, updated_at)
		VALUES (?,?,?,?,?,?,?,?)`,
		id, gymIDFromReq(p), name, str(p, "description", 1000), intFrom(p, "capacity"), status, now, now)
	if err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal membuat fasilitas")
	}
	h.audit(gymIDFromReq(p), uid, "facilities.create", "facility", id, nil)
	row, _ := h.queryRow(`SELECT * FROM `+h.gymDB+`.facilities WHERE facility_id = ?`, id)
	return row, "Fasilitas ditambahkan", nil
}

func (h *Handler) handleFacilitiesUpdate(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	p := req.Payload
	id, _ := p["facility_id"].(string)
	if _, err := h.queryRow(`SELECT facility_id FROM `+h.gymDB+`.facilities WHERE facility_id = ?`, id); err != nil {
		return nil, "", apiErr(CodeFacilityNotFound, "Fasilitas tidak ditemukan")
	}
	allowed := []string{"facility_name", "description", "capacity", "status"}
	setClause, vals := buildUpdate(p, allowed, 512)
	if setClause == "" {
		return nil, "", validation("Tidak ada field yang bisa diperbarui")
	}
	if err := h.exec(`UPDATE `+h.gymDB+`.facilities SET `+setClause+`, updated_at=? WHERE facility_id=?`,
		append(vals, NowUTC(), id)...); err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal memperbarui fasilitas")
	}
	h.audit(gymIDFromReq(p), uid, "facilities.update", "facility", id, nil)
	out, _ := h.queryRow(`SELECT * FROM `+h.gymDB+`.facilities WHERE facility_id = ?`, id)
	return out, "Fasilitas diperbarui", nil
}

func (h *Handler) handleFacilitiesDeactivate(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	id, _ := req.Payload["facility_id"].(string)
	res, err := h.db.Exec(`UPDATE `+h.gymDB+`.facilities SET status='Inactive', updated_at=? WHERE facility_id=?`, NowUTC(), id)
	if err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal menonaktifkan fasilitas")
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return nil, "", apiErr(CodeFacilityNotFound, "Fasilitas tidak ditemukan")
	}
	h.audit(gymIDFromReq(req.Payload), uid, "facilities.deactivate", "facility", id, nil)
	return map[string]interface{}{"facility_id": id, "status": "Inactive"}, "Fasilitas dinonaktifkan", nil
}

// ============ schedules.* ============
// Padanan scheduleService.gs: cek konflik overlap pada fasilitas yang sama.

func (h *Handler) handleSchedulesList(req *apiRequest) (map[string]interface{}, string, *APIError) {
	q := `SELECT s.*, f.facility_name, (s.capacity - COALESCE(b.n,0)) AS remaining
		FROM ` + h.gymDB + `.schedules s
		JOIN ` + h.gymDB + `.facilities f ON f.facility_id = s.facility_id
		LEFT JOIN (SELECT schedule_id, COUNT(*) n FROM ` + h.gymDB + `.bookings
			WHERE booking_status IN ('Pending','Confirmed') GROUP BY schedule_id) b ON b.schedule_id = s.schedule_id
		WHERE 1=1`
	args := []interface{}{}
	if d, ok := req.Payload["schedule_date"].(string); ok && d != "" {
		q += ` AND s.schedule_date = ?`
		args = append(args, d)
	}
	q += ` ORDER BY s.schedule_date, s.start_time`
	rows, err := h.queryRows(q, args...)
	if err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal membaca jadwal")
	}
	return map[string]interface{}{"schedules": rows, "count": len(rows)}, "", nil
}

func (h *Handler) handleSchedulesCreate(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	p := req.Payload
	facilityID := str(p, "facility_id", 64)
	sDate := str(p, "schedule_date", 10)
	startT := str(p, "start_time", 8)
	endT := str(p, "end_time", 8)
	if facilityID == "" || sDate == "" || startT == "" || endT == "" {
		return nil, "", validation("facility_id, schedule_date, start_time, end_time wajib diisi")
	}
	if endT <= startT {
		return nil, "", validation("end_time harus setelah start_time")
	}
	// Fasilitas harus ada dan Active.
	fac, err := h.queryRow(`SELECT status FROM `+h.gymDB+`.facilities WHERE facility_id = ?`, facilityID)
	if err != nil {
		return nil, "", apiErr(CodeFacilityNotFound, "Fasilitas tidak ditemukan")
	}
	if fac["status"] != "Active" {
		return nil, "", validation("Fasilitas sedang tidak aktif")
	}
	// Konflik overlap: same facility + same date, (start1 < end2 && end1 > start2).
	conflict, err := h.queryRow(`SELECT schedule_id FROM `+h.gymDB+`.schedules
		WHERE facility_id = ? AND schedule_date = ? AND status != 'Inactive'
		AND start_time < ? AND end_time > ?`, facilityID, sDate, endT, startT)
	if err == nil {
		_ = conflict
		return nil, "", apiErr(CodeScheduleConflict, "Jadwal bertabrakan pada fasilitas yang sama")
	}
	now := NowUTC()
	id := fmtID("sch")
	_, err = h.db.Exec(`INSERT INTO `+h.gymDB+`.schedules
		(schedule_id, facility_id, schedule_date, start_time, end_time, capacity, status, created_at, updated_at)
		VALUES (?,?,?,?,?,?,?,?,?)`,
		id, facilityID, sDate, startT, endT, intFrom(p, "capacity"), strOrDefault(str(p, "status", 32), "Active"), now, now)
	if err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal membuat jadwal")
	}
	h.audit(gymIDFromReq(p), uid, "schedules.create", "schedule", id, nil)
	row, _ := h.queryRow(`SELECT * FROM `+h.gymDB+`.schedules WHERE schedule_id = ?`, id)
	return row, "Jadwal dibuat", nil
}

func (h *Handler) handleSchedulesUpdate(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	p := req.Payload
	id, _ := p["schedule_id"].(string)
	sched, err := h.queryRow(`SELECT * FROM `+h.gymDB+`.schedules WHERE schedule_id = ?`, id)
	if err != nil {
		return nil, "", apiErr(CodeScheduleNotFound, "Jadwal tidak ditemukan")
	}
	// Jika mengubah waktu: validasi ulang overlap dan end>start.
	newStart, hasStart := p["start_time"].(string)
	newEnd, hasEnd := p["end_time"].(string)
	startT := orStr(hasStart, newStart, sched["start_time"])
	endT := orStr(hasEnd, newEnd, sched["end_time"])
	if hasStart || hasEnd {
		if endT <= startT {
			return nil, "", validation("end_time harus setelah start_time")
		}
		sDate, _ := sched["schedule_date"].(string)
		facID, _ := sched["facility_id"].(string)
		conflict, err := h.queryRow(`SELECT schedule_id FROM `+h.gymDB+`.schedules
			WHERE facility_id = ? AND schedule_date = ? AND schedule_id != ? AND status != 'Inactive'
			AND start_time < ? AND end_time > ?`, facID, sDate, id, endT, startT)
		if err == nil {
			_ = conflict
			return nil, "", apiErr(CodeScheduleConflict, "Perubahan waktu bertabrakan dengan jadwal lain")
		}
	}
	allowed := []string{"start_time", "end_time", "capacity", "status", "schedule_date"}
	setClause, vals := buildUpdate(p, allowed, 32)
	if setClause == "" {
		return nil, "", validation("Tidak ada field yang bisa diperbarui")
	}
	if err := h.exec(`UPDATE `+h.gymDB+`.schedules SET `+setClause+`, updated_at=? WHERE schedule_id=?`,
		append(vals, NowUTC(), id)...); err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal memperbarui jadwal")
	}
	h.audit(gymIDFromReq(p), uid, "schedules.update", "schedule", id, nil)
	out, _ := h.queryRow(`SELECT * FROM `+h.gymDB+`.schedules WHERE schedule_id = ?`, id)
	return out, "Jadwal diperbarui", nil
}

func (h *Handler) handleSchedulesDeactivate(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	id, _ := req.Payload["schedule_id"].(string)
	res, err := h.db.Exec(`UPDATE `+h.gymDB+`.schedules SET status='Inactive', updated_at=? WHERE schedule_id=?`, NowUTC(), id)
	if err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal menonaktifkan jadwal")
	}
	if n, _ := res.RowsAffected(); n == 0 {
		return nil, "", apiErr(CodeScheduleNotFound, "Jadwal tidak ditemukan")
	}
	h.audit(gymIDFromReq(req.Payload), uid, "schedules.deactivate", "schedule", id, nil)
	return map[string]interface{}{"schedule_id": id, "status": "Inactive"}, "Jadwal dinonaktifkan", nil
}

// ============ Helper bersama ============

func gymIDFromReq(p map[string]interface{}) string {
	s, _ := p["gym_id"].(string)
	return s
}

func intFrom(p map[string]interface{}, key string) int {
	switch v := p[key].(type) {
	case float64:
		return int(v)
	case int:
		return v
	}
	return 0
}

func nullDate(s string) interface{} {
	if s == "" {
		return nil
	}
	return s
}

func orStr(has bool, val string, fallback interface{}) string {
	if has && val != "" {
		return val
	}
	if s, ok := fallback.(string); ok {
		return s
	}
	if t, ok := fallback.(time.Time); ok {
		return t.Format("15:04:05")
	}
	return ""
}

// buildUpdate menyusun "k = ?" hanya untuk key yang ada di payload.
func buildUpdate(p map[string]interface{}, allowed []string, maxLen int) (string, []interface{}) {
	setClause := ""
	vals := []interface{}{}
	for _, k := range allowed {
		if v, ok := p[k]; ok {
			switch vv := v.(type) {
			case string:
				setClause += k + " = ?, "
				vals = append(vals, sanitize(vv, maxLen))
			case float64:
				setClause += k + " = ?, "
				vals = append(vals, int(vv))
			case bool:
				setClause += k + " = ?, "
				vals = append(vals, vv)
			}
		}
	}
	return setClause, vals
}

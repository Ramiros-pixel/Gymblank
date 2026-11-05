package main

import (
	"time"
)

// ============ bookings.* ============
// Padanan bookingService.gs (PRD 13): status member Active → jadwal+fasilitas Active
// → duplikat check → LOCK → re-check duplikat+kapasitas DI DALAM lock → insert Confirmed.

func (h *Handler) handleBookingsList(req *apiRequest) (map[string]interface{}, string, *APIError) {
	q := `SELECT b.*, m.full_name, s.schedule_date, s.start_time, s.end_time, f.facility_name
		FROM ` + h.gymDB + `.bookings b
		JOIN ` + h.gymDB + `.members m ON m.member_id = b.member_id
		JOIN ` + h.gymDB + `.schedules s ON s.schedule_id = b.schedule_id
		JOIN ` + h.gymDB + `.facilities f ON f.facility_id = s.facility_id
		WHERE 1=1`
	args := []interface{}{}
	if st, ok := req.Payload["booking_status"].(string); ok && st != "" {
		q += ` AND b.booking_status = ?`
		args = append(args, st)
	}
	q += ` ORDER BY b.created_at DESC LIMIT 500`
	rows, err := h.queryRows(q, args...)
	if err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal membaca booking")
	}
	return map[string]interface{}{"bookings": rows, "count": len(rows)}, "", nil
}

// bookings.my: booking milik member yang login saja.
func (h *Handler) handleBookingsMy(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	member, err := h.queryRow(`SELECT member_id FROM `+h.gymDB+`.members WHERE user_id = ? AND membership_status != 'Inactive'`, uid)
	if err != nil {
		return map[string]interface{}{"bookings": []map[string]interface{}{}, "count": 0}, "", nil
	}
	rows, err := h.queryRows(`SELECT b.*, s.schedule_date, s.start_time, s.end_time, f.facility_name
		FROM `+h.gymDB+`.bookings b
		JOIN `+h.gymDB+`.schedules s ON s.schedule_id = b.schedule_id
		JOIN `+h.gymDB+`.facilities f ON f.facility_id = s.facility_id
		WHERE b.member_id = ? ORDER BY b.created_at DESC LIMIT 200`, member["member_id"])
	if err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal membaca booking")
	}
	return map[string]interface{}{"bookings": rows, "count": len(rows)}, "", nil
}

func (h *Handler) handleBookingsCreate(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	p := req.Payload
	scheduleID := str(p, "schedule_id", 64)

	// 1. Member aktif (milik user yang login).
	member, err := h.queryRow(`SELECT member_id, membership_status FROM `+h.gymDB+`.members
		WHERE user_id = ? AND membership_status = 'Active'`, uid)
	if err != nil {
		return nil, "", apiErr(CodePermissionDenied, "Hanya anggota aktif yang dapat booking")
	}
	memberID, _ := member["member_id"].(string)

	// 2. Jadwal + fasilitas harus Active.
	sched, err := h.queryRow(`SELECT s.*, f.status AS facility_status FROM `+h.gymDB+`.schedules s
		JOIN `+h.gymDB+`.facilities f ON f.facility_id = s.facility_id WHERE s.schedule_id = ?`, scheduleID)
	if err != nil {
		return nil, "", apiErr(CodeScheduleNotFound, "Jadwal tidak ditemukan")
	}
	if sched["status"] != "Active" {
		return nil, "", validation("Jadwal tidak aktif")
	}
	if sched["facility_status"] != "Active" {
		return nil, "", validation("Fasilitas sedang maintenance/tidak aktif")
	}
	capacity, _ := toInt(sched["capacity"])
	if capacity <= 0 {
		return nil, "", validation("Kapasitas jadwal tidak valid")
	}

	// 3. Duplikat check (pra-lock, cepat).
	if dup := h.countActiveBooking(h.gymDB, scheduleID, memberID); dup > 0 {
		return nil, "", apiErr(CodeDuplicateBooking, "Anda sudah booking jadwal ini")
	}

	// 4-7. LOCK → re-check duplikat + kapasitas DI DALAM lock → insert.
	// Prinsip PRD: validasi ulang di dalam kunci adalah keputusan yang menentukan.
	release, aerr := h.lockGym(h.gymDB)
	if aerr != nil {
		return nil, "", aerr // RATE_LIMITED saat gagal mendapat lock — client boleh retry
	}
	defer release()

	if dup := h.countActiveBooking(h.gymDB, scheduleID, memberID); dup > 0 {
		return nil, "", apiErr(CodeDuplicateBooking, "Anda sudah booking jadwal ini")
	}
	var used int
	if err := h.db.QueryRow(`SELECT COUNT(*) FROM `+h.gymDB+`.bookings
		WHERE schedule_id = ? AND booking_status IN ('Pending','Confirmed')`, scheduleID).Scan(&used); err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal menghitung kapasitas")
	}
	if used >= capacity {
		return nil, "", apiErr(CodeCapacityFull, "Kapasitas jadwal sudah penuh")
	}

	now := NowUTC()
	id := fmtID("bkg")
	if _, err := h.db.Exec(`INSERT INTO `+h.gymDB+`.bookings
		(booking_id, member_id, schedule_id, facility_id, booking_status, created_at, updated_at)
		VALUES (?,?,?,?,?,?,?)`,
		id, memberID, scheduleID, sched["facility_id"], "Confirmed", now, now); err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal menyimpan booking")
	}
	h.invalidateDashboardCache()
	h.audit(gymIDFromReq(p), uid, "bookings.create", "booking", id, map[string]interface{}{"schedule_id": scheduleID})
	row, _ := h.queryRow(`SELECT * FROM `+h.gymDB+`.bookings WHERE booking_id = ?`, id)
	return row, "Booking berhasil", nil
}

func (h *Handler) handleBookingsCancel(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	p := req.Payload
	bookingID := str(p, "booking_id", 64)
	b, err := h.queryRow(`SELECT * FROM `+h.gymDB+`.bookings WHERE booking_id = ?`, bookingID)
	if err != nil {
		return nil, "", apiErr(CodeBookingNotFound, "Booking tidak ditemukan")
	}
	// Member hanya boleh membatalkan booking miliknya; staff boleh membatalkan milik siapa pun.
	role := h.role
	if role == "member" {
		member, merr := h.queryRow(`SELECT member_id FROM `+h.gymDB+`.members WHERE user_id = ?`, uid)
		if merr != nil || member["member_id"] != b["member_id"] {
			return nil, "", apiErr(CodePermissionDenied, "Bukan booking Anda")
		}
	}
	if b["booking_status"] == "Cancelled" {
		return nil, "", validation("Booking sudah dibatalkan sebelumnya")
	}
	if _, err := h.db.Exec(`UPDATE `+h.gymDB+`.bookings SET booking_status='Cancelled', cancelled_at=?, updated_at=? WHERE booking_id=?`,
		NowUTC(), NowUTC(), bookingID); err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal membatalkan booking")
	}
	h.invalidateDashboardCache()
	h.audit(gymIDFromReq(p), uid, "bookings.cancel", "booking", bookingID, nil)
	return map[string]interface{}{"booking_id": bookingID, "booking_status": "Cancelled"}, "Booking dibatalkan", nil
}

func (h *Handler) countActiveBooking(gymDB, scheduleID, memberID string) int {
	var n int
	_ = h.db.QueryRow(`SELECT COUNT(*) FROM `+gymDB+`.bookings
		WHERE schedule_id = ? AND member_id = ? AND booking_status IN ('Pending','Confirmed')`,
		scheduleID, memberID).Scan(&n)
	return n
}

// ============ attendance.* ============
// Padanan attendanceService.gs: gated oleh Settings gym, check_in_at selalu waktu server.

func (h *Handler) handleAttendanceList(req *apiRequest) (map[string]interface{}, string, *APIError) {
	q := `SELECT a.*, m.full_name FROM ` + h.gymDB + `.attendance a
		JOIN ` + h.gymDB + `.members m ON m.member_id = a.member_id
		WHERE 1=1`
	args := []interface{}{}
	if d, ok := req.Payload["date"].(string); ok && d != "" {
		q += ` AND DATE(a.check_in_at) = ?`
		args = append(args, d)
	}
	q += ` ORDER BY a.check_in_at DESC LIMIT 500`
	rows, err := h.queryRows(q, args...)
	if err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal membaca attendance")
	}
	return map[string]interface{}{"attendance": rows, "count": len(rows)}, "", nil
}

func (h *Handler) handleAttendanceCheckin(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	p := req.Payload

	// Manual attendance harus diaktifkan di Settings gym (baca settings DULU).
	set, err := h.gymSettings(h.gymDB)
	if err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal membaca pengaturan gym")
	}
	if set["manual_attendance_enabled"] != "true" {
		return nil, "", apiErr(CodePermissionDenied, "Attendance manual tidak diaktifkan gym ini")
	}

	// Member aktif.
	member, err := h.queryRow(`SELECT member_id FROM `+h.gymDB+`.members WHERE user_id = ? AND membership_status = 'Active'`, uid)
	if err != nil {
		return nil, "", apiErr(CodePermissionDenied, "Hanya anggota aktif yang dapat check-in")
	}
	memberID, _ := member["member_id"].(string)

	bookingID := str(p, "booking_id", 64)
	if set["attendance_booking_policy"] == "booking_required" {
		if bookingID == "" {
			return nil, "", validation("Booking diperlukan untuk check-in (booking_required)")
		}
		bk, err := h.queryRow(`SELECT member_id FROM `+h.gymDB+`.bookings
			WHERE booking_id = ? AND member_id = ? AND booking_status = 'Confirmed'`, bookingID, memberID)
		if err != nil {
			return nil, "", apiErr(CodeBookingNotFound, "Booking Confirmed milik Anda tidak ditemukan")
		}
		_ = bk
		// Satu booking hanya bisa check-in sekali.
		if n := h.countCheckinByBooking(bookingID); n > 0 {
			return nil, "", validation("Booking ini sudah pernah check-in")
		}
	} else if bookingID != "" {
		// walk_in_allowed: booking opsional; bila diisi tetap divalidasi.
		if _, err := h.queryRow(`SELECT booking_id FROM `+h.gymDB+`.bookings WHERE booking_id = ? AND member_id = ?`, bookingID, memberID); err != nil {
			return nil, "", apiErr(CodeBookingNotFound, "Booking tidak ditemukan")
		}
	}

	// Waktu check-in SELALU waktu server (PRD 14) — tidak pernah menerima dari device.
	now := NowUTC()
	method := strOrDefault(str(p, "attendance_method", 32), "manual")
	id := fmtID("att")
	if _, err := h.db.Exec(`INSERT INTO `+h.gymDB+`.attendance
		(attendance_id, member_id, booking_id, check_in_at, attendance_method, device_id, created_by, created_at)
		VALUES (?,?,?,?,?,?,?,?)`,
		id, memberID, nullIfEmpty(bookingID), now, method, str(p, "device_id", 128), uid, now); err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal mencatat kehadiran")
	}
	h.invalidateDashboardCache()
	h.audit(gymIDFromReq(p), uid, "attendance.checkin", "attendance", id, nil)
	row, _ := h.queryRow(`SELECT * FROM `+h.gymDB+`.attendance WHERE attendance_id = ?`, id)
	return row, "Check-in berhasil", nil
}

func (h *Handler) countCheckinByBooking(bookingID string) int {
	var n int
	_ = h.db.QueryRow(`SELECT COUNT(*) FROM `+h.gymDB+`.attendance WHERE booking_id = ?`, bookingID).Scan(&n)
	return n
}

// ============ settings.* ============
// Padanan gymSettingsService.gs: whitelist key, validasi semuanya sebelum menulis.

var allowedSettingKeys = map[string]bool{
	"attendance_device_mode":    true,
	"attendance_booking_policy": true,
	"manual_attendance_enabled": true,
	"timezone":                  true,
}

func (h *Handler) handleSettingsGet(req *apiRequest) (map[string]interface{}, string, *APIError) {
	set, err := h.gymSettings(h.gymDB)
	if err != nil {
		return nil, "", apiErr(CodeInternal, "Gagal membaca pengaturan gym")
	}
	return map[string]interface{}{"settings": set}, "", nil
}

func (h *Handler) handleSettingsUpdate(req *apiRequest) (map[string]interface{}, string, *APIError) {
	uid, aerr := h.requireSession(req)
	if aerr != nil {
		return nil, "", aerr
	}
	// owner-only (PRD 14 settings; Apps Script: settings.update owner-only).
	if h.role != "owner" {
		return nil, "", apiErr(CodePermissionDenied, "Hanya owner yang dapat mengubah pengaturan")
	}
	raw, ok := req.Payload["settings"].(map[string]interface{})
	if !ok || len(raw) == 0 {
		return nil, "", validation("Payload settings wajib berisi objek settings")
	}
	// Validasi SEMUA sebelum menulis apa pun (all-or-nothing).
	updates := map[string]string{}
	for k, v := range raw {
		if !allowedSettingKeys[k] {
			return nil, "", validation("Key pengaturan tidak dikenal: " + k)
		}
		sv, isStr := v.(string)
		if !isStr {
			return nil, "", validation("Nilai pengaturan harus string: " + k)
		}
		switch k {
		case "attendance_device_mode":
			if sv != "gym_camera" && sv != "mobile_camera" && sv != "both" {
				return nil, "", validation("attendance_device_mode tidak valid")
			}
		case "attendance_booking_policy":
			if sv != "booking_required" && sv != "walk_in_allowed" {
				return nil, "", validation("attendance_booking_policy tidak valid")
			}
		case "manual_attendance_enabled":
			if sv != "true" && sv != "false" {
				return nil, "", validation("manual_attendance_enabled harus 'true'/'false'")
			}
		case "timezone":
			if _, err := time.LoadLocation(sv); err != nil {
				return nil, "", validation("timezone tidak valid")
			}
		}
		updates[k] = sv
	}
	now := NowUTC()
	for k, v := range updates {
		if _, err := h.db.Exec(`INSERT INTO `+h.gymDB+`.settings (skey, svalue, updated_at) VALUES (?,?,?)
			ON DUPLICATE KEY UPDATE svalue = VALUES(svalue), updated_at = VALUES(updated_at)`, k, v, now); err != nil {
			return nil, "", apiErr(CodeInternal, "Gagal menyimpan pengaturan")
		}
	}
	// Timezone mengubah arti "hari ini" → cache dashboard harus invalid (padanan invalidate).
	if _, changed := updates["timezone"]; changed {
		h.invalidateDashboardCache()
	}
	h.audit(gymIDFromReq(req.Payload), uid, "settings.update", "settings", "", mapToIface(updates))
	set, _ := h.gymSettings(h.gymDB)
	return map[string]interface{}{"settings": set}, "Pengaturan diperbarui", nil
}

// mapToIface mengonversi map[string]string → map[string]interface{} untuk audit.
func mapToIface(m map[string]string) map[string]interface{} {
	out := map[string]interface{}{}
	for k, v := range m {
		out[k] = v
	}
	return out
}

func (h *Handler) gymSettings(gymDB string) (map[string]string, error) {
	rows, err := rowsToMaps(h.db, `SELECT skey, svalue FROM `+gymDB+`.settings`)
	out := map[string]string{}
	if err != nil {
		return out, err
	}
	for _, r := range rows {
		k, _ := r["skey"].(string)
		v, _ := r["svalue"].(string)
		out[k] = v
	}
	return out, nil
}

// ============ Helper ============

func toInt(v interface{}) (int, bool) {
	switch n := v.(type) {
	case int64:
		return int(n), true
	case float64:
		return int(n), true
	case int:
		return n, true
	}
	return 0, false
}

func nullIfEmpty(s string) interface{} {
	if s == "" {
		return nil
	}
	return s
}

package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"time"
)

// ============ Locking (padanan lock.gs / LockService.getScriptLock) ============
// MySQL GET_LOCK per-gym: booking create/cancel memegang lock ini;
// re-check kapasitas terjadi DI DALAM lock.
// Gagal mendapat lock → RATE_LIMITED agar client retry (bukan menulis tanpa lock).

type unlockFunc func()

func (h *Handler) lockGym(gymDB string) (unlockFunc, *APIError) {
	conn, err := h.db.Conn(context.Background())
	if err != nil {
		return nil, apiErr(CodeInternal, "Gagal mendapat koneksi")
	}
	var got int
	if err := conn.QueryRowContext(context.Background(), "SELECT GET_LOCK(?, 10)", "gymlock_"+gymDB).Scan(&got); err != nil || got != 1 {
		conn.Close()
		return nil, apiErr(CodeRateLimited, "Sistem sibuk, coba lagi sebentar")
	}
	return func() {
		_, _ = conn.ExecContext(context.Background(), "SELECT RELEASE_LOCK(?)", "gymlock_"+gymDB)
		conn.Close()
	}, nil
}

// ============ Dashboard cache (padanan CacheService, TTL 60 detik) ============
// MySQL tabel dashboard_cache dengan expires_at. invalidateDashboardCache
// menghapus baris cache (MySQL punya DELETE, tak perlu trik generasi).

const dashboardCacheTTL = 60 * time.Second

func (h *Handler) cacheGet(key string) (map[string]interface{}, bool) {
	var payload []byte
	var genAt time.Time
	err := h.db.QueryRow(`SELECT payload, generated_at FROM `+h.cfg.ControlDB+`.dashboard_cache
		WHERE cache_key = ? AND expires_at > NOW()`, key).Scan(&payload, &genAt)
	if err != nil {
		return nil, false
	}
	var out map[string]interface{}
	if err := json.Unmarshal(payload, &out); err != nil {
		return nil, false
	}
	out["generated_at"] = iso(genAt)
	return out, true
}

func (h *Handler) cachePut(key string, data map[string]interface{}) {
	b, err := json.Marshal(data)
	if err != nil {
		return
	}
	now := NowUTC()
	_, _ = h.db.Exec(`INSERT INTO `+h.cfg.ControlDB+`.dashboard_cache (cache_key, payload, generated_at, expires_at)
		VALUES (?,?,?,?) ON DUPLICATE KEY UPDATE payload=VALUES(payload), generated_at=VALUES(generated_at), expires_at=VALUES(expires_at)`,
		key, string(b), now, now.Add(dashboardCacheTTL))
}

func (h *Handler) invalidateDashboardCache() {
	_, _ = h.db.Exec(`DELETE FROM ` + h.cfg.ControlDB + `.dashboard_cache`)
}

// scanCount menjalankan query COUNT(*) dan menaruhnya di data[key].
func (h *Handler) scanCount(data map[string]interface{}, key, query string, args ...interface{}) {
	var n int64
	if err := h.db.QueryRow(query, args...).Scan(&n); err == nil {
		data[key] = n
	} else {
		data[key] = 0
	}
}

// ============ dashboard.stats ============

func (h *Handler) handleDashboardStats(req *apiRequest) (map[string]interface{}, string, *APIError) {
	if cached, okk := h.cacheGet("dash:stats:" + h.gymDB); okk {
		return cached, "", nil
	}
	set, _ := h.gymSettings(h.gymDB)
	tz := set["timezone"]
	if tz == "" {
		tz = "Asia/Jakarta"
	}
	today := todayLocal(tz)

	data := map[string]interface{}{}
	g := h.gymDB
	h.scanCount(data, "total_members", `SELECT COUNT(*) FROM `+g+`.members`)
	h.scanCount(data, "active_members", `SELECT COUNT(*) FROM `+g+`.members WHERE membership_status='Active'`)
	h.scanCount(data, "bookings_today", `SELECT COUNT(*) FROM `+g+`.bookings b JOIN `+g+`.schedules s ON s.schedule_id=b.schedule_id
		WHERE s.schedule_date = ? AND b.booking_status IN ('Pending','Confirmed')`, today)
	h.scanCount(data, "bookings_upcoming", `SELECT COUNT(*) FROM `+g+`.bookings b JOIN `+g+`.schedules s ON s.schedule_id=b.schedule_id
		WHERE s.schedule_date >= ? AND b.booking_status IN ('Pending','Confirmed')`, today)
	h.scanCount(data, "attendance_today", `SELECT COUNT(*) FROM `+g+`.attendance WHERE DATE(check_in_at) = ?`, today)
	h.scanCount(data, "bookings_cancelled", `SELECT COUNT(*) FROM `+g+`.bookings WHERE booking_status='Cancelled'`)
	h.scanCount(data, "bookings_pending", `SELECT COUNT(*) FROM `+g+`.bookings WHERE booking_status='Pending'`)

	data["timezone"] = tz
	data["today"] = today
	h.cachePut("dash:stats:"+g, data)
	return data, "", nil
}

// ============ dashboard.charts ============
// 5 dataset: tren booking, tren kehadiran, status booking, fasilitas populer, jam ramai.

func (h *Handler) handleDashboardCharts(req *apiRequest) (map[string]interface{}, string, *APIError) {
	rng, _ := req.Payload["range"].(string)
	set, _ := h.gymSettings(h.gymDB)
	tz := set["timezone"]
	if tz == "" {
		tz = "Asia/Jakarta"
	}
	today := todayLocal(tz)

	days := 7
	startDate := ""
	switch rng {
	case "today":
		startDate = today
		days = 1
	case "30d":
		days = 30
	case "custom":
		startDate, _ = req.Payload["start_date"].(string)
		endDate, _ := req.Payload["end_date"].(string)
		if startDate == "" || endDate == "" {
			return nil, "", validation("start_date dan end_date wajib untuk range custom")
		}
		if endDate < startDate {
			return nil, "", validation("end_date tidak boleh sebelum start_date")
		}
		d, err := daysBetween(startDate, endDate)
		if err != nil || d > 366 {
			return nil, "", validation("Rentang custom maksimal 366 hari")
		}
		days = d + 1
	default:
		rng = "7d"
	}
	if startDate == "" {
		startDate = shiftDate(today, -(days - 1))
	}

	cacheKey := fmt.Sprintf("dash:charts:%s:%s:%s", h.gymDB, rng, startDate)
	if cached, okk := h.cacheGet(cacheKey); okk {
		return cached, "", nil
	}

	g := h.gymDB
	data := map[string]interface{}{}
	data["range"] = rng
	data["start_date"] = startDate

	// 1. Tren booking per hari (periode rentang).
	bookingTrend, err := h.queryRows(`SELECT s.schedule_date AS d, COUNT(*) AS n
		FROM `+g+`.bookings b JOIN `+g+`.schedules s ON s.schedule_id=b.schedule_id
		WHERE s.schedule_date BETWEEN ? AND ? AND b.booking_status IN ('Pending','Confirmed')
		GROUP BY s.schedule_date ORDER BY s.schedule_date`, startDate, today)
	if err != nil {
		bookingTrend = nil
	}
	data["booking_trend"] = seriesFill(bookingTrend, startDate, days, today)

	// 2. Tren kehadiran per hari.
	attTrend, err := h.queryRows(`SELECT DATE(check_in_at) AS d, COUNT(*) AS n
		FROM `+g+`.attendance WHERE DATE(check_in_at) BETWEEN ? AND ?
		GROUP BY DATE(check_in_at) ORDER BY d`, startDate, today)
	if err != nil {
		attTrend = nil
	}
	data["attendance_trend"] = seriesFill(attTrend, startDate, days, today)

	// 3. Status booking.
	statusRows, _ := h.queryRows(`SELECT booking_status AS k, COUNT(*) AS n FROM ` + g + `.bookings GROUP BY booking_status`)
	data["booking_status"] = kvList(statusRows)

	// 4. Fasilitas populer.
	popRows, _ := h.queryRows(`SELECT f.facility_name AS k, COUNT(*) AS n
		FROM ` + g + `.bookings b JOIN ` + g + `.schedules s ON s.schedule_id=b.schedule_id
		JOIN ` + g + `.facilities f ON f.facility_id=s.facility_id
		WHERE b.booking_status IN ('Pending','Confirmed')
		GROUP BY f.facility_name ORDER BY n DESC LIMIT 8`)
	data["popular_facilities"] = kvList(popRows)

	// 5. Jam ramai (distribusi check-in per jam, waktu lokal gym).
	hourRows, err := h.queryRows(`SELECT HOUR(CONVERT_TZ(check_in_at,'+00:00',?)) AS k, COUNT(*) AS n
		FROM `+g+`.attendance GROUP BY k ORDER BY k`, tzOffsetSQL(tz))
	if err != nil {
		hourRows, _ = h.queryRows(`SELECT HOUR(check_in_at) AS k, COUNT(*) AS n
			FROM ` + g + `.attendance GROUP BY k ORDER BY k`)
	}
	data["busy_hours"] = kvList(hourRows)

	data["timezone"] = tz
	h.cachePut(cacheKey, data)
	return data, "", nil
}

func kvList(rows []map[string]interface{}) []map[string]interface{} {
	out := []map[string]interface{}{}
	for _, r := range rows {
		k := ""
		switch v := r["k"].(type) {
		case string:
			k = v
		case []byte:
			k = string(v)
		case time.Time:
			k = v.Format("2006-01-02")
		}
		n := 0
		if iv, ok := r["n"].(int64); ok {
			n = int(iv)
		}
		out = append(out, map[string]interface{}{"label": k, "value": n})
	}
	return out
}

// seriesFill mengisi hari kosong dengan 0, dari startDate sampai endDate
// (rentang tanggal masa depan tidak dipakai — hari setelah today bernilai 0).
func seriesFill(rows []map[string]interface{}, startDate string, days int, endDate string) []map[string]interface{} {
	byDay := map[string]int{}
	for _, r := range rows {
		d := ""
		switch v := r["d"].(type) {
		case string:
			if len(v) >= 10 {
				d = v[:10]
			}
		case []byte:
			if len(v) >= 10 {
				d = string(v)[:10]
			}
		case time.Time:
			d = v.Format("2006-01-02")
		}
		if n, ok := r["n"].(int64); ok {
			byDay[d] = int(n)
		}
	}
	out := []map[string]interface{}{}
	for i := 0; i < days; i++ {
		d := shiftDate(startDate, i)
		if d > endDate {
			break
		}
		out = append(out, map[string]interface{}{"date": d, "value": byDay[d]})
	}
	return out
}

func shiftDate(date string, deltaDays int) string {
	t, err := time.Parse("2006-01-02", date)
	if err != nil {
		return date
	}
	return t.AddDate(0, 0, deltaDays).Format("2006-01-02")
}

func daysBetween(a, b string) (int, error) {
	ta, err := time.Parse("2006-01-02", a)
	if err != nil {
		return 0, err
	}
	tb, err := time.Parse("2006-01-02", b)
	if err != nil {
		return 0, err
	}
	return int(tb.Sub(ta).Hours() / 24), nil
}

// tzOffsetSQL menghasilkan offset '+07:00' untuk CONVERT_TZ.
func tzOffsetSQL(tz string) string {
	loc, err := time.LoadLocation(tz)
	if err != nil {
		return "+07:00"
	}
	_, off := time.Now().In(loc).Zone()
	sign := "+"
	if off < 0 {
		sign = "-"
		off = -off
	}
	return fmt.Sprintf("%s%02d:%02d", sign, off/3600, (off%3600)/60)
}

var _ = sql.ErrNoRows

package main

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"regexp"
	"strings"
	"sync"
	"time"
)

// ============ Kontrak request/response — identik dengan Apps Script ============

type apiRequest struct {
	Action    string                 `json:"action"`
	Version   string                 `json:"version"`
	RequestID string                 `json:"request_id"`
	Payload   map[string]interface{} `json:"payload"`
	Auth      struct {
		SessionToken string `json:"session_token"`
		IDToken      string `json:"id_token"`
	} `json:"auth"`
}

func ok(w http.ResponseWriter, reqID string, data map[string]interface{}, msg string) {
	if msg == "" {
		msg = "Request berhasil"
	}
	writeJSON(w, 200, map[string]interface{}{
		"success":    true,
		"request_id": reqID,
		"data":       data,
		"message":    msg,
	})
}

func fail(w http.ResponseWriter, reqID string, e *APIError) {
	writeJSON(w, mapStatus(e), map[string]interface{}{
		"success":    false,
		"request_id": reqID,
		"error":      map[string]string{"code": e.Code, "message": e.Message},
	})
}

func failShape(reqID, code, msg string) map[string]interface{} {
	return map[string]interface{}{
		"success":    false,
		"request_id": reqID,
		"error":      map[string]string{"code": code, "message": msg},
	}
}

func writeJSON(w http.ResponseWriter, status int, v interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func iso(t time.Time) string { return t.UTC().Format("2006-01-02T15:04:05.000Z") }

// ============ Handler & Router ============

type Handler struct {
	db    *sql.DB
	cfg   *Config
	gymDB string // database per-gym yang sudah di-resolve (kosong untuk route non-tenant)
	role  string // role membership yang sudah di-resolve
}

func (h *Handler) queryRows(q string, args ...interface{}) ([]map[string]interface{}, error) {
	return rowsToMaps(h.db, q, args...)
}

func (h *Handler) queryRow(q string, args ...interface{}) (map[string]interface{}, error) {
	return rowToMap(h.db, q, args...)
}

func (h *Handler) exec(q string, args ...interface{}) error {
	_, err := h.db.Exec(q, args...)
	return err
}

type routeFunc func(h *Handler, req *apiRequest) (map[string]interface{}, string, *APIError)

type routeEntry struct {
	fn     routeFunc
	tenant bool // butuh resolveSpreadsheetID (gym_id dalam payload)
	pub    bool // tanpa sesi (auth.google)
	lim    int  // rate limit per menit per user untuk action sensitif
}

type Router struct {
	db     *sql.DB
	cfg    *Config
	routes map[string]routeEntry
	mu     sync.Mutex
	rate   map[string]rateWindow
}

func NewRouter(db *sql.DB, cfg *Config) *Router {
	r := &Router{db: db, cfg: cfg, rate: map[string]rateWindow{}}
	r.routes = map[string]routeEntry{
		// auth
		"auth.google": {fn: (*Handler).handleAuthGoogle, pub: true, lim: 5},
		"auth.me":     {fn: (*Handler).handleAuthMe, lim: 60},
		"auth.logout": {fn: (*Handler).handleAuthLogout, lim: 30},
		// gyms
		"gyms.create":      {fn: (*Handler).handleGymsCreate, lim: 5},
		"gyms.list":        {fn: (*Handler).handleGymsList, lim: 60},
		"gyms.detail":      {fn: (*Handler).handleGymsDetail, lim: 60},
		"gyms.update":      {fn: (*Handler).handleGymsUpdate, lim: 30},
		"memberships.list": {fn: (*Handler).handleMembershipsList, lim: 60},
		// integrasi (di Go = provisioning DB per-gym; diekspos agar Flutter kompatibel)
		"integrations.connect":            {fn: (*Handler).handleIntegrationConnect, lim: 10},
		"integrations.callback":           {fn: (*Handler).handleIntegrationStub, lim: 10},
		"integrations.status":             {fn: (*Handler).handleIntegrationStatus, lim: 60},
		"integrations.create-spreadsheet": {fn: (*Handler).handleCreateGymDB, lim: 10},
		"integrations.disconnect":         {fn: (*Handler).handleIntegrationDisconnect, lim: 10},
		// members
		"members.list":       {fn: (*Handler).handleMembersList, tenant: true, lim: 60},
		"members.create":     {fn: (*Handler).handleMembersCreate, tenant: true, lim: 30},
		"members.update":     {fn: (*Handler).handleMembersUpdate, tenant: true, lim: 30},
		"members.deactivate": {fn: (*Handler).handleMembersDeactivate, tenant: true, lim: 30},
		// facilities
		"facilities.list":       {fn: (*Handler).handleFacilitiesList, tenant: true, lim: 60},
		"facilities.create":     {fn: (*Handler).handleFacilitiesCreate, tenant: true, lim: 30},
		"facilities.update":     {fn: (*Handler).handleFacilitiesUpdate, tenant: true, lim: 30},
		"facilities.deactivate": {fn: (*Handler).handleFacilitiesDeactivate, tenant: true, lim: 30},
		// schedules
		"schedules.list":       {fn: (*Handler).handleSchedulesList, tenant: true, lim: 60},
		"schedules.create":     {fn: (*Handler).handleSchedulesCreate, tenant: true, lim: 30},
		"schedules.update":     {fn: (*Handler).handleSchedulesUpdate, tenant: true, lim: 30},
		"schedules.deactivate": {fn: (*Handler).handleSchedulesDeactivate, tenant: true, lim: 30},
		// bookings
		"bookings.list":   {fn: (*Handler).handleBookingsList, tenant: true, lim: 60},
		"bookings.my":     {fn: (*Handler).handleBookingsMy, tenant: true, lim: 60},
		"bookings.create": {fn: (*Handler).handleBookingsCreate, tenant: true, lim: 10},
		"bookings.cancel": {fn: (*Handler).handleBookingsCancel, tenant: true, lim: 30},
		// attendance
		"attendance.list":    {fn: (*Handler).handleAttendanceList, tenant: true, lim: 60},
		"attendance.checkin": {fn: (*Handler).handleAttendanceCheckin, tenant: true, lim: 30},
		// settings
		"settings.get":    {fn: (*Handler).handleSettingsGet, tenant: true, lim: 60},
		"settings.update": {fn: (*Handler).handleSettingsUpdate, tenant: true, lim: 10},
		// dashboard
		"dashboard.stats":  {fn: (*Handler).handleDashboardStats, tenant: true, lim: 60},
		"dashboard.charts": {fn: (*Handler).handleDashboardCharts, tenant: true, lim: 60},
	}
	return r
}

var reAction = regexp.MustCompile(`^[\w.\-]{1,64}$`)

// requestIDValid: hanya cek panjang (1-128), sama seperti Apps Script —
// tanpa batasan karakter agar kontrak tidak berubah.
func requestIDValid(s string) bool { return len(s) <= 128 }

// ServeHTTP: parse body → validasi → rate limit → auth sesi → tenant resolve → dispatch.
func (rt *Router) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	reqID := ""
	start := time.Now()
	defer func() {
		if rec := recover(); rec != nil {
			LogInfo("panic %v (req=%s, %s)", rec, reqID, time.Since(start))
			writeJSON(w, 200, failShape(reqID, CodeInternal, "Terjadi kesalahan internal"))
		}
	}()

	// Health check (GET/POST) — mendukung path di balik funnel (/gymslot, /gymslot-api, dll).
	if r.URL.Path == "/health" || strings.HasSuffix(r.URL.Path, "/health") {
		writeJSON(w, 200, map[string]string{"status": "ok", "backend": "go", "env": rt.cfg.Env, "time": NowISO()})
		return
	}
	if r.Method != http.MethodPost {
		writeJSON(w, 405, failShape("", CodeValidationError, "Method harus POST"))
		return
	}
	// Terima path apa pun untuk POST: routing ditentukan oleh body.action,
	// sehingga aman di balik reverse-proxy/funnel dengan prefix path.

	var req apiRequest
	if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1<<20)).Decode(&req); err != nil {
		writeJSON(w, 200, failShape("", CodeValidationError, "Body JSON tidak valid"))
		return
	}
	reqID = req.RequestID
	if !reAction.MatchString(req.Action) {
		writeJSON(w, 200, failShape(reqID, CodeValidationError, "Action tidak valid"))
		return
	}
	if req.RequestID != "" && !requestIDValid(req.RequestID) {
		writeJSON(w, 200, failShape(reqID, CodeValidationError, "request_id tidak valid"))
		return
	}
	if req.Version != "" && req.Version != "v1" {
		writeJSON(w, 200, failShape(reqID, CodeValidationError, "Version harus v1"))
		return
	}

	route, found := rt.routes[req.Action]
	if !found {
		writeJSON(w, 200, failShape(reqID, CodeValidationError, "Action tidak dikenal: "+req.Action))
		return
	}

	// Rate limit per IP+action (pra-auth).
	ip := remoteIP(r.RemoteAddr)
	if !rt.allow("ip:"+ip+":"+req.Action, 120) {
		writeJSON(w, 429, failShape(reqID, CodeRateLimited, "Terlalu banyak permintaan"))
		return
	}

	h := &Handler{db: rt.db, cfg: rt.cfg}
	userID := ""
	if !route.pub {
		var aerr *APIError
		userID, aerr = h.requireSession(&req)
		if aerr != nil {
			fail(w, reqID, aerr)
			return
		}
	}

	// Rate limit per user untuk action sensitif.
	if userID != "" && route.lim > 0 && route.lim < 60 {
		if !rt.allow("u:"+userID+":"+req.Action, route.lim) {
			fail(w, reqID, apiErr(CodeRateLimited, "Terlalu banyak permintaan, coba lagi sebentar"))
			return
		}
	}

	// Tenant: resolve DB per-gym dari membership backend, bukan dari payload.
	if route.tenant {
		gymDB, aerr := h.resolveSpreadsheetID(userID, req.Payload)
		if aerr != nil {
			fail(w, reqID, aerr)
			return
		}
		h.gymDB = gymDB
	}

	data, msg, aerr := route.fn(h, &req)
	if aerr != nil {
		fail(w, reqID, aerr)
		return
	}
	ok(w, reqID, data, msg)
}

func (rt *Router) Run(addr string) error {
	return http.ListenAndServe(addr, rt)
}

func remoteIP(addr string) string {
	if i := strings.LastIndex(addr, ":"); i > 0 {
		return addr[:i]
	}
	return addr
}

// ============ Rate limiter in-memory ============

type rateWindow struct {
	start time.Time
	cnt   int
}

func (rt *Router) allow(key string, limit int) bool {
	rt.mu.Lock()
	defer rt.mu.Unlock()
	now := time.Now()
	win, found := rt.rate[key]
	if !found || now.Sub(win.start) >= time.Minute {
		rt.rate[key] = rateWindow{start: now, cnt: 1}
		if len(rt.rate) > 10000 {
			rt.pruneRate(now)
		}
		return true
	}
	if win.cnt >= limit {
		return false
	}
	win.cnt++
	rt.rate[key] = win
	return true
}

func (rt *Router) pruneRate(now time.Time) {
	for k, v := range rt.rate {
		if now.Sub(v.start) >= time.Minute {
			delete(rt.rate, k)
		}
	}
}

package main

import (
	"database/sql"
	"fmt"
	"strings"
)

// Error kode — harus sama persis dengan errors.gs Apps Script.
const (
	CodeAuthInvalid      = "AUTH_INVALID"
	CodeAuthExpired      = "AUTH_EXPIRED"
	CodePermissionDenied = "PERMISSION_DENIED"
	CodeGymNotFound      = "GYM_NOT_FOUND"
	CodeTenantAccess     = "TENANT_ACCESS_DENIED"
	CodeValidationError  = "VALIDATION_ERROR"
	CodeDuplicateBooking = "DUPLICATE_BOOKING"
	CodeCapacityFull     = "CAPACITY_FULL"
	CodeGoogleDisconnect = "GOOGLE_DISCONNECTED"
	CodeSheetNotFound    = "SHEET_NOT_FOUND"
	CodeRateLimited      = "RATE_LIMITED"
	CodeInternal         = "INTERNAL_ERROR"
	CodeMemberNotFound   = "MEMBER_NOT_FOUND"
	CodeFacilityNotFound = "FACILITY_NOT_FOUND"
	CodeScheduleNotFound = "SCHEDULE_NOT_FOUND"
	CodeScheduleConflict = "SCHEDULE_CONFLICT"
	CodeBookingNotFound  = "BOOKING_NOT_FOUND"
)

type APIError struct {
	Code    string
	Message string
	Status  int
	HTTP    bool // tampil sebagai HTTP status selain 200
}

func (e *APIError) Error() string { return e.Code + ": " + e.Message }

func apiErr(code, msg string) *APIError { return &APIError{Code: code, Message: msg} }

func validation(msg string) *APIError { return &APIError{Code: CodeValidationError, Message: msg} }

// mapStatus memberi HTTP status untuk error tertentu (Apps Script selalu 200;
// untuk Go kita pakai 200 juga agar kontrak Flutter identik, kecuali RATE_LIMITED 429).
func mapStatus(e *APIError) int {
	if e.Code == CodeRateLimited {
		return 429
	}
	return 200
}

// DB helpers — mirror controlRepository.gs (rows as map[string]any).
func rowsToMaps(db *sql.DB, query string, args ...interface{}) ([]map[string]interface{}, error) {
	rs, err := db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rs.Close()
	cols, _ := rs.Columns()
	vals := make([]interface{}, len(cols))
	ptrs := make([]interface{}, len(cols))
	for i := range vals {
		ptrs[i] = &vals[i]
	}
	out := []map[string]interface{}{}
	for rs.Next() {
		if err := rs.Scan(ptrs...); err != nil {
			return nil, err
		}
		m := map[string]interface{}{}
		for i, c := range cols {
			v := vals[i]
			if b, ok := v.([]byte); ok {
				m[c] = string(b)
			} else {
				m[c] = v
			}
		}
		out = append(out, m)
	}
	return out, rs.Err()
}

func rowToMap(db *sql.DB, query string, args ...interface{}) (map[string]interface{}, error) {
	rows, err := rowsToMaps(db, query, args...)
	if err != nil {
		return nil, err
	}
	if len(rows) == 0 {
		return nil, sql.ErrNoRows
	}
	return rows[0], nil
}

func colNames(m map[string]interface{}, allowed []string) (cols []string, qs []string, vals []interface{}) {
	for _, k := range allowed {
		if v, ok := m[k]; ok {
			cols = append(cols, k)
			vals = append(vals, v)
			qs = append(qs, "?")
		}
	}
	return
}

// sanitizeInflight memotong value menjadi maxLen rune dan menghapus null byte.
func sanitize(s string, maxLen int) string {
	s = strings.ReplaceAll(s, "\x00", "")
	r := []rune(s)
	if len(r) > maxLen {
		return string(r[:maxLen])
	}
	return s
}

func fmtID(prefix string) string { return fmt.Sprintf("%s_%s", prefix, newUUID()) }

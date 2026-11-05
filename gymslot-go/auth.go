package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"net/http"
	"time"
)

// ============ Autentikasi ============
// Identitas permanen = google_sub (bukan email), sama seperti Apps Script.

type googleClaims struct {
	Aud           string `json:"aud"`
	Sub           string `json:"sub"`
	Email         string `json:"email"`
	EmailVerified string `json:"email_verified"`
	Name          string `json:"name"`
	Picture       string `json:"picture"`
	Iss           string `json:"iss"`
	Exp           string `json:"exp"`
}

var httpClient = &http.Client{Timeout: 10 * time.Second}

// verifyIDToken memvalidasi Google ID token (fail-closed bila client ID kosong,
// sesuai Phase 7 hardening). Mode development menerima token "dev" untuk
// testing lokal tanpa Google.
func (h *Handler) verifyIDToken(idToken string) (*googleClaims, *APIError) {
	if idToken == "" {
		return nil, apiErr(CodeAuthInvalid, "ID token tidak ada")
	}
	if h.cfg.Env == "development" && idToken == "dev" {
		return &googleClaims{
			Sub:           env("GYMSLOT_DEV_SUB", "dev-user-1"),
			Email:         env("GYMSLOT_DEV_EMAIL", "dev@example.com"),
			Name:          env("GYMSLOT_DEV_NAME", "Dev User"),
			EmailVerified: "true",
			Aud:           h.cfg.GoogleClientID,
		}, nil
	}
	if h.cfg.GoogleClientID == "" {
		return nil, apiErr(CodeAuthInvalid, "Server belum dikonfigurasi GOOGLE_CLIENT_ID")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet,
		"https://oauth2.googleapis.com/tokeninfo?id_token="+idToken, nil)
	if err != nil {
		return nil, apiErr(CodeAuthInvalid, "Token tidak valid")
	}
	resp, err := httpClient.Do(req)
	if err != nil {
		return nil, apiErr(CodeAuthInvalid, "Verifikasi token gagal")
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		return nil, apiErr(CodeAuthInvalid, "Token tidak valid")
	}
	var c googleClaims
	if err := json.NewDecoder(resp.Body).Decode(&c); err != nil {
		return nil, apiErr(CodeAuthInvalid, "Token tidak valid")
	}
	if c.Aud != h.cfg.GoogleClientID {
		return nil, apiErr(CodeAuthInvalid, "Token bukan untuk aplikasi ini")
	}
	if c.Iss != "accounts.google.com" && c.Iss != "https://accounts.google.com" {
		return nil, apiErr(CodeAuthInvalid, "Issuer token tidak dikenal")
	}
	if exp, err := atoi64(c.Exp); err != nil || exp <= time.Now().Unix() {
		return nil, apiErr(CodeAuthExpired, "Token kedaluwarsa")
	}
	if c.EmailVerified == "false" {
		return nil, apiErr(CodeAuthInvalid, "Email Google belum terverifikasi")
	}
	if c.Sub == "" {
		return nil, apiErr(CodeAuthInvalid, "Token tidak memiliki subject")
	}
	return &c, nil
}

func atoi64(s string) (int64, error) {
	var n int64
	for _, r := range s {
		if r < '0' || r > '9' {
			return 0, errBadNumber
		}
		n = n*10 + int64(r-'0')
	}
	return n, nil
}

type constErr string

func (e constErr) Error() string { return string(e) }

const errBadNumber = constErr("bukan angka")

// ============ Sesi ============

const sessionTTL = 7 * 24 * time.Hour

func (h *Handler) createSession(userID string) (string, *APIError) {
	tok := randToken()
	_, err := h.db.Exec(`INSERT INTO `+h.cfg.ControlDB+`.sessions
		(session_token, user_id, created_at, expires_at, revoked) VALUES (?,?,?,?,0)`,
		tok, userID, NowUTC(), NowUTC().Add(sessionTTL))
	if err != nil {
		return "", apiErr(CodeInternal, "Gagal membuat sesi")
	}
	return tok, nil
}

// userIDFromToken mengembalikan user_id bila sesi valid.
func (h *Handler) userIDFromToken(token string) (string, *APIError) {
	if token == "" {
		return "", apiErr(CodeAuthExpired, "Sesi tidak ada")
	}
	row, err := rowToMap(h.db, `SELECT user_id, expires_at, revoked FROM `+h.cfg.ControlDB+`.sessions WHERE session_token = ?`, token)
	if err != nil {
		return "", apiErr(CodeAuthExpired, "Sesi tidak valid atau kedaluwarsa")
	}
	if row["revoked"] == int64(1) {
		return "", apiErr(CodeAuthExpired, "Sesi sudah logout")
	}
	if exp, okk := row["expires_at"].(time.Time); okk && exp.Before(NowUTC()) {
		return "", apiErr(CodeAuthExpired, "Sesi kedaluwarsa")
	}
	uid, _ := row["user_id"].(string)
	return uid, nil
}

func (h *Handler) revokeSession(token string) {
	_, _ = h.db.Exec(`UPDATE `+h.cfg.ControlDB+`.sessions SET revoked = 1 WHERE session_token = ?`, token)
}

// requireSession memvalidasi sesi dan mengembalikan user_id.
func (h *Handler) requireSession(req *apiRequest) (string, *APIError) {
	return h.userIDFromToken(req.Auth.SessionToken)
}

// upsertUser membuat/memperbarui profil user berdasarkan google_sub.
func (h *Handler) upsertUser(c *googleClaims) (map[string]interface{}, *APIError) {
	now := NowUTC()
	existing, err := rowToMap(h.db, `SELECT user_id, google_sub, email, name, picture, created_at, updated_at
		FROM `+h.cfg.ControlDB+`.users WHERE google_sub = ?`, c.Sub)
	if err == nil {
		_, _ = h.db.Exec(`UPDATE `+h.cfg.ControlDB+`.users SET email=?, name=?, picture=?, updated_at=? WHERE google_sub=?`,
			c.Email, c.Name, c.Picture, now, c.Sub)
		existing["email"] = c.Email
		existing["name"] = c.Name
		existing["picture"] = c.Picture
		return existing, nil
	}
	if err != sql.ErrNoRows {
		return nil, apiErr(CodeInternal, "Gagal membaca pengguna")
	}
	userID := fmtID("usr")
	_, err = h.db.Exec(`INSERT INTO `+h.cfg.ControlDB+`.users
		(user_id, google_sub, email, name, picture, created_at, updated_at) VALUES (?,?,?,?,?,?,?)`,
		userID, c.Sub, c.Email, c.Name, c.Picture, now, now)
	if err != nil {
		return nil, apiErr(CodeInternal, "Gagal membuat pengguna")
	}
	return map[string]interface{}{
		"user_id": userID, "google_sub": c.Sub, "email": c.Email,
		"name": c.Name, "picture": c.Picture,
		"created_at": iso(now), "updated_at": iso(now),
	}, nil
}

func (h *Handler) userByID(userID string) map[string]interface{} {
	row, err := rowToMap(h.db, `SELECT user_id, google_sub, email, name, picture, created_at, updated_at
		FROM `+h.cfg.ControlDB+`.users WHERE user_id = ?`, userID)
	if err != nil {
		return nil
	}
	return row
}

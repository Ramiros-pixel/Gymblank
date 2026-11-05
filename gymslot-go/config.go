package main

import (
	"os"
)

// Config semua via env — tidak ada secret di source.
type Config struct {
	Addr           string
	DSN            string
	JWTSecret      string // dev fallback; prod wajib dari env
	GoogleClientID string
	ControlDB      string
	Env            string // "development" | "production"
}

func env(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func LoadConfig() *Config {
	port := env("GYMSLOT_PORT", "8090")
	return &Config{
		Addr:           "127.0.0.1:" + port,
		DSN:            env("GYMSLOT_DSN", ""),
		JWTSecret:      env("GYMSLOT_JWT_SECRET", ""),
		GoogleClientID: env("GYMSLOT_GOOGLE_CLIENT_ID", ""),
		ControlDB:      env("GYMSLOT_DB", "gymslot_control"),
		Env:            env("GYMSLOT_ENV", "development"),
	}
}

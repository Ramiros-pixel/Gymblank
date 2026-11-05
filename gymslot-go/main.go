// Package main — GymSlot backend dalam Go.
// Satu handler: POST {action, version, request_id, payload, auth{session_token,id_token}}
// Respons identik dengan backend Apps Script: {success, request_id, data, message} / {success, request_id, error{code,message}}
package main

import (
	_ "github.com/go-sql-driver/mysql"
)

func main() {
	cfg := LoadConfig()
	if err := EnsureSchema(cfg); err != nil {
		LogInfo("schema: %v", err)
	}
	db := MustOpenDB(cfg)
	defer db.Close()
	// Warm-up koneksi: gagal cepat di sini daripada 502 di tengah request pertama.
	if err := db.Ping(); err != nil {
		LogInfo("db ping: %v", err)
	}
	r := NewRouter(db, cfg)
	addr := cfg.Addr
	LogInfo("GymSlot Go backend listening on %s", addr)
	if err := r.Run(addr); err != nil {
		LogInfo("server: %v", err)
	}
}

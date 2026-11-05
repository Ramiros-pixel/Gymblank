package main

import (
	"database/sql"
	"fmt"
	"strings"
	"time"

	_ "github.com/go-sql-driver/mysql"
)

// MustOpenDB membuka koneksi ke server MySQL (tanpa memilih database;
// tiap fungsi menyebut nama DB secara eksplisit, atau USE per operasi).
func MustOpenDB(cfg *Config) *sql.DB {
	dsn := cfg.DSN
	if dsn == "" {
		// Default lokal: root tanpa password via unix socket.
		dsn = "root@unix(/var/run/mysqld/mysqld.sock)/?parseTime=true&multiStatements=true"
	}
	if !strings.Contains(dsn, "parseTime") {
		if strings.Contains(dsn, "?") {
			dsn += "&parseTime=true"
		} else {
			dsn += "?parseTime=true"
		}
	}
	db, err := sql.Open("mysql", dsn)
	if err != nil {
		panic(err)
	}
	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)
	return db
}

func ensureDatabase(db *sql.DB, name string) error {
	if !validDBName(name) {
		return fmt.Errorf("invalid db name %q", name)
	}
	_, err := db.Exec("CREATE DATABASE IF NOT EXISTS `" + name + "` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
	return err
}

func validDBName(s string) bool {
	if len(s) == 0 || len(s) > 64 {
		return false
	}
	for _, r := range s {
		ok := r == '_' || (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9')
		if !ok {
			return false
		}
	}
	return true
}

// EnsureSchema membuat database kontrol + tabelnya (idempotent).
func EnsureSchema(cfg *Config) error {
	db := MustOpenDB(cfg)
	defer db.Close()
	if err := ensureDatabase(db, cfg.ControlDB); err != nil {
		return err
	}
	if err := use(db, cfg.ControlDB, controlSchemaSQL); err != nil {
		return err
	}
	return nil
}

func use(db *sql.DB, dbname string, stmts []string) error {
	if _, err := db.Exec("USE `" + dbname + "`"); err != nil {
		return fmt.Errorf("use %s: %w", dbname, err)
	}
	for _, s := range stmts {
		if _, err := db.Exec(s); err != nil {
			return fmt.Errorf("%s: %w", dbname, err)
		}
	}
	return nil
}

var controlSchemaSQL = []string{
	`CREATE TABLE IF NOT EXISTS users (
		user_id VARCHAR(64) PRIMARY KEY,
		google_sub VARCHAR(64) NOT NULL UNIQUE,
		email VARCHAR(255) NOT NULL,
		name VARCHAR(255) NOT NULL DEFAULT '',
		picture VARCHAR(512) NOT NULL DEFAULT '',
		created_at DATETIME NOT NULL,
		updated_at DATETIME NOT NULL
	) ENGINE=InnoDB`,
	`CREATE TABLE IF NOT EXISTS gyms (
		gym_id VARCHAR(64) PRIMARY KEY,
		owner_user_id VARCHAR(64) NOT NULL,
		name VARCHAR(255) NOT NULL,
		address VARCHAR(512) NOT NULL DEFAULT '',
		phone VARCHAR(64) NOT NULL DEFAULT '',
		contact_email VARCHAR(255) NOT NULL DEFAULT '',
		description TEXT,
		logo_url VARCHAR(512) NOT NULL DEFAULT '',
		timezone VARCHAR(64) NOT NULL DEFAULT 'Asia/Jakarta',
		status VARCHAR(32) NOT NULL DEFAULT 'Active',
		` + "`database`" + ` VARCHAR(64) NOT NULL DEFAULT '',
		created_at DATETIME NOT NULL,
		updated_at DATETIME NOT NULL
	) ENGINE=InnoDB`,
	`CREATE TABLE IF NOT EXISTS memberships (
		membership_id VARCHAR(64) PRIMARY KEY,
		user_id VARCHAR(64) NOT NULL,
		gym_id VARCHAR(64) NOT NULL,
		role VARCHAR(32) NOT NULL,
		status VARCHAR(32) NOT NULL DEFAULT 'Active',
		created_at DATETIME NOT NULL,
		updated_at DATETIME NOT NULL,
		UNIQUE KEY uq_user_gym (user_id, gym_id)
	) ENGINE=InnoDB`,
	`CREATE TABLE IF NOT EXISTS sessions (
		session_token VARCHAR(128) PRIMARY KEY,
		user_id VARCHAR(64) NOT NULL,
		created_at DATETIME NOT NULL,
		expires_at DATETIME NOT NULL,
		revoked TINYINT NOT NULL DEFAULT 0,
		KEY idx_user (user_id)
	) ENGINE=InnoDB`,
	`CREATE TABLE IF NOT EXISTS integrations (
		integration_id VARCHAR(64) PRIMARY KEY,
		gym_id VARCHAR(64) NOT NULL,
		provider VARCHAR(32) NOT NULL DEFAULT 'mysql',
		status VARCHAR(32) NOT NULL DEFAULT 'Connected',
		access_token TEXT,
		refresh_token TEXT,
		token_expiry DATETIME NULL,
		updated_at DATETIME NOT NULL,
		UNIQUE KEY uq_gym_provider (gym_id, provider)
	) ENGINE=InnoDB`,
	`CREATE TABLE IF NOT EXISTS invitations (
		invitation_id VARCHAR(64) PRIMARY KEY,
		gym_id VARCHAR(64) NOT NULL,
		email VARCHAR(255) NOT NULL,
		role VARCHAR(32) NOT NULL,
		status VARCHAR(32) NOT NULL DEFAULT 'Pending',
		invited_by VARCHAR(64) NOT NULL,
		created_at DATETIME NOT NULL,
		accepted_at DATETIME NULL
	) ENGINE=InnoDB`,
	`CREATE TABLE IF NOT EXISTS audit_logs (
		id BIGINT AUTO_INCREMENT PRIMARY KEY,
		gym_id VARCHAR(64) NOT NULL DEFAULT '',
		actor_user_id VARCHAR(64) NOT NULL DEFAULT '',
		action VARCHAR(128) NOT NULL,
		resource_type VARCHAR(64) NOT NULL DEFAULT '',
		resource_id VARCHAR(64) NOT NULL DEFAULT '',
		detail TEXT,
		created_at DATETIME NOT NULL,
		KEY idx_gym (gym_id),
		KEY idx_actor (actor_user_id)
	) ENGINE=InnoDB`,
	`CREATE TABLE IF NOT EXISTS rate_limits (
		rkey VARCHAR(255) PRIMARY KEY,
		cnt INT NOT NULL DEFAULT 0,
		window_start DATETIME NOT NULL
	) ENGINE=InnoDB`,
}

// Schema per-gym (pengganti spreadsheet GymBooking).
var gymSchemaSQL = []string{
	`CREATE TABLE IF NOT EXISTS members (
		member_id VARCHAR(64) PRIMARY KEY,
		user_id VARCHAR(64) NOT NULL DEFAULT '',
		full_name VARCHAR(255) NOT NULL,
		email VARCHAR(255) NOT NULL DEFAULT '',
		phone VARCHAR(64) NOT NULL DEFAULT '',
		join_date DATE NULL,
		membership_status VARCHAR(32) NOT NULL DEFAULT 'Active',
		created_at DATETIME NOT NULL,
		updated_at DATETIME NOT NULL,
		KEY idx_status (membership_status)
	) ENGINE=InnoDB`,
	`CREATE TABLE IF NOT EXISTS facilities (
		facility_id VARCHAR(64) PRIMARY KEY,
		gym_id VARCHAR(64) NOT NULL DEFAULT '',
		facility_name VARCHAR(255) NOT NULL,
		description TEXT,
		capacity INT NOT NULL DEFAULT 0,
		status VARCHAR(32) NOT NULL DEFAULT 'Active',
		created_at DATETIME NOT NULL,
		updated_at DATETIME NOT NULL
	) ENGINE=InnoDB`,
	`CREATE TABLE IF NOT EXISTS schedules (
		schedule_id VARCHAR(64) PRIMARY KEY,
		facility_id VARCHAR(64) NOT NULL,
		schedule_date DATE NOT NULL,
		start_time TIME NOT NULL,
		end_time TIME NOT NULL,
		capacity INT NOT NULL DEFAULT 0,
		status VARCHAR(32) NOT NULL DEFAULT 'Active',
		created_at DATETIME NOT NULL,
		updated_at DATETIME NOT NULL,
		KEY idx_fac_date (facility_id, schedule_date)
	) ENGINE=InnoDB`,
	`CREATE TABLE IF NOT EXISTS bookings (
		booking_id VARCHAR(64) PRIMARY KEY,
		member_id VARCHAR(64) NOT NULL,
		schedule_id VARCHAR(64) NOT NULL,
		facility_id VARCHAR(64) NOT NULL DEFAULT '',
		booking_status VARCHAR(32) NOT NULL DEFAULT 'Confirmed',
		cancelled_at DATETIME NULL,
		created_at DATETIME NOT NULL,
		updated_at DATETIME NOT NULL,
		KEY idx_sched (schedule_id),
		KEY idx_member (member_id)
	) ENGINE=InnoDB`,
	`CREATE TABLE IF NOT EXISTS attendance (
		attendance_id VARCHAR(64) PRIMARY KEY,
		member_id VARCHAR(64) NOT NULL,
		booking_id VARCHAR(64) NULL,
		check_in_at DATETIME NOT NULL,
		attendance_method VARCHAR(32) NOT NULL DEFAULT 'manual',
		device_id VARCHAR(128) NOT NULL DEFAULT '',
		created_by VARCHAR(64) NOT NULL DEFAULT '',
		created_at DATETIME NOT NULL,
		KEY idx_member (member_id),
		KEY idx_checkin (check_in_at)
	) ENGINE=InnoDB`,
	`CREATE TABLE IF NOT EXISTS settings (
		skey VARCHAR(64) PRIMARY KEY,
		svalue VARCHAR(255) NOT NULL,
		updated_at DATETIME NOT NULL
	) ENGINE=InnoDB`,
	`CREATE TABLE IF NOT EXISTS audit_logs (
		id BIGINT AUTO_INCREMENT PRIMARY KEY,
		gym_id VARCHAR(64) NOT NULL DEFAULT '',
		actor_user_id VARCHAR(64) NOT NULL DEFAULT '',
		action VARCHAR(128) NOT NULL,
		resource_type VARCHAR(64) NOT NULL DEFAULT '',
		resource_id VARCHAR(64) NOT NULL DEFAULT '',
		detail TEXT,
		created_at DATETIME NOT NULL
	) ENGINE=InnoDB`,
	`CREATE TABLE IF NOT EXISTS dashboard_cache (
		cache_key VARCHAR(255) PRIMARY KEY,
		payload JSON NOT NULL,
		generated_at DATETIME NOT NULL,
		expires_at DATETIME NOT NULL
	) ENGINE=InnoDB`,
}

// ensureGymDB membuat database + tabel per-gym (idempotent; pengganti
// integrations.create-spreadsheet). Nama DB = spreadsheet_id di sisi Go.
func ensureGymDB(db *sql.DB, dbname string) error {
	if err := ensureDatabase(db, dbname); err != nil {
		return err
	}
	return use(db, dbname, gymSchemaSQL)
}

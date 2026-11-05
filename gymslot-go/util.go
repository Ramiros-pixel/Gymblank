package main

import (
	"crypto/rand"
	"encoding/hex"
	"log"
	"time"
)

func NowUTC() time.Time { return time.Now().UTC() }

func NowISO() string { return NowUTC().Format("2006-01-02T15:04:05.000Z") }

func todayLocal(tz string) string {
	loc, err := time.LoadLocation(tz)
	if err != nil {
		loc = time.FixedZone("WIB", 7*3600)
	}
	return time.Now().In(loc).Format("2006-01-02")
}

func newUUID() string {
	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		panic(err)
	}
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	h := hex.EncodeToString(b)
	return h[0:8] + "-" + h[8:12] + "-" + h[12:16] + "-" + h[16:20] + "-" + h[20:32]
}

func randToken() string {
	b := make([]byte, 24)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}

func LogInfo(format string, args ...interface{}) {
	log.Printf("[gymslot] "+format, args...)
}

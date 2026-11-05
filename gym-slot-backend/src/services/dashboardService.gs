/**
 * dashboardService.gs
 * Agregasi statistik dashboard dari data aktual spreadsheet gym (PRD 8.1 & 15).
 * Semua angka dihitung dari tab Members, Schedules, Bookings, Attendance.
 * Tidak ada data dummy: jika belum ada data, nilai 0 / array kosong.
 *
 * Zona waktu referensi "hari ini": timezone gym dari tab Settings
 * (fallback Asia/Jakarta). Tanggal disimpan/dibandingkan sebagai string
 * YYYY-MM-DD pada kolom schedule_date; timestamp ISO dibandingkan sebagai
 * tanggal lokal zona gym.
 *
 * CACHE (Phase 6): agregat dashboard di-cache di CacheService (TTL 60 detik)
 * untuk melindungi kuota Sheets API. Kunci memakai "generation" per gym;
 * DashboardService.invalidate(ssId) menaikkan generation sehingga semua
 * key lama otomatis tak terpakai. Service operasional (booking, attendance,
 * member, schedule, facility) memanggil invalidate setelah data berubah.
 * generated_at tetap mencatat waktu agregasi — angka cache tidak
 * ditampilkan seolah-olah dihitung baru.
 */

var DashboardService = (function () {
  /** Status booking yang dihitung sebagai booking hari ini/mendatang. */
  var ACTIVE_STATUSES = ['Pending', 'Confirmed'];

  var CACHE_TTL_SECONDS = 60;

  /** Nomor generasi cache per gym (naik saat invalidate). */
  function getGeneration(ssId) {
    var g = CacheService.getScriptCache().get('dash:gen:' + ssId);
    return g ? String(g) : '0';
  }

  function cacheGet(key) {
    var raw = CacheService.getScriptCache().get(key);
    if (!raw) return null;
    try {
      return JSON.parse(raw);
    } catch (e) {
      return null;
    }
  }

  function cachePut(key, value) {
    CacheService.getScriptCache().put(key, JSON.stringify(value), CACHE_TTL_SECONDS);
  }

  /**
   * Kosongkan cache dashboard gym. Dipanggil service operasional setelah
   * ada perubahan data; key lama otomatis tidak terpakai karena generation
   * naik (key baru berbeda).
   */
  function invalidate(ssId) {
    var cache = CacheService.getScriptCache();
    var current = cache.get('dash:gen:' + ssId);
    var next = (current ? Number(current) : 0) + 1;
    cache.put('dash:gen:' + ssId, String(next), 21600);
  }

  /**
   * Ambil timezone gym dari Settings (fallback Asia/Jakarta).
   */
  function getGymTimezone(ssId) {
    try {
      var tz = GymSettingsService.get(ssId, 'timezone');
      if (tz && tz.trim() !== '') return tz.trim();
    } catch (e) {
      // Fallback di bawah.
    }
    return 'Asia/Jakarta';
  }

  /**
   * Tanggal hari ini (YYYY-MM-DD) menurut zona waktu gym.
   */
  function todayString(timezone) {
    var fmt = 'yyyy-MM-dd';
    return Utilities.formatDate(new Date(), timezone, fmt);
  }

  /**
   * Tanggal N hari ke belakang dari hari ini (YYYY-MM-DD).
   */
  function daysAgoString(n, timezone) {
    var d = new Date(Date.now() - n * 24 * 60 * 60 * 1000);
    return Utilities.formatDate(d, timezone, 'yyyy-MM-dd');
  }

  /**
   * Bagian tanggal (YYYY-MM-DD) dari ISO timestamp menurut zona gym.
   */
  function isoToLocalDate(iso, timezone) {
    if (!iso) return '';
    var d = new Date(iso);
    if (isNaN(d.getTime())) return String(iso).substring(0, 10);
    return Utilities.formatDate(d, timezone, 'yyyy-MM-dd');
  }

  /** Hari dalam rentang [startYmd, endYmd] inklusif sebagai array YYYY-MM-DD. */
  function dateRange(startYmd, endYmd) {
    var out = [];
    var start = new Date(startYmd + 'T00:00:00Z');
    var end = new Date(endYmd + 'T00:00:00Z');
    for (var t = start.getTime(); t <= end.getTime(); t += 24 * 60 * 60 * 1000) {
      out.push(new Date(t).toISOString().substring(0, 10));
    }
    return out;
  }

  /**
   * Statistik kartu (PRD 15).
   * @param {string} ssId - spreadsheet ID gym.
   * @returns {Object} {total_members, active_members, bookings_today,
   *   upcoming_bookings, attendance_today, cancelled_bookings, generated_at}
   */
  function getStats(ssId) {
    var cacheKey = 'dash:' + getGeneration(ssId) + ':stats:' + ssId;
    var cached = cacheGet(cacheKey);
    if (cached) return cached;

    var timezone = getGymTimezone(ssId);
    var today = todayString(timezone);

    var members = GymRepository.getAllRows(ssId, 'Members');
    var schedules = GymRepository.getAllRows(ssId, 'Schedules');
    var bookings = GymRepository.getAllRows(ssId, 'Bookings');
    var attendance = GymRepository.getAllRows(ssId, 'Attendance');

    // Kartu anggota.
    var totalMembers = members.length;
    var activeMembers = 0;
    for (var i = 0; i < members.length; i++) {
      if (String(members[i].membership_status) === 'Active') activeMembers++;
    }

    // Booking aktif hari ini (berdasarkan tanggal jadwal).
    var scheduleDateById = {};
    for (var s = 0; s < schedules.length; s++) {
      scheduleDateById[String(schedules[s].schedule_id)] = String(schedules[s].schedule_date);
    }

    var bookingsToday = 0;
    var upcomingBookings = 0;
    var cancelledBookings = 0;
    var statusCounts = { Pending: 0, Confirmed: 0, Completed: 0, Cancelled: 0, Rejected: 0 };

    for (var b = 0; b < bookings.length; b++) {
      var status = String(bookings[b].booking_status || '');
      if (statusCounts.hasOwnProperty(status)) statusCounts[status]++;

      if (status === 'Cancelled') cancelledBookings++;

      if (ACTIVE_STATUSES.indexOf(status) !== -1) {
        var sdate = scheduleDateById[String(bookings[b].schedule_id)] || '';
        if (sdate === today) bookingsToday++;
        else if (sdate > today) upcomingBookings++;
      }
    }

    // Kehadiran hari ini (check_in_at dikonversi ke tanggal lokal gym).
    var attendanceToday = 0;
    for (var a = 0; a < attendance.length; a++) {
      if (isoToLocalDate(attendance[a].check_in_at, timezone) === today) {
        attendanceToday++;
      }
    }

    var result = {
      total_members: totalMembers,
      active_members: activeMembers,
      bookings_today: bookingsToday,
      upcoming_bookings: upcomingBookings,
      attendance_today: attendanceToday,
      cancelled_bookings: cancelledBookings,
      generated_at: DateTimeHelper.nowIso(),
    };
    cachePut(cacheKey, result);
    return result;
  }

  /**
   * Data grafik (PRD 8.1): tren booking, tren kehadiran, status booking,
   * fasilitas populer, jam ramai.
   * @param {string} ssId
   * @param {string} range - 'today' | '7d' | '30d' | 'custom'
   * @param {string} [startDate] - YYYY-MM-DD (untuk custom)
   * @param {string} [endDate] - YYYY-MM-DD (untuk custom)
   */
  function getCharts(ssId, range, startDate, endDate) {
    var timezone = getGymTimezone(ssId);
    var today = todayString(timezone);

    var start, end;
    if (range === 'today') {
      start = today; end = today;
    } else if (range === '30d') {
      start = daysAgoString(29, timezone); end = today;
    } else if (range === 'custom' && startDate && endDate) {
      start = String(startDate).substring(0, 10);
      end = String(endDate).substring(0, 10);
      if (end < start) {
        throw Error('VALIDATION_ERROR', 'endDate harus setelah startDate');
      }
    } else {
      // default 7 hari terakhir.
      start = daysAgoString(6, timezone); end = today;
    }

    var cacheKey = 'dash:' + getGeneration(ssId) + ':charts:' + ssId +
      ':' + (range || '7d') + ':' + (start || '') + ':' + (end || '');
    var cached = cacheGet(cacheKey);
    if (cached) return cached;

    var days = dateRange(start, end);

    var schedules = GymRepository.getAllRows(ssId, 'Schedules');
    var facilities = GymRepository.getAllRows(ssId, 'Facilities');
    var bookings = GymRepository.getAllRows(ssId, 'Bookings');
    var attendance = GymRepository.getAllRows(ssId, 'Attendance');

    var facilityNameById = {};
    for (var f = 0; f < facilities.length; f++) {
      facilityNameById[String(facilities[f].facility_id)] = String(facilities[f].facility_name);
    }

    // index jadwal: schedule_id → {date, start, facility}
    var scheduleById = {};
    for (var s = 0; s < schedules.length; s++) {
      scheduleById[String(schedules[s].schedule_id)] = {
        date: String(schedules[s].schedule_date),
        start: String(schedules[s].start_time),
        facilityId: String(schedules[s].facility_id),
      };
    }

    // --- Tren booking per hari (booking dibuat pada rentang). ---
    var bookingTrend = {};
    var attendanceTrend = {};
    for (var d = 0; d < days.length; d++) {
      bookingTrend[days[d]] = 0;
      attendanceTrend[days[d]] = 0;
    }
    for (var b = 0; b < bookings.length; b++) {
      var bday = isoToLocalDate(bookings[b].created_at, timezone);
      if (bookingTrend.hasOwnProperty(bday)) bookingTrend[bday]++;
    }
    for (var a = 0; a < attendance.length; a++) {
      var aday = isoToLocalDate(attendance[a].check_in_at, timezone);
      if (attendanceTrend.hasOwnProperty(aday)) attendanceTrend[aday]++;
    }

    // --- Status booking pada rentang. ---
    var statusCounts = { Pending: 0, Confirmed: 0, Completed: 0, Cancelled: 0, Rejected: 0 };
    // --- Fasilitas populer (booking aktif per fasilitas). ---
    var facilityCounts = {};
    // --- Jam ramai (jumlah booking aktif per jam mulai jadwal). ---
    var hourCounts = {};

    for (var k = 0; k < bookings.length; k++) {
      var st = String(bookings[k].booking_status || '');
      var inRange = false;
      var sch = scheduleById[String(bookings[k].schedule_id)];
      var activeLike = (st === 'Pending' || st === 'Confirmed' || st === 'Completed');

      if (sch && sch.date >= start && sch.date <= end) inRange = true;

      if (statusCounts.hasOwnProperty(st) && inRange) statusCounts[st]++;

      if (activeLike && inRange && sch) {
        var fname = facilityNameById[sch.facilityId] || sch.facilityId;
        facilityCounts[fname] = (facilityCounts[fname] || 0) + 1;

        var hour = sch.start.substring(0, 2);
        hourCounts[hour] = (hourCounts[hour] || 0) + 1;
      }
    }

    // Susun output stabil (sorted keys).
    var bookingTrendArr = days.map(function (d) { return { date: d, count: bookingTrend[d] }; });
    var attendanceTrendArr = days.map(function (d) { return { date: d, count: attendanceTrend[d] }; });

    var facilityArr = Object.keys(facilityCounts).map(function (name) {
      return { facility: name, count: facilityCounts[name] };
    }).sort(function (x, y) { return y.count - x.count; });

    var hourArr = Object.keys(hourCounts).sort().map(function (h) {
      return { hour: h + ':00', count: hourCounts[h] };
    });

    var charts = {
      range: range === 'custom' ? 'custom' : (range || '7d'),
      start_date: start,
      end_date: end,
      booking_trend: bookingTrendArr,
      attendance_trend: attendanceTrendArr,
      booking_status: statusCounts,
      popular_facilities: facilityArr,
      busy_hours: hourArr,
      generated_at: DateTimeHelper.nowIso(),
    };
    cachePut(cacheKey, charts);
    return charts;
  }

  return {
    getStats: getStats,
    getCharts: getCharts,
    invalidate: invalidate,
  };
})();

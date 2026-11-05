/**
 * bookingService.gs
 * Booking jadwal oleh anggota di tab Bookings (GymBooking spreadsheet).
 * Alur PRD 13: keanggotaan → jadwal → kapasitas → duplikat → LOCK →
 * validasi ulang → simpan.
 * Pencegahan overbooking: keputusan final diambil DI DALAM ScriptLock.
 */

var BookingService = (function () {
  /** Status yang menghabiskan kapasitas jadwal. */
  var ACTIVE_STATUSES = ['Pending', 'Confirmed'];

  function findAll(ssId) {
    return GymRepository.getAllRows(ssId, 'Bookings');
  }

  function findByBookingId(ssId, bookingId) {
    return GymRepository.findOne(ssId, 'Bookings', { booking_id: bookingId });
  }

  /** Hitung booking aktif untuk satu jadwal. */
  function countActiveForSchedule(ssId, scheduleId) {
    var rows = GymRepository.getAllRows(ssId, 'Bookings');
    var n = 0;
    for (var i = 0; i < rows.length; i++) {
      if (String(rows[i].schedule_id) === String(scheduleId) &&
          ACTIVE_STATUSES.indexOf(String(rows[i].booking_status)) !== -1) {
        n++;
      }
    }
    return n;
  }

  /** Cari booking aktif milik member pada satu jadwal (deteksi duplikat). */
  function findActiveByMemberAndSchedule(ssId, memberId, scheduleId) {
    var rows = GymRepository.getAllRows(ssId, 'Bookings');
    for (var i = 0; i < rows.length; i++) {
      if (String(rows[i].member_id) === String(memberId) &&
          String(rows[i].schedule_id) === String(scheduleId) &&
          ACTIVE_STATUSES.indexOf(String(rows[i].booking_status)) !== -1) {
        return rows[i];
      }
    }
    return null;
  }

  /**
   * Buat booking dengan pencegahan overbooking (PRD 13).
   * Cek di luar lock hanyalah fast-path; keputusan final ada di dalam lock
   * agar beberapa booking bersamaan tidak melebihi kapasitas.
   */
  function create(ssId, bookingData, actorUserId) {
    Validator.required(bookingData.member_id, 'member_id');
    Validator.required(bookingData.schedule_id, 'schedule_id');
    var memberId = bookingData.member_id;
    var scheduleId = bookingData.schedule_id;

    // 2. Status keanggotaan — hanya anggota aktif yang dapat booking (PRD 10).
    var member = MemberService.findByMemberId(ssId, memberId);
    if (!member) {
      throw Error('MEMBER_NOT_FOUND');
    }
    if (String(member.membership_status) !== 'Active') {
      throw Error('PERMISSION_DENIED', 'Hanya anggota aktif yang dapat melakukan booking');
    }

    // 3. Status jadwal dan fasilitas.
    var schedule = ScheduleService.findByScheduleId(ssId, scheduleId);
    if (!schedule) {
      throw Error('SCHEDULE_NOT_FOUND');
    }
    if (String(schedule.status) !== 'Active') {
      throw Error('VALIDATION_ERROR', 'Jadwal tidak aktif');
    }
    var facility = FacilityService.findByFacilityId(ssId, schedule.facility_id);
    if (!facility) {
      throw Error('FACILITY_NOT_FOUND');
    }
    if (String(facility.status) !== 'Active') {
      throw Error('VALIDATION_ERROR', 'Fasilitas tidak dapat dibooking');
    }

    // 5. Booking duplikat (fast-path).
    if (findActiveByMemberAndSchedule(ssId, memberId, scheduleId)) {
      throw Error('DUPLICATE_BOOKING', 'Anda sudah memiliki booking aktif untuk jadwal ini');
    }

    // 6-8. Kunci proses, validasi ulang, simpan.
    var lock = LockService.getScriptLock();
    if (!lock.tryLock(10000)) {
      throw Error('RATE_LIMITED', 'Sistem sibuk. Coba lagi sesaat lagi.');
    }
    try {
      // 7. Validasi ulang di dalam lock.
      if (findActiveByMemberAndSchedule(ssId, memberId, scheduleId)) {
        throw Error('DUPLICATE_BOOKING', 'Anda sudah memiliki booking aktif untuk jadwal ini');
      }
      var capacity = Number(schedule.capacity) || 0;
      var activeCount = countActiveForSchedule(ssId, scheduleId);
      if (activeCount >= capacity) {
        throw Error('CAPACITY_FULL', 'Kapasitas jadwal sudah penuh');
      }

      var now = DateTimeHelper.nowIso();
      var booking = {
        booking_id: Uuid.v4(),
        member_id: memberId,
        schedule_id: scheduleId,
        booking_status: 'Confirmed',
        booking_time: now,
        cancelled_at: '',
        created_at: now,
        updated_at: now,
      };
      GymRepository.insertRow(ssId, 'Bookings', booking);
      GymRepository.audit(ssId, actorUserId, 'bookings.create', 'booking', booking.booking_id, 'member=' + memberId);
      DashboardService.invalidate(ssId);
      return booking;
    } finally {
      lock.releaseLock();
    }
  }

  /** Batalkan booking (soft cancel; tanpa kebijakan batas waktu — PRD 21). */
  function cancel(ssId, bookingId, actorUserId) {
    var booking = findByBookingId(ssId, bookingId);
    if (!booking) {
      throw Error('BOOKING_NOT_FOUND');
    }
    if (String(booking.booking_status) === 'Cancelled') {
      throw Error('VALIDATION_ERROR', 'Booking sudah dibatalkan sebelumnya');
    }
    var result = GymRepository.updateRow(ssId, 'Bookings', 'booking_id', bookingId, {
      booking_status: 'Cancelled',
      cancelled_at: DateTimeHelper.nowIso(),
    });
    GymRepository.audit(ssId, actorUserId, 'bookings.cancel', 'booking', bookingId, '');
    DashboardService.invalidate(ssId);
    return result;
  }

  return {
    findAll: findAll,
    findByBookingId: findByBookingId,
    countActiveForSchedule: countActiveForSchedule,
    findActiveByMemberAndSchedule: findActiveByMemberAndSchedule,
    create: create,
    cancel: cancel,
  };
})();

/**
 * attendanceService.gs
 * Pencatatan kehadiran di tab Attendance (GymBooking spreadsheet).
 * Waktu check-in memakai waktu SERVER (DateTimeHelper.nowIso), bukan
 * waktu perangkat pengguna (PRD 14).
 * Kebijakan mengikuti tab Settings gym:
 *   - attendance_device_mode: gym_camera | mobile_camera | both
 *   - attendance_booking_policy: booking_required | walk_in_allowed
 *   - manual_attendance_enabled: true | false
 */

var AttendanceService = (function () {
  function findAll(ssId) {
    return GymRepository.getAllRows(ssId, 'Attendance');
  }

  function findByAttendanceId(ssId, attendanceId) {
    return GymRepository.findOne(ssId, 'Attendance', { attendance_id: attendanceId });
  }

  /** Cek apakah booking sudah pernah di-check-in. */
  function hasCheckedIn(ssId, bookingId) {
    var rows = GymRepository.getAllRows(ssId, 'Attendance');
    for (var i = 0; i < rows.length; i++) {
      if (String(rows[i].booking_id) === String(bookingId)) {
        return true;
      }
    }
    return false;
  }

  /**
   * Check-in manual oleh staff.
   * - manual_attendance_enabled harus true (diaktifkan gym).
   * - booking_required: booking_id wajib, harus Confirmed dan milik member.
   * - walk_in_allowed: booking_id boleh kosong.
   * - Satu booking hanya bisa di-check-in sekali.
   */
  function checkIn(ssId, data, actorUserId) {
    Validator.required(data.member_id, 'member_id');

    var settings = GymSettingsService.getAll(ssId);
    if (String(settings.manual_attendance_enabled) !== 'true') {
      throw Error('PERMISSION_DENIED', 'Pencatatan kehadiran manual tidak diaktifkan oleh gym');
    }

    var member = MemberService.findByMemberId(ssId, data.member_id);
    if (!member) {
      throw Error('MEMBER_NOT_FOUND');
    }

    var policy = String(settings.attendance_booking_policy || 'booking_required');
    var bookingId = data.booking_id || '';

    if (policy === 'booking_required' && !bookingId) {
      throw Error('VALIDATION_ERROR', 'Booking diperlukan untuk check-in (kebijakan gym)');
    }

    if (bookingId) {
      var booking = BookingService.findByBookingId(ssId, bookingId);
      if (!booking) {
        throw Error('BOOKING_NOT_FOUND');
      }
      if (String(booking.member_id) !== String(data.member_id)) {
        throw Error('VALIDATION_ERROR', 'Booking bukan milik anggota ini');
      }
      if (String(booking.booking_status) !== 'Confirmed') {
        throw Error('VALIDATION_ERROR', 'Booking tidak berstatus Confirmed');
      }
      if (hasCheckedIn(ssId, bookingId)) {
        throw Error('DUPLICATE_BOOKING', 'Booking ini sudah di-check-in sebelumnya');
      }
    }

    // Waktu server, bukan waktu perangkat (PRD 14).
    var now = DateTimeHelper.nowIso();
    var attendance = {
      attendance_id: Uuid.v4(),
      member_id: data.member_id,
      booking_id: bookingId,
      check_in_at: now,
      attendance_method: data.attendance_method || 'manual',
      device_id: data.device_id || '',
      created_by: actorUserId,
      created_at: now,
    };

    GymRepository.insertRow(ssId, 'Attendance', attendance);
    GymRepository.audit(ssId, actorUserId, 'attendance.checkin', 'attendance', attendance.attendance_id, 'member=' + data.member_id);
    return attendance;
  }

  return {
    findAll: findAll,
    findByAttendanceId: findByAttendanceId,
    hasCheckedIn: hasCheckedIn,
    checkIn: checkIn,
  };
})();

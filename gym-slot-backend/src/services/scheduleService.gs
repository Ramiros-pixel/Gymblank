/**
 * scheduleService.gs
 * Manajemen jadwal di tab Schedules spreadsheet GymBooking per-gym.
 * Akses selalu via spreadsheet ID hasil TenantResolver (bukan dari Flutter).
 * Sistem mencegah jadwal bertabrakan pada fasilitas yang sama (PRD 12).
 */

var ScheduleService = (function () {
  /** Ambil semua jadwal gym. */
  function findAll(ssId) {
    return GymRepository.getAllRows(ssId, 'Schedules');
  }

  /** Cari jadwal oleh ID. */
  function findByScheduleId(ssId, scheduleId) {
    return GymRepository.findOne(ssId, 'Schedules', { schedule_id: scheduleId });
  }

  /** Cari jadwal berdasarkan fasilitas dan tanggal. */
  function findByFacilityAndDate(ssId, facilityId, scheduleDate) {
    var rows = GymRepository.getAllRows(ssId, 'Schedules');
    var result = [];
    for (var i = 0; i < rows.length; i++) {
      if (String(rows[i].facility_id) === String(facilityId) &&
          String(rows[i].schedule_date) === String(scheduleDate)) {
        result.push(rows[i]);
      }
    }
    return result;
  }

  /**
   * Cek tabrakan jadwal pada fasilitas yang sama.
   * Overlap: [start1, end1) dan [start2, end2) → start1 < end2 && end1 > start2.
   */
  function hasConflict(ssId, facilityId, scheduleDate, startTime, endTime, excludeScheduleId) {
    var existing = findByFacilityAndDate(ssId, facilityId, scheduleDate);
    for (var i = 0; i < existing.length; i++) {
      if (excludeScheduleId &&
          String(existing[i].schedule_id) === String(excludeScheduleId)) {
        continue;
      }
      if (startTime < existing[i].end_time && endTime > existing[i].start_time) {
        return true;
      }
    }
    return false;
  }

  /** Buat jadwal baru. */
  function create(ssId, scheduleData, actorUserId) {
    Validator.required(scheduleData.facility_id, 'facility_id');
    Validator.required(scheduleData.schedule_date, 'schedule_date');
    Validator.required(scheduleData.start_time, 'start_time');
    Validator.required(scheduleData.end_time, 'end_time');

    if (scheduleData.end_time <= scheduleData.start_time) {
      throw Error('VALIDATION_ERROR', 'end_time harus setelah start_time');
    }

    // Fasilitas harus ada dan aktif
    var facility = FacilityService.findByFacilityId(ssId, scheduleData.facility_id);
    if (!facility) {
      throw Error('FACILITY_NOT_FOUND');
    }
    if (facility.status !== 'Active') {
      throw Error('VALIDATION_ERROR', 'Fasilitas tidak aktif');
    }

    // Cek tabrakan jadwal
    if (hasConflict(ssId, scheduleData.facility_id, scheduleData.schedule_date,
        scheduleData.start_time, scheduleData.end_time)) {
      throw Error('SCHEDULE_CONFLICT', 'Jadwal bertabrakan dengan jadwal yang ada pada fasilitas ini');
    }

    var now = DateTimeHelper.nowIso();
    var schedule = {
      schedule_id: Uuid.v4(),
      facility_id: scheduleData.facility_id,
      schedule_date: scheduleData.schedule_date,
      start_time: scheduleData.start_time,
      end_time: scheduleData.end_time,
      capacity: scheduleData.capacity !== undefined ? Number(scheduleData.capacity) : 1,
      status: scheduleData.status || 'Active',
      created_at: now,
      updated_at: now,
    };

    GymRepository.insertRow(ssId, 'Schedules', schedule);
    GymRepository.audit(ssId, actorUserId, 'schedules.create', 'schedule', schedule.schedule_id, 'create');
    DashboardService.invalidate(ssId);
    return schedule;
  }

  /** Perbarui jadwal. */
  function update(ssId, scheduleId, updateData, actorUserId) {
    var schedule = findByScheduleId(ssId, scheduleId);
    if (!schedule) {
      throw Error('SCHEDULE_NOT_FOUND');
    }

    // Data gabungan untuk validasi tabrakan
    var facilityId = updateData.facility_id !== undefined ? updateData.facility_id : schedule.facility_id;
    var date = updateData.schedule_date !== undefined ? updateData.schedule_date : schedule.schedule_date;
    var start = updateData.start_time !== undefined ? updateData.start_time : schedule.start_time;
    var end = updateData.end_time !== undefined ? updateData.end_time : schedule.end_time;

    if (end <= start) {
      throw Error('VALIDATION_ERROR', 'end_time harus setelah start_time');
    }

    if (hasConflict(ssId, facilityId, date, start, end, scheduleId)) {
      throw Error('SCHEDULE_CONFLICT', 'Jadwal baru bertabrakan dengan jadwal yang ada');
    }

    var updates = {};
    var fields = ['facility_id', 'schedule_date', 'start_time', 'end_time', 'capacity', 'status'];
    for (var i = 0; i < fields.length; i++) {
      var f = fields[i];
      if (updateData[f] !== undefined) {
        updates[f] = f === 'capacity' ? Number(updateData[f]) : updateData[f];
      }
    }

    var result = GymRepository.updateRow(ssId, 'Schedules', 'schedule_id', scheduleId, updates);
    GymRepository.audit(ssId, actorUserId, 'schedules.update', 'schedule', scheduleId, 'update');
    DashboardService.invalidate(ssId);
    return result;
  }

  /** Nonaktifkan jadwal. */
  function deactivate(ssId, scheduleId, actorUserId) {
    return update(ssId, scheduleId, { status: 'Inactive' }, actorUserId);
  }

  return {
    findAll: findAll,
    findByScheduleId: findByScheduleId,
    findByFacilityAndDate: findByFacilityAndDate,
    hasConflict: hasConflict,
    create: create,
    update: update,
    deactivate: deactivate,
  };
})();

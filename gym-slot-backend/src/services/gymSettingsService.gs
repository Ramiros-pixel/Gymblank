/**
 * gymSettingsService.gs
 * Pengaturan gym di tab Settings (GymBooking spreadsheet).
 * Hanya key yang dikenal yang boleh diubah (PRD 14 & TD 4.10).
 */

var GymSettingsService = (function () {
  var ALLOWED_KEYS = [
    'attendance_device_mode',
    'attendance_booking_policy',
    'manual_attendance_enabled',
    'timezone',
  ];

  /** Baca semua setting sebagai map {key: value}. */
  function getAll(ssId) {
    var rows = GymRepository.getAllRows(ssId, 'Settings');
    var map = {};
    for (var i = 0; i < rows.length; i++) {
      if (rows[i].key !== undefined && rows[i].key !== '') {
        map[String(rows[i].key)] = String(rows[i].value);
      }
    }
    return map;
  }

  function get(ssId, key) {
    var map = getAll(ssId);
    return map.hasOwnProperty(key) ? map[key] : null;
  }

  /** Validasi sebelum menulis apa pun (all-or-nothing). */
  function validateKey(key) {
    if (ALLOWED_KEYS.indexOf(key) === -1) {
      throw Error('VALIDATION_ERROR', 'Setting tidak dikenal: ' + key);
    }
  }

  function validateValue(key, value) {
    var s = String(value);
    if (key === 'attendance_device_mode') {
      Validator.isIn(s, ['gym_camera', 'mobile_camera', 'both'], 'attendance_device_mode');
    } else if (key === 'attendance_booking_policy') {
      Validator.isIn(s, ['booking_required', 'walk_in_allowed'], 'attendance_booking_policy');
    } else if (key === 'manual_attendance_enabled') {
      Validator.isIn(s, ['true', 'false'], 'manual_attendance_enabled');
    } else if (key === 'timezone') {
      Validator.required(s, 'timezone');
    }
  }

  /**
   * Perbarui beberapa setting sekaligus (upsert per key).
   * @param {string} ssId - spreadsheet ID gym.
   * @param {Object} updates - {key: value}
   * @returns {Object} map setting terbaru.
   */
  function update(ssId, updates, actorUserId) {
    if (!updates || typeof updates !== 'object') {
      throw Error('VALIDATION_ERROR', 'settings wajib diisi');
    }

    // Validasi dulu supaya tidak ada penulisan parsial.
    for (var k in updates) {
      validateKey(k);
      validateValue(k, updates[k]);
    }

    var sheet = GymRepository.getSheet(ssId, 'Settings');
    var values = sheet.getDataRange().getValues();
    var headers = values.length > 0 ? values[0] : [];
    var keyIdx = headers.indexOf('key');
    var valueIdx = headers.indexOf('value');
    if (keyIdx < 0 || valueIdx < 0) {
      throw Error('SHEET_NOT_FOUND:Settings');
    }

    for (var key in updates) {
      var found = false;
      for (var r = 1; r < values.length; r++) {
        if (String(values[r][keyIdx]) === String(key)) {
          sheet.getRange(r + 1, valueIdx + 1).setValue(String(updates[key]));
          found = true;
          break;
        }
      }
      if (!found) {
        sheet.appendRow([key, String(updates[key])]);
      }
    }

    GymRepository.audit(ssId, actorUserId, 'settings.update', 'settings', '', JSON.stringify(updates));
    if (updates.timezone !== undefined) {
      DashboardService.invalidate(ssId);
    }
    return getAll(ssId);
  }

  return {
    getAll: getAll,
    get: get,
    update: update,
    ALLOWED_KEYS: ALLOWED_KEYS,
  };
})();

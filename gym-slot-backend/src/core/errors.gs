/**
 * errors.gs
 * Daftar kode error terstandar dan helper membangun objek error.
 * Kode ini menjadi kontrak antara backend dan Flutter (lihat TECHNICAL_DOCUMENTATION 11).
 */

var Errors = (function () {
  var CODES = {
      AUTH_INVALID: 'AUTH_INVALID',
      AUTH_EXPIRED: 'AUTH_EXPIRED',
      PERMISSION_DENIED: 'PERMISSION_DENIED',
      GYM_NOT_FOUND: 'GYM_NOT_FOUND',
      TENANT_ACCESS_DENIED: 'TENANT_ACCESS_DENIED',
      VALIDATION_ERROR: 'VALIDATION_ERROR',
      DUPLICATE_BOOKING: 'DUPLICATE_BOOKING',
      CAPACITY_FULL: 'CAPACITY_FULL',
      GOOGLE_DISCONNECTED: 'GOOGLE_DISCONNECTED',
      SHEET_NOT_FOUND: 'SHEET_NOT_FOUND',
      RATE_LIMITED: 'RATE_LIMITED',
      INTERNAL_ERROR: 'INTERNAL_ERROR',
      MEMBER_NOT_FOUND: 'MEMBER_NOT_FOUND',
      FACILITY_NOT_FOUND: 'FACILITY_NOT_FOUND',
      SCHEDULE_NOT_FOUND: 'SCHEDULE_NOT_FOUND',
      SCHEDULE_CONFLICT: 'SCHEDULE_CONFLICT',
      BOOKING_NOT_FOUND: 'BOOKING_NOT_FOUND',
    };

  return {
    CODES: CODES,
    /** Membangun {code, message} siap disisipkan ke Response.fail. */
    make: function (code, message) {
      return { code: code, message: message || code };
    },
  };
})();
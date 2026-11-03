/**
 * tenantResolver.gs
 * Middleware: menentukan gym aktif dan memverifikasi akses pengguna.
 * TIDAK mempercayai gym_id dari Flutter sebagai bukti akses.
 * Backend harus mencari membership pengguna pada Control Spreadsheet
 * sebelum mengakses spreadsheet gym.
 */

var TenantResolver = (function () {
  /**
   * Mengembalikan spreadsheet ID gym yang sah untuk user.
   * @param {string} userId - ID pengguna.
   * @param {string} requestedGymId - gym_id dari request (hanya konteks, bukan bukti akses).
   * @returns {string} spreadsheet ID gym.
   * @throws {Error} TENANT_ACCESS_DENIED jika user tidak punya akses.
   */
  function resolveSpreadsheetId(userId, requestedGymId) {
    if (!userId) {
      throw Error('AUTH_INVALID');
    }

    var membership = MembershipService.findByUserAndGym(userId, requestedGymId);
    if (!membership) {
      throw Error('TENANT_ACCESS_DENIED');
    }

    if (membership.status !== 'Active') {
      throw Error('PERMISSION_DENIED');
    }

    var gym = GymService.findByGymId(requestedGymId);
    if (!gym) {
      throw Error('GYM_NOT_FOUND');
    }

    if (!gym.spreadsheet_id) {
      throw Error('GOOGLE_DISCONNECTED');
    }

    return gym.spreadsheet_id;
  }

  /**
   * Mengembalikan semua gym yang dapat diakses user beserta spreadsheet ID-nya.
   * @param {string} userId - ID pengguna.
   * @returns {Array<{gymId, spreadsheetId, role, gymStatus}>}
   */
  function listAccessibleGyms(userId) {
    if (!userId) {
      throw Error('AUTH_INVALID');
    }

    var memberships = MembershipService.listByUser(userId);
    var result = [];

    for (var i = 0; i < memberships.length; i++) {
      var gym = GymService.findByGymId(memberships[i].gym_id);
      if (gym) {
        result.push({
          gymId: gym.gym_id,
          spreadsheetId: gym.spreadsheet_id || '',
          role: memberships[i].role,
          gymStatus: gym.gym_status,
        });
      }
    }

    return result;
  }

  return {
    resolveSpreadsheetId: resolveSpreadsheetId,
    listAccessibleGyms: listAccessibleGyms,
  };
})();

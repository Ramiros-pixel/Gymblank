/**
 * authorization.gs
 * Middleware: memeriksa permission pengguna berdasarkan role di membership.
 */

var Authorization = (function () {
  /**
   * Memeriksa apakah user memiliki role tertentu di gym tertentu.
   * @param {Object} body - request body.
   * @param {Array<string>} requiredRoles - role yang diizinkan.
   * @returns {Object|null} membership data jika allowed, null jika denied.
   */
  function checkPermission(body, requiredRoles) {
    var sessionData = Authentication.getSession(body);
    if (!sessionData) {
      throw Error('AUTH_EXPIRED');
    }

    var gymId = body.payload && body.payload.gym_id;
    if (!gymId) {
      throw Error('VALIDATION_ERROR', 'gym_id wajib diisi');
    }

    var membership = MembershipService.findByUserAndGym(sessionData.user_id, gymId);
    if (!membership) {
      throw Error('GYM_NOT_FOUND');
    }

    if (membership.status !== 'Active') {
      throw Error('PERMISSION_DENIED');
    }

    var allowed = false;
    for (var i = 0; i < requiredRoles.length; i++) {
      if (membership.role === requiredRoles[i]) {
        allowed = true;
        break;
      }
    }

    if (!allowed) {
      throw Error('PERMISSION_DENIED');
    }

    return membership;
  }

  /**
   * Check owner only.
   */
  function checkOwner(body) {
    var membership = checkPermission(body, ['owner']);
    return membership;
  }

  /**
   * Check admin or owner.
   */
  function checkAdminOrOwner(body) {
    var membership = checkPermission(body, ['owner', 'admin']);
    return membership;
  }

  /**
   * Check admin, owner, atau trainer.
   */
  function checkStaff(body) {
    var membership = checkPermission(body, ['owner', 'admin', 'trainer']);
    return membership;
  }

  return {
    checkPermission: checkPermission,
    checkOwner: checkOwner,
    checkAdminOrOwner: checkAdminOrOwner,
    checkStaff: checkStaff,
  };
})();

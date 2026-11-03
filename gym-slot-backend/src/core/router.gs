/**
 * router.gs
 * Router tunggal yang memetakan action ke handler.
 * Setiap request membawa { action, version, request_id, payload }.
 * Header Authorization tidak diandalkan (lihat TECHNICAL_DOCUMENTATION 5.2):
 * token dikirim dalam body JSON (payload.auth).
 */

var Router = (function () {
  /**
   * Menangani request dan mengembalikan respons standar.
   * @param {Object} body - payload JSON dari klien.
   * @returns {Object} respons standar (lihat response.gs).
   */
  function route(body) {
    var requestId = body && body.request_id ? String(body.request_id) : '';
    if (!body || typeof body !== 'object') {
      return Response.fail(requestId, Errors.CODES.VALIDATION_ERROR, 'Request tidak valid');
    }

    var action = body.action;
    if (!action || typeof action !== 'string') {
      return Response.fail(requestId, Errors.CODES.VALIDATION_ERROR, 'Action wajib diisi');
    }

    try {
      return dispatch(action, body, requestId);
    } catch (e) {
      // Jangan bocorkan detail internal ke klien.
      Logger.audit(null, action, 'request', '', e.message || '');
      return Response.fail(requestId, mapErrorCode(e), 'Terjadi kesalahan. Coba lagi.');
    }
  }

  function dispatch(action, body, requestId) {
    switch (action) {
      // Authentication
      case 'auth.google':
        return handleAuthGoogle(body, requestId);
      case 'auth.me':
        return handleAuthMe(body, requestId);
      case 'auth.logout':
        return handleAuthLogout(body, requestId);

      // Gym
      case 'gyms.create':
        return handleGymsCreate(body, requestId);
      case 'gyms.list':
        return handleGymsList(body, requestId);
      case 'gyms.detail':
        return handleGymsDetail(body, requestId);
      case 'gyms.update':
        return handleGymsUpdate(body, requestId);

      // Membership
      case 'memberships.list':
        return handleMembershipsList(body, requestId);

      default:
        return Response.fail(requestId, Errors.CODES.VALIDATION_ERROR, 'Action tidak dikenal');
    }
  }

  // ---------- Authentication Handlers ----------

  function handleAuthGoogle(body, requestId) {
    var idToken = body.auth && body.auth.id_token;
    var claims;
    try {
      claims = GoogleAuth.validateIdToken(idToken);
    } catch (e) {
      return Response.fail(requestId, Errors.CODES.AUTH_INVALID, 'Identitas tidak valid. Silakan masuk lagi.');
    }
    var result = UserService.upsertFromGoogle(claims);
    var session = Session.create(result.user.user_id);
    Logger.audit(result.user.user_id, 'auth.google', 'user', result.user.user_id, 'login');
    return Response.ok(requestId, {
      session_token: session.token,
      expires_at: session.expires_at,
      user: result.user,
      is_new: result.is_new,
    }, 'Login berhasil');
  }

  function handleAuthMe(body, requestId) {
    var sessionData = Authentication.getSession(body);
    if (!sessionData) {
      return Response.fail(requestId, Errors.CODES.AUTH_EXPIRED, 'Sesi berakhir. Silakan masuk lagi.');
    }
    var user = UserService.findByUserId(sessionData.user_id);
    if (!user) {
      return Response.fail(requestId, Errors.CODES.AUTH_INVALID, 'Pengguna tidak ditemukan.');
    }
    return Response.ok(requestId, { user: user }, 'Profil pengguna');
  }

  function handleAuthLogout(body, requestId) {
    var sessionToken = body.auth && body.auth.session_token;
    if (sessionToken) {
      Session.revoke(sessionToken);
    }
    return Response.ok(requestId, {}, 'Logout berhasil');
  }

  // ---------- Gym Handlers ----------

  function handleGymsCreate(body, requestId) {
    var membership = Authorization.checkOwner(body);
    var createData = body.payload || {};
    var result = GymService.create(createData, membership.user_id);
    Logger.audit(membership.user_id, 'gyms.create', 'gym', result.gym.gym_id, 'create');
    return Response.ok(requestId, { gym: result.gym }, 'Gym berhasil dibuat');
  }

  function handleGymsList(body, requestId) {
    var sessionData = Authentication.getSession(body);
    if (!sessionData) {
      return Response.fail(requestId, Errors.CODES.AUTH_EXPIRED, 'Sesi berakhir. Silakan masuk lagi.');
    }
    var gyms = GymService.listByUser(sessionData.user_id);
    return Response.ok(requestId, { gyms: gyms }, 'Daftar gym');
  }

  function handleGymsDetail(body, requestId) {
    var membership = Authorization.checkPermission(body, ['owner', 'admin', 'trainer', 'member']);
    var gymId = body.payload && body.payload.gym_id;
    var gym = GymService.findByGymId(gymId);
    if (!gym) {
      return Response.fail(requestId, Errors.CODES.GYM_NOT_FOUND, 'Gym tidak ditemukan');
    }
    return Response.ok(requestId, { gym: gym }, 'Detail gym');
  }

  function handleGymsUpdate(body, requestId) {
    var membership = Authorization.checkAdminOrOwner(body);
    var gymId = body.payload && body.payload.gym_id;
    var updateData = body.payload || {};
    var gym = GymService.update(gymId, updateData, membership.user_id);
    Logger.audit(membership.user_id, 'gyms.update', 'gym', gymId, 'update');
    return Response.ok(requestId, { gym: gym }, 'Gym berhasil diperbarui');
  }

  // ---------- Membership Handlers ----------

  function handleMembershipsList(body, requestId) {
    var sessionData = Authentication.getSession(body);
    if (!sessionData) {
      return Response.fail(requestId, Errors.CODES.AUTH_EXPIRED, 'Sesi berakhir. Silakan masuk lagi.');
    }
    var memberships = MembershipService.listByUser(sessionData.user_id);
    return Response.ok(requestId, { memberships: memberships }, 'Daftar membership');
  }

  /** Memetakan pesan Error ke kode error terstandard. */
  function mapErrorCode(e) {
    var msg = e && e.message ? String(e.message) : '';
    var known = [
      'AUTH_INVALID', 'AUTH_EXPIRED', 'PERMISSION_DENIED', 'GYM_NOT_FOUND',
      'TENANT_ACCESS_DENIED', 'VALIDATION_ERROR', 'DUPLICATE_BOOKING',
      'CAPACITY_FULL', 'GOOGLE_DISCONNECTED', 'SHEET_NOT_FOUND',
      'RATE_LIMITED', 'CONTROL_SPREADSHEET_NOT_CONFIGURED',
    ];
    for (var i = 0; i < known.length; i++) {
      if (msg.indexOf(known[i]) !== -1) return known[i];
    }
    return Errors.CODES.INTERNAL_ERROR;
  }

  return { route: route };
})();

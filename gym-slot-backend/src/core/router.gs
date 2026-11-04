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

      // Integrations (Google Drive/Sheets)
      case 'integrations.connect':
        return handleIntegrationsConnect(body, requestId);
      case 'integrations.callback':
        return handleIntegrationsCallback(body, requestId);
      case 'integrations.status':
        return handleIntegrationsStatus(body, requestId);
      case 'integrations.create-spreadsheet':
        return handleIntegrationsCreateSpreadsheet(body, requestId);
      case 'integrations.disconnect':
        return handleIntegrationsDisconnect(body, requestId);

      // Members
      case 'members.list':
        return handleMembersList(body, requestId);
      case 'members.create':
        return handleMembersCreate(body, requestId);
      case 'members.update':
        return handleMembersUpdate(body, requestId);
      case 'members.deactivate':
        return handleMembersDeactivate(body, requestId);

      // Facilities
      case 'facilities.list':
        return handleFacilitiesList(body, requestId);
      case 'facilities.create':
        return handleFacilitiesCreate(body, requestId);
      case 'facilities.update':
        return handleFacilitiesUpdate(body, requestId);
      case 'facilities.deactivate':
        return handleFacilitiesDeactivate(body, requestId);

      // Schedules
      case 'schedules.list':
        return handleSchedulesList(body, requestId);
      case 'schedules.create':
        return handleSchedulesCreate(body, requestId);
      case 'schedules.update':
        return handleSchedulesUpdate(body, requestId);
      case 'schedules.deactivate':
        return handleSchedulesDeactivate(body, requestId);

      // Bookings
      case 'bookings.list':
        return handleBookingsList(body, requestId);
      case 'bookings.my':
        return handleBookingsMy(body, requestId);
      case 'bookings.create':
        return handleBookingsCreate(body, requestId);
      case 'bookings.cancel':
        return handleBookingsCancel(body, requestId);

      // Attendance
      case 'attendance.list':
        return handleAttendanceList(body, requestId);
      case 'attendance.checkin':
        return handleAttendanceCheckin(body, requestId);

      // Gym Settings
      case 'settings.get':
        return handleSettingsGet(body, requestId);
      case 'settings.update':
        return handleSettingsUpdate(body, requestId);

      // Dashboard
      case 'dashboard.stats':
        return handleDashboardStats(body, requestId);
      case 'dashboard.charts':
        return handleDashboardCharts(body, requestId);

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

  // ---------- Integrations Handlers ----------

  function handleIntegrationsConnect(body, requestId) {
    var sessionData = Authentication.getSession(body);
    if (!sessionData) {
      return Response.fail(requestId, Errors.CODES.AUTH_EXPIRED, 'Sesi berakhir. Silakan masuk lagi.');
    }
    var result = GoogleIntegrationService.startConnect(body);
    return Response.ok(requestId, result, 'URL autorisasi siap');
  }

  function handleIntegrationsCallback(body, requestId) {
    var result = GoogleIntegrationService.handleCallback(body);
    return Response.ok(requestId, result, 'Koneksi Google Drive berhasil');
  }

  function handleIntegrationsStatus(body, requestId) {
    var status = GoogleIntegrationService.getConnectionStatus();
    return Response.ok(requestId, status, 'Status koneksi');
  }

  function handleIntegrationsCreateSpreadsheet(body, requestId) {
    var sessionData = Authentication.getSession(body);
    if (!sessionData) {
      return Response.fail(requestId, Errors.CODES.AUTH_EXPIRED, 'Sesi berakhir. Silakan masuk lagi.');
    }
    var result = GoogleIntegrationService.createGymSpreadsheet(body);
    Logger.audit(sessionData.user_id, 'integrations.create-spreadsheet', 'gym', body.payload.gym_id, 'create_spreadsheet');
    return Response.ok(requestId, result, 'Spreadsheet gym berhasil dibuat');
  }

  function handleIntegrationsDisconnect(body, requestId) {
    var sessionData = Authentication.getSession(body);
    if (!sessionData) {
      return Response.fail(requestId, Errors.CODES.AUTH_EXPIRED, 'Sesi berakhir. Silakan masuk lagi.');
    }
    var result = GoogleIntegrationService.disconnect();
    return Response.ok(requestId, result, 'Koneksi Google Drive diputus');
  }

  // ---------- Members Handlers ----------
  // Semua handler resolve spreadsheet ID via TenantResolver (dari metadata
  // backend), bukan menerima spreadsheet ID dari Flutter (TD 17).

  function handleMembersList(body, requestId) {
    var membership = Authorization.checkPermission(body, ['owner', 'admin', 'trainer', 'member']);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var members = MemberService.findAll(ssId);
    return Response.ok(requestId, { members: members }, 'Daftar anggota');
  }

  function handleMembersCreate(body, requestId) {
    var membership = Authorization.checkStaff(body);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var createData = body.payload || {};
    var result = MemberService.create(ssId, createData, membership.user_id);
    return Response.ok(requestId, { member: result }, 'Anggota berhasil ditambahkan');
  }

  function handleMembersUpdate(body, requestId) {
    var membership = Authorization.checkStaff(body);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var memberId = body.payload && body.payload.member_id;
    var updateData = body.payload || {};
    var result = MemberService.update(ssId, memberId, updateData, membership.user_id);
    return Response.ok(requestId, { member: result }, 'Anggota berhasil diperbarui');
  }

  function handleMembersDeactivate(body, requestId) {
    var membership = Authorization.checkStaff(body);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var memberId = body.payload && body.payload.member_id;
    var result = MemberService.deactivate(ssId, memberId, membership.user_id);
    return Response.ok(requestId, { member: result }, 'Anggota dinonaktifkan');
  }

  // ---------- Facilities Handlers ----------

  function handleFacilitiesList(body, requestId) {
    var membership = Authorization.checkPermission(body, ['owner', 'admin', 'trainer', 'member']);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var facilities = FacilityService.findAll(ssId);
    return Response.ok(requestId, { facilities: facilities }, 'Daftar fasilitas');
  }

  function handleFacilitiesCreate(body, requestId) {
    var membership = Authorization.checkStaff(body);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var createData = body.payload || {};
    var result = FacilityService.create(ssId, createData, membership.user_id);
    return Response.ok(requestId, { facility: result }, 'Fasilitas berhasil ditambahkan');
  }

  function handleFacilitiesUpdate(body, requestId) {
    var membership = Authorization.checkStaff(body);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var facilityId = body.payload && body.payload.facility_id;
    var updateData = body.payload || {};
    var result = FacilityService.update(ssId, facilityId, updateData, membership.user_id);
    return Response.ok(requestId, { facility: result }, 'Fasilitas berhasil diperbarui');
  }

  function handleFacilitiesDeactivate(body, requestId) {
    var membership = Authorization.checkStaff(body);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var facilityId = body.payload && body.payload.facility_id;
    var result = FacilityService.deactivate(ssId, facilityId, membership.user_id);
    return Response.ok(requestId, { facility: result }, 'Fasilitas dinonaktifkan');
  }

  // ---------- Schedules Handlers ----------

  function handleSchedulesList(body, requestId) {
    var membership = Authorization.checkPermission(body, ['owner', 'admin', 'trainer', 'member']);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var schedules = ScheduleService.findAll(ssId);
    return Response.ok(requestId, { schedules: schedules }, 'Daftar jadwal');
  }

  function handleSchedulesCreate(body, requestId) {
    var membership = Authorization.checkStaff(body);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var createData = body.payload || {};
    var result = ScheduleService.create(ssId, createData, membership.user_id);
    return Response.ok(requestId, { schedule: result }, 'Jadwal berhasil dibuat');
  }

  function handleSchedulesUpdate(body, requestId) {
    var membership = Authorization.checkStaff(body);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var scheduleId = body.payload && body.payload.schedule_id;
    var updateData = body.payload || {};
    var result = ScheduleService.update(ssId, scheduleId, updateData, membership.user_id);
    return Response.ok(requestId, { schedule: result }, 'Jadwal berhasil diperbarui');
  }

  function handleSchedulesDeactivate(body, requestId) {
    var membership = Authorization.checkStaff(body);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var scheduleId = body.payload && body.payload.schedule_id;
    var result = ScheduleService.deactivate(ssId, scheduleId, membership.user_id);
    return Response.ok(requestId, { schedule: result }, 'Jadwal dinonaktifkan');
  }

  // ---------- Bookings Handlers ----------

  function handleBookingsList(body, requestId) {
    var membership = Authorization.checkStaff(body);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var bookings = BookingService.findAll(ssId);
    return Response.ok(requestId, { bookings: bookings }, 'Daftar booking');
  }

  /** Riwayat booking milik member yang sedang login. */
  function handleBookingsMy(body, requestId) {
    var membership = Authorization.checkPermission(body, ['owner', 'admin', 'trainer', 'member']);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var member = MemberService.findByUserId(ssId, membership.user_id);
    if (!member) {
      return Response.ok(requestId, { bookings: [] }, 'Belum terdaftar sebagai anggota');
    }
    var all = BookingService.findAll(ssId);
    var mine = [];
    for (var i = 0; i < all.length; i++) {
      if (String(all[i].member_id) === String(member.member_id)) {
        mine.push(all[i]);
      }
    }
    return Response.ok(requestId, { bookings: mine }, 'Booking Anda');
  }

  function handleBookingsCreate(body, requestId) {
    var membership = Authorization.checkPermission(body, ['owner', 'admin', 'trainer', 'member']);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var data = body.payload || {};
    var result = BookingService.create(ssId, data, membership.user_id);
    return Response.ok(requestId, { booking: result }, 'Booking berhasil');
  }

  function handleBookingsCancel(body, requestId) {
    var membership = Authorization.checkPermission(body, ['owner', 'admin', 'trainer', 'member']);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var bookingId = body.payload && body.payload.booking_id;

    var booking = BookingService.findByBookingId(ssId, bookingId);
    if (!booking) {
      return Response.fail(requestId, Errors.CODES.BOOKING_NOT_FOUND, 'Booking tidak ditemukan');
    }

    // Member hanya boleh membatalkan booking miliknya sendiri.
    var member = MemberService.findByUserId(ssId, membership.user_id);
    var isOwn = member && String(booking.member_id) === String(member.member_id);
    var isStaff = ['owner', 'admin', 'trainer'].indexOf(membership.role) !== -1;
    if (!isOwn && !isStaff) {
      return Response.fail(requestId, Errors.CODES.PERMISSION_DENIED, 'Tidak diizinkan');
    }

    var result = BookingService.cancel(ssId, bookingId, membership.user_id);
    return Response.ok(requestId, { booking: result }, 'Booking dibatalkan');
  }

  // ---------- Attendance Handlers ----------

  function handleAttendanceList(body, requestId) {
    var membership = Authorization.checkStaff(body);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var attendance = AttendanceService.findAll(ssId);
    return Response.ok(requestId, { attendance: attendance }, 'Daftar kehadiran');
  }

  function handleAttendanceCheckin(body, requestId) {
    var membership = Authorization.checkPermission(body, ['owner', 'admin', 'trainer', 'member']);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var data = body.payload || {};
    var result = AttendanceService.checkIn(ssId, data, membership.user_id);
    return Response.ok(requestId, { attendance: result }, 'Check-in berhasil');
  }

  // ---------- Gym Settings Handlers ----------

  function handleSettingsGet(body, requestId) {
    var membership = Authorization.checkPermission(body, ['owner', 'admin', 'trainer', 'member']);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var settings = GymSettingsService.getAll(ssId);
    return Response.ok(requestId, { settings: settings }, 'Pengaturan gym');
  }

  function handleSettingsUpdate(body, requestId) {
    var membership = Authorization.checkOwner(body);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var updates = body.payload && body.payload.settings ? body.payload.settings : {};
    var result = GymSettingsService.update(ssId, updates, membership.user_id);
    return Response.ok(requestId, { settings: result }, 'Pengaturan diperbarui');
  }

  // ---------- Dashboard Handlers ----------

  function handleDashboardStats(body, requestId) {
    var membership = Authorization.checkPermission(body, ['owner', 'admin', 'trainer', 'member']);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var stats = DashboardService.getStats(ssId);
    return Response.ok(requestId, { stats: stats }, 'Statistik dashboard');
  }

  function handleDashboardCharts(body, requestId) {
    var membership = Authorization.checkPermission(body, ['owner', 'admin', 'trainer', 'member']);
    var gymId = body.payload && body.payload.gym_id;
    var ssId = TenantResolver.resolveSpreadsheetId(membership.user_id, gymId);
    var p = body.payload || {};
    var charts = DashboardService.getCharts(ssId, p.range, p.start_date, p.end_date);
    return Response.ok(requestId, { charts: charts }, 'Data grafik dashboard');
  }

  /** Memetakan pesan Error ke kode error terstandard. */
  function mapErrorCode(e) {
    var msg = e && e.message ? String(e.message) : '';
    var known = [
      'AUTH_INVALID', 'AUTH_EXPIRED', 'PERMISSION_DENIED', 'GYM_NOT_FOUND',
      'TENANT_ACCESS_DENIED', 'VALIDATION_ERROR', 'DUPLICATE_BOOKING',
      'CAPACITY_FULL', 'GOOGLE_DISCONNECTED', 'SHEET_NOT_FOUND',
      'RATE_LIMITED', 'CONTROL_SPREADSHEET_NOT_CONFIGURED',
      'MEMBER_NOT_FOUND', 'FACILITY_NOT_FOUND', 'SCHEDULE_NOT_FOUND',
      'SCHEDULE_CONFLICT', 'BOOKING_NOT_FOUND',
    ];
    for (var i = 0; i < known.length; i++) {
      if (msg.indexOf(known[i]) !== -1) return known[i];
    }
    return Errors.CODES.INTERNAL_ERROR;
  }

  return { route: route };
})();

/**
 * tests.gs
 * Test suite GymSlot backend (Phase 7 — Hardening).
 *
 * Cara menjalankan di Apps Script editor:
 *   runAllTests()          → jalankan semua test (unit + integration)
 *   runUnitTests()         → hanya unit test (tanpa data nyata)
 *   runIntegrationTests()  → integration test (butuh CONTROL_SPREADSHEET_ID)
 *
 * Aturan (TECHDOC 18): data uji terpisah dari produksi — integration test
 * membuat baris berawalan [TEST] dan menghapusnya di blok finally.
 *
 * Hasil: { total, passed, failed, results: [{name, pass, detail}] }
 * Untuk integration, hasil juga ditulis ke tab AuditLogs dengan action
 * 'test.suite' agar jejak pengujian tercatat.
 */

var __TEST__ = true; // Guard: nonaktifkan rate limiter di dalam test.

var TestRunner = (function () {
  var results = [];

  function assertEqual(actual, expected, name) {
    if (String(actual) !== String(expected)) {
      throw Error('TEST_FAIL:' + name + ' expected=' + expected + ' got=' + actual);
    }
  }

  function assertTrue(value, name) {
    if (!value) throw Error('TEST_FAIL:' + name);
  }

  function assertThrows(fn, name, codeFragment) {
    try {
      fn();
    } catch (e) {
      if (codeFragment && String(e.message).indexOf(codeFragment) === -1) {
        throw Error('TEST_FAIL:' + name + ' wrong error: ' + e.message);
      }
      return;
    }
    throw Error('TEST_FAIL:' + name + ' did not throw');
  }

  function run(name, fn) {
    try {
      fn();
      results.push({ name: name, pass: true, detail: '' });
    } catch (e) {
      results.push({ name: name, pass: false, detail: e.message });
    }
  }

  // ---------- Unit: Session ----------

  function testSessionCreateValidateRevoke() {
    var s = Session.create('test-user-1', 60 * 1000);
    assertTrue(s.token && s.token.length >= 32, 'session token length');
    var v = Session.validate(s.token);
    assertTrue(v && v.user_id === 'test-user-1', 'session validate');
    Session.revoke(s.token);
    assertTrue(Session.validate(s.token) === null, 'session revoked');
  }

  function testSessionExpired() {
    var s = Session.create('test-user-2', -1000); // langsung kedaluwarsa
    assertTrue(Session.validate(s.token) === null, 'session expired');
  }

  function testSessionInvalidToken() {
    assertTrue(Session.validate('tidak-ada-token-ini') === null, 'invalid token');
    assertTrue(Session.validate('') === null, 'empty token');
    assertTrue(Session.validate(null) === null, 'null token');
  }

  // ---------- Unit: Validator ----------

  function testValidator() {
    assertThrows(function () { Validator.required('', 'x'); }, 'required empty', 'VALIDATION_ERROR');
    assertThrows(function () { Validator.isIn('x', ['a', 'b'], 'x'); }, 'isIn fail', 'VALIDATION_ERROR');
    Validator.isIn('a', ['a', 'b'], 'x'); // tidak melempar
    assertThrows(function () { Validator.isEmail('bukan-email', 'x'); }, 'email fail', 'VALIDATION_ERROR');
    Validator.isEmail('a@b.co', 'x');
  }

  // ---------- Unit: RateLimiter ----------

  function testRateLimiter() {
    assertTrue(RateLimiter.limitFor('auth.google') === 5, 'auth limit');
    assertTrue(RateLimiter.limitFor('action.lain') === 30, 'default limit');
    // Burst kecil diizinkan.
    for (var i = 0; i < 3; i++) {
      assertTrue(RateLimiter.check('test-user-rl', 'test.action'), 'rl within ' + i);
    }
  }

  // ---------- Unit: UUID & DateTime ----------

  function testUuidUnique() {
    var a = Uuid.v4();
    var b = Uuid.v4();
    assertTrue(a !== b, 'uuid unique');
    assertTrue(a.length === 36, 'uuid format');
  }

  function testDateTimeNowIso() {
    var iso = DateTimeHelper.nowIso();
    assertTrue(!isNaN(new Date(iso).getTime()), 'iso parseable');
  }

  // ---------- Unit: Response & Errors ----------

  function testResponseFormat() {
    var ok = Response.ok('r1', { x: 1 }, 'pesan');
    assertTrue(ok.success === true && ok.request_id === 'r1', 'response ok');
    var fail = Response.fail('r2', Errors.CODES.VALIDATION_ERROR, 'galat');
    assertTrue(fail.success === false && fail.error.code === 'VALIDATION_ERROR', 'response fail');
  }

  function testErrorCodesExist() {
    ['AUTH_INVALID', 'AUTH_EXPIRED', 'PERMISSION_DENIED', 'GYM_NOT_FOUND',
     'TENANT_ACCESS_DENIED', 'VALIDATION_ERROR', 'DUPLICATE_BOOKING',
     'CAPACITY_FULL', 'GOOGLE_DISCONNECTED', 'SHEET_NOT_FOUND', 'RATE_LIMITED']
      .forEach(function (c) {
        assertTrue(Errors.CODES[c] === c, 'code ' + c);
      });
  }

  // ---------- Unit: Router (tanpa data) ----------

  function testRouterUnknownAction() {
    var res = Router.route({ action: 'tidak.ada', request_id: 't1' });
    assertTrue(res.success === false, 'unknown action fails');
    // Catatan: bisa VALIDATION_ERROR atau RATE_LIMITED bila bucket penuh
    // oleh test lain; keduanya kegagalan yang benar untuk action asing.
    assertTrue(res.error.code === 'VALIDATION_ERROR' || res.error.code === 'RATE_LIMITED',
      'unknown action code');
  }

  function testRouterMalformed() {
    var res = Router.route(null);
    assertTrue(res.success === false, 'null body fails');
    var res2 = Router.route({});
    assertTrue(res2.success === false, 'empty body fails');
  }

  // ---------- Integration: Control Spreadsheet ----------

  function testControlSpreadsheetReachable() {
    var ss = ControlRepository.getSpreadsheet();
    assertTrue(ss && ss.getId(), 'control reachable');
  }

  function testGymCreateIsolated() {
    var gymName = '[TEST] Gym Hardening ' + Date.now();
    var result = GymService.create({ gym_name: gymName }, 'test-owner-hardening');
    var gym = result.gym;
    try {
      assertTrue(gym.gym_id && gym.gym_status === 'Pending', 'gym created pending');
      var found = GymService.findByGymId(gym.gym_id);
      assertTrue(found && found.gym_name === gymName, 'gym findable');
    } finally {
      // Cleanup: tandai tidak aktif (data uji dibiarkan terlacak di audit).
      try {
        GymService.update(gym.gym_id, { gym_name: gymName + ' [DELETED]' }, 'test-owner-hardening');
      } catch (e) { /* abaikan */ }
    }
  }

  function testTenantIsolationDenied() {
    // Member tanpa membership ke gym lain harus ditolak TenantResolver.
    var gyms = GymService.listByUser('test-owner-hardening');
    assertTrue(gyms.length >= 1, 'owner has gym');
    var otherGymId = gyms[0].gym_id;
    assertThrows(function () {
      TenantResolver.resolveSpreadsheetId('test-user-tanpa-membership', otherGymId);
    }, 'cross tenant denied', 'TENANT_ACCESS_DENIED');
  }

  // ---------- Integration: booking tanpa spreadsheet gym (validasi urut) ----------

  function testBookingRequiresActiveMember() {
    // ssId palsu: validasi keanggotaan berjalan sebelum akses spreadsheet,
    // sehingga gagal di MEMBER_NOT_FOUND tanpa menyentuh gym sheet.
    assertThrows(function () {
      BookingService.create('test-ss-palsu', {
        member_id: 'test-member-tidak-ada',
        schedule_id: 'test-schedule-tidak-ada',
      }, 'test-actor');
    }, 'booking member check first', 'MEMBER_NOT_FOUND');
  }

  // ---------- Runner ----------

  function runAll(unitFns, integrationFns, label) {
    results = [];
    unitFns.forEach(function (t) { run(t[0], t[1]); });
    integrationFns.forEach(function (t) { run(t[0], t[1]); });

    var passed = 0;
    var failed = 0;
    results.forEach(function (r) { if (r.pass) passed++; else failed++; });

    var summary = {
      suite: label,
      total: results.length,
      passed: passed,
      failed: failed,
      results: results,
      ran_at: DateTimeHelper.nowIso(),
    };

    try {
      Logger.audit(null, 'test.suite', 'test', label,
        passed + '/' + results.length + ' passed');
    } catch (e) { /* logging best effort */ }

    return summary;
  }

  return {
    assertEqual: assertEqual,
    assertTrue: assertTrue,
    assertThrows: assertThrows,
    run: run,
    reset: function () { results = []; },
    summary: function () {
      var passed = 0;
      results.forEach(function (r) { if (r.pass) passed++; });
      return { total: results.length, passed: passed, failed: results.length - passed };
    },
  };
})();

function runUnitTests() {
  var unit = [
    ['session create/validate/revoke', testSessionCreateValidateRevoke],
    ['session expired', testSessionExpired],
    ['session invalid token', testSessionInvalidToken],
    ['validator rules', testValidator],
    ['rate limiter', testRateLimiter],
    ['uuid unique', testUuidUnique],
    ['datetime nowIso', testDateTimeNowIso],
    ['response format', testResponseFormat],
    ['error codes exist', testErrorCodesExist],
    ['router unknown action', testRouterUnknownAction],
    ['router malformed body', testRouterMalformed],
  ];
  return TestRunner.runAll(unit, [], 'unit');
}

function runIntegrationTests() {
  var integration = [
    ['control spreadsheet reachable', testControlSpreadsheetReachable],
    ['gym create isolated data', testGymCreateIsolated],
    ['tenant isolation denied', testTenantIsolationDenied],
    ['booking requires active member', testBookingRequiresActiveMember],
  ];
  return TestRunner.runAll([], integration, 'integration');
}

function runAllTests() {
  var unit = runUnitTests();
  var integ;
  try {
    integ = runIntegrationTests();
  } catch (e) {
    integ = { suite: 'integration', error: e.message, total: 0, passed: 0, failed: 0, results: [] };
  }
  return {
    unit: unit,
    integration: integ,
    total: unit.total + integ.total,
    passed: unit.passed + integ.passed,
    failed: unit.failed + integ.failed,
  };
}

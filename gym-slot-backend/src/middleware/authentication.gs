/**
 * authentication.gs
 * Middleware: validasi session aplikasi GymSlot dari request.
 * session_token dibawa dalam body.auth (bukan header).
 */

var Authentication = (function () {
  /**
   * Mengambil session valid dari request.
   * @param {Object} body - payload JSON.
   * @returns {Object|null} {user_id, expires_at} atau null.
   */
  function getSession(body) {
    if (!body || !body.auth || !body.auth.session_token) return null;
    return Session.validate(body.auth.session_token);
  }

  return { getSession: getSession };
})();
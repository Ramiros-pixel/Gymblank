/**
 * doPost.gs
 * Entry point POST. Semua action API masuk lewat sini.
 * Token dikirim dalam body JSON (bukan header), sesuai keterbatasan Apps Script.
 */

function doPost(e) {
  var body;
  try {
    body = JSON.parse(e.postData.contents);
  } catch (parseErr) {
    return content(Response.fail('', Errors.CODES.VALIDATION_ERROR, 'Body harus JSON'));
  }
  return content(Router.route(body));
}

/** Membungkus hasil sebagai JSON untuk Web App. */
function content(payload) {
  return ContentService.createTextOutput(JSON.stringify(payload))
    .setMimeType(ContentService.MimeType.JSON);
}
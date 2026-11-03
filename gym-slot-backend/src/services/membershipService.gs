/**
 * membershipService.gs
 * Manajemen membership: hubungan user dengan gym dan role.
 */

var MembershipService = (function () {
  /**
   * Mencari membership oleh user_id dan gym_id.
   */
  function findByUserAndGym(userId, gymId) {
    var rows = ControlRepository.getAllRows('Memberships');
    for (var i = 0; i < rows.length; i++) {
      if (String(rows[i].user_id) === String(userId) &&
          String(rows[i].gym_id) === String(gymId)) {
        return rows[i];
      }
    }
    return null;
  }

  /**
   * Daftar semua membership untuk user tertentu.
   */
  function listByUser(userId) {
    var rows = ControlRepository.getAllRows('Memberships');
    var result = [];
    for (var i = 0; i < rows.length; i++) {
      if (String(rows[i].user_id) === String(userId)) {
        result.push(rows[i]);
      }
    }
    return result;
  }

  /**
   * Menambahkan membership baru.
   */
  function create(membershipData) {
    if (!membershipData.user_id || !membershipData.gym_id || !membershipData.role) {
      throw Error('VALIDATION_ERROR', 'user_id, gym_id, dan role wajib diisi');
    }

    // Cek duplikat
    var existing = findByUserAndGym(membershipData.user_id, membershipData.gym_id);
    if (existing) {
      throw Error('VALIDATION_ERROR', 'User sudah menjadi member gym ini');
    }

    var now = DateTimeHelper.nowIso();
    var membership = {
      membership_id: Uuid.v4(),
      user_id: membershipData.user_id,
      gym_id: membershipData.gym_id,
      role: membershipData.role,
      status: 'Active',
      joined_at: now,
    };

    ControlRepository.insertRow('Memberships', membership);
    return membership;
  }

  /**
   * Memperbarui role membership.
   */
  function updateRole(membershipId, newRole) {
    var validRoles = Constants.ROLES;
    var isValid = false;
    for (var i = 0; i < validRoles.length; i++) {
      if (validRoles[i] === newRole) {
        isValid = true;
        break;
      }
    }
    if (!isValid) {
      throw Error('VALIDATION_ERROR', 'Role tidak valid');
    }

    var sheet = ControlRepository.getSheet('Memberships');
    var headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
    var data = sheet.getDataRange().getValues();

    for (var i = 1; i < data.length; i++) {
      var idIdx = headers.indexOf('membership_id');
      if (idIdx >= 0 && String(data[i][idIdx]) === String(membershipId)) {
        var roleIdx = headers.indexOf('role');
        if (roleIdx >= 0) {
          sheet.getRange(i + 1, roleIdx + 1).setValue(newRole);
        }
        var updatedAtIdx = headers.indexOf('updated_at');
        if (updatedAtIdx >= 0) {
          sheet.getRange(i + 1, updatedAtIdx + 1).setValue(DateTimeHelper.nowIso());
        }
        return { membership_id: membershipId, role: newRole };
      }
    }

    throw Error('VALIDATION_ERROR', 'Membership tidak ditemukan');
  }

  return {
    findByUserAndGym: findByUserAndGym,
    listByUser: listByUser,
    create: create,
    updateRole: updateRole,
  };
})();

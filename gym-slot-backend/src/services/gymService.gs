/**
 * gymService.gs
 * Manajemen gym: create, list, detail.
 */

var GymService = (function () {
  /**
   * Membuat gym baru.
   * Owner diberikan role 'owner' secara otomatis.
   */
  function create(createData, ownerId) {
    if (!createData.gym_name) {
      throw Error('VALIDATION_ERROR', 'Nama gym wajib diisi');
    }

    var gymId = Uuid.v4();
    var now = DateTimeHelper.nowIso();

    var gym = {
      gym_id: gymId,
      gym_name: createData.gym_name,
      address: createData.address || '',
      phone: createData.phone || '',
      contact_email: createData.contact_email || '',
      timezone: createData.timezone || 'Asia/Jakarta',
      spreadsheet_id: '', // akan diisi setelah OAuth
      owner_user_id: ownerId,
      gym_status: 'Pending',
      created_at: now,
      updated_at: now,
    };

    ControlRepository.insertRow('Gyms', gym);

    // Buat membership owner
    var membership = MembershipService.create({
      user_id: ownerId,
      gym_id: gymId,
      role: 'owner',
    });

    return { gym: gym, membership: membership };
  }

  /**
   * Daftar gym milik user.
   */
  function listByUser(userId) {
    var memberships = MembershipService.listByUser(userId);
    var gyms = [];

    for (var i = 0; i < memberships.length; i++) {
      var gym = findByGymId(memberships[i].gym_id);
      if (gym) {
        gyms.push({
          gym_id: gym.gym_id,
          gym_name: gym.gym_name,
          address: gym.address,
          phone: gym.phone,
          contact_email: gym.contact_email,
          timezone: gym.timezone,
          spreadsheet_id: gym.spreadsheet_id,
          owner_user_id: gym.owner_user_id,
          gym_status: gym.gym_status,
          created_at: gym.created_at,
          updated_at: gym.updated_at,
          role: memberships[i].role,
          membership_status: memberships[i].status,
        });
      }
    }

    return gyms;
  }

  /**
   * Detail gym oleh ID.
   */
  function findByGymId(gymId) {
    var gym = ControlRepository.findOne('Gyms', { gym_id: gymId });
    return gym;
  }

  /**
   * Update informasi gym.
   */
  function update(gymId, updateData, actorUserId) {
    var gym = findByGymId(gymId);
    if (!gym) {
      throw Error('GYM_NOT_FOUND');
    }

    var sheet = ControlRepository.getSheet('Gyms');
    var headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];

    var fields = ['gym_name', 'address', 'phone', 'contact_email', 'timezone'];
    for (var i = 0; i < fields.length; i++) {
      var field = fields[i];
      if (updateData[field] !== undefined) {
        var colIdx = headers.indexOf(field);
        if (colIdx >= 0) {
          // Cari baris gym
          var data = sheet.getDataRange().getValues();
          for (var j = 1; j < data.length; j++) {
            var idIdx = headers.indexOf('gym_id');
            if (idIdx >= 0 && String(data[j][idIdx]) === String(gymId)) {
              sheet.getRange(j + 1, colIdx + 1).setValue(updateData[field]);
              break;
            }
          }
        }
      }
    }

    // Update updated_at
    var updatedAtIdx = headers.indexOf('updated_at');
    if (updatedAtIdx >= 0) {
      var data = sheet.getDataRange().getValues();
      for (var k = 1; k < data.length; k++) {
        var idIdx = headers.indexOf('gym_id');
        if (idIdx >= 0 && String(data[k][idIdx]) === String(gymId)) {
          sheet.getRange(k + 1, updatedAtIdx + 1).setValue(DateTimeHelper.nowIso());
          break;
        }
      }
    }

    return findByGymId(gymId);
  }

  return {
    create: create,
    listByUser: listByUser,
    findByGymId: findByGymId,
    update: update,
  };
})();

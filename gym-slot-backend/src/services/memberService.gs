/**
 * memberService.gs
 * Manajemen anggota gym di tab Members spreadsheet GymBooking per-gym.
 * Akses selalu via spreadsheet ID hasil TenantResolver (bukan dari Flutter).
 * Hanya anggota aktif yang dapat melakukan booking (PRD 10).
 */

var MemberService = (function () {
  /** Ambil semua anggota gym. */
  function findAll(ssId) {
    var rows = GymRepository.getAllRows(ssId, 'Members');
    return rows;
  }

  /** Cari anggota oleh ID. */
  function findByMemberId(ssId, memberId) {
    return GymRepository.findOne(ssId, 'Members', { member_id: memberId });
  }

  /** Cari anggota oleh user_id. */
  function findByUserId(ssId, userId) {
    return GymRepository.findOne(ssId, 'Members', { user_id: userId });
  }

  /** Buat anggota baru. */
  function create(ssId, memberData, actorUserId) {
    Validator.required(memberData.user_id, 'user_id');
    Validator.required(memberData.full_name, 'full_name');

    // Cek duplikat per gym
    var existing = findByUserId(ssId, memberData.user_id);
    if (existing) {
      throw Error('VALIDATION_ERROR', 'User sudah terdaftar sebagai anggota gym ini');
    }

    var now = DateTimeHelper.nowIso();
    var member = {
      member_id: Uuid.v4(),
      user_id: memberData.user_id,
      full_name: memberData.full_name,
      email: memberData.email || '',
      phone: memberData.phone || '',
      join_date: memberData.join_date || now,
      membership_status: memberData.membership_status || 'Active',
      created_at: now,
      updated_at: now,
    };

    GymRepository.insertRow(ssId, 'Members', member);
    GymRepository.audit(ssId, actorUserId, 'members.create', 'member', member.member_id, 'create');
    DashboardService.invalidate(ssId);
    return member;
  }

  /** Perbarui data anggota. */
  function update(ssId, memberId, updateData, actorUserId) {
    var member = findByMemberId(ssId, memberId);
    if (!member) {
      throw Error('MEMBER_NOT_FOUND');
    }

    var updates = {};
    var fields = ['full_name', 'email', 'phone', 'membership_status'];
    for (var i = 0; i < fields.length; i++) {
      var f = fields[i];
      if (updateData[f] !== undefined) {
        updates[f] = updateData[f];
      }
    }

    var result = GymRepository.updateRow(ssId, 'Members', 'member_id', memberId, updates);
    GymRepository.audit(ssId, actorUserId, 'members.update', 'member', memberId, 'update');
    DashboardService.invalidate(ssId);
    return result;
  }

  /** Nonaktifkan anggota (soft delete). */
  function deactivate(ssId, memberId, actorUserId) {
    return update(ssId, memberId, { membership_status: 'Inactive' }, actorUserId);
  }

  return {
    findAll: findAll,
    findByMemberId: findByMemberId,
    findByUserId: findByUserId,
    create: create,
    update: update,
    deactivate: deactivate,
  };
})();

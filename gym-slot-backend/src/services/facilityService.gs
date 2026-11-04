/**
 * facilityService.gs
 * Manajemen fasilitas gym di tab Facilities spreadsheet GymBooking per-gym.
 * Akses selalu via spreadsheet ID hasil TenantResolver (bukan dari Flutter).
 * Fasilitas maintenance tidak dapat dipilih untuk booking baru (PRD 11).
 */

var FacilityService = (function () {
  /** Ambil semua fasilitas gym. */
  function findAll(ssId) {
    return GymRepository.getAllRows(ssId, 'Facilities');
  }

  /** Cari fasilitas oleh ID. */
  function findByFacilityId(ssId, facilityId) {
    return GymRepository.findOne(ssId, 'Facilities', { facility_id: facilityId });
  }

  /** Buat fasilitas baru. */
  function create(ssId, facilityData, actorUserId) {
    Validator.required(facilityData.facility_name, 'facility_name');

    var now = DateTimeHelper.nowIso();
    var facility = {
      facility_id: Uuid.v4(),
      facility_name: facilityData.facility_name,
      description: facilityData.description || '',
      capacity: facilityData.capacity !== undefined ? Number(facilityData.capacity) : 1,
      status: facilityData.status || 'Active',
      created_at: now,
      updated_at: now,
    };

    GymRepository.insertRow(ssId, 'Facilities', facility);
    GymRepository.audit(ssId, actorUserId, 'facilities.create', 'facility', facility.facility_id, 'create');
    return facility;
  }

  /** Perbarui fasilitas. */
  function update(ssId, facilityId, updateData, actorUserId) {
    var facility = findByFacilityId(ssId, facilityId);
    if (!facility) {
      throw Error('FACILITY_NOT_FOUND');
    }

    var updates = {};
    var fields = ['facility_name', 'description', 'capacity', 'status'];
    for (var i = 0; i < fields.length; i++) {
      var f = fields[i];
      if (updateData[f] !== undefined) {
        updates[f] = f === 'capacity' ? Number(updateData[f]) : updateData[f];
      }
    }

    var result = GymRepository.updateRow(ssId, 'Facilities', 'facility_id', facilityId, updates);
    GymRepository.audit(ssId, actorUserId, 'facilities.update', 'facility', facilityId, 'update');
    return result;
  }

  /** Nonaktifkan fasilitas (soft delete via status). */
  function deactivate(ssId, facilityId, actorUserId) {
    return update(ssId, facilityId, { status: 'Inactive' }, actorUserId);
  }

  return {
    findAll: findAll,
    findByFacilityId: findByFacilityId,
    create: create,
    update: update,
    deactivate: deactivate,
  };
})();

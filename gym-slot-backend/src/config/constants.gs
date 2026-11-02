/**
 * constants.gs
 * Nilai konstan platform GymSlot. Tidak ada secret di sini.
 * Konfigurasi yang bisa berubah antar environment dipisah di settings.gs.
 */

var Constants = (function () {
  var API_VERSION = 'v1';

  // Control Spreadsheet.
  var CONTROL_SPREADSHEET_NAME = 'GymSlot_Control';
  var CONTROL_TABS = [
    'Users',
    'Gyms',
    'Memberships',
    'Invitations',
    'Integrations',
    'PlatformSettings',
    'AuditLogs',
  ];

  // Spreadsheet per gym.
  var GYM_SPREADSHEET_NAME = 'GymBooking';
  var GYM_TABS = [
    'Dashboard',
    'Gym',
    'Users',
    'Members',
    'Facilities',
    'Schedules',
    'Bookings',
    'Attendance',
    'Settings',
    'AuditLogs',
  ];

  // Kolom header tiap tab Control. Header menentukan urutan kolom.
  var CONTROL_HEADERS = {
    Users: ['user_id', 'google_sub', 'email', 'full_name', 'photo_url', 'account_status', 'created_at', 'updated_at'],
    Gyms: ['gym_id', 'gym_name', 'address', 'phone', 'contact_email', 'timezone', 'spreadsheet_id', 'owner_user_id', 'gym_status', 'created_at', 'updated_at'],
    Memberships: ['membership_id', 'user_id', 'gym_id', 'role', 'status', 'joined_at'],
    Invitations: ['invitation_id', 'gym_id', 'email', 'assigned_role', 'invitation_token_hash', 'status', 'expires_at', 'created_by', 'created_at'],
    Integrations: ['integration_id', 'gym_id', 'provider', 'status', 'token_ref_expires_at', 'connected_at', 'last_error'],
    PlatformSettings: ['key', 'value'],
    AuditLogs: ['log_id', 'actor_user_id', 'action', 'resource_type', 'resource_id', 'detail', 'created_at'],
  };

  // Kolom header tiap tab gym.
  var GYM_HEADERS = {
    Gym: ['gym_id', 'gym_name', 'address', 'phone', 'contact_email', 'timezone', 'created_at', 'updated_at'],
    Users: ['user_id', 'google_sub', 'email', 'full_name', 'role', 'status', 'joined_at'],
    Members: ['member_id', 'user_id', 'full_name', 'email', 'phone', 'join_date', 'membership_status', 'created_at', 'updated_at'],
    Facilities: ['facility_id', 'gym_id', 'facility_name', 'description', 'capacity', 'status', 'created_at', 'updated_at'],
    Schedules: ['schedule_id', 'facility_id', 'schedule_date', 'start_time', 'end_time', 'capacity', 'status', 'created_at', 'updated_at'],
    Bookings: ['booking_id', 'member_id', 'schedule_id', 'booking_status', 'booking_time', 'cancelled_at', 'created_at', 'updated_at'],
    Attendance: ['attendance_id', 'member_id', 'booking_id', 'check_in_at', 'attendance_method', 'device_id', 'created_by', 'created_at'],
    Settings: ['key', 'value'],
    AuditLogs: ['log_id', 'actor_user_id', 'action', 'resource_type', 'resource_id', 'detail', 'created_at'],
  };

  // Role dan status valid.
  var ROLES = ['owner', 'admin', 'trainer', 'member'];
  var GYM_STATUS = ['Pending', 'Active', 'Suspended', 'Disconnected', 'SetupFailed'];
  var ACCOUNT_STATUS = ['Active', 'Disabled'];

  // Durasi session aplikasi (ms).
  var SESSION_TTL_MS = 7 * 24 * 60 * 60 * 1000; // 7 hari.

  return {
    API_VERSION: API_VERSION,
    CONTROL_SPREADSHEET_NAME: CONTROL_SPREADSHEET_NAME,
    CONTROL_TABS: CONTROL_TABS,
    GYM_SPREADSHEET_NAME: GYM_SPREADSHEET_NAME,
    GYM_TABS: GYM_TABS,
    CONTROL_HEADERS: CONTROL_HEADERS,
    GYM_HEADERS: GYM_HEADERS,
    ROLES: ROLES,
    GYM_STATUS: GYM_STATUS,
    ACCOUNT_STATUS: ACCOUNT_STATUS,
    SESSION_TTL_MS: SESSION_TTL_MS,
  };
})();
import 'package:flutter/material.dart';
import 'package:gym_slot/core/theme/app_colors.dart';
import 'package:gym_slot/models/booking.dart';
import 'package:gym_slot/models/facility.dart';
import 'package:gym_slot/models/gym.dart';
import 'package:gym_slot/models/member.dart';
import 'package:gym_slot/models/schedule.dart';
import 'package:gym_slot/providers/booking_provider.dart';
import 'package:gym_slot/providers/management_provider.dart';
import 'package:gym_slot/shared/widgets/status_chip.dart';
import 'package:provider/provider.dart';

/// Layar detail gym dengan tab Anggota / Fasilitas / Jadwal (Phase 3) dan
/// Booking / Kehadiran / Pengaturan (Phase 4).
class GymDetailScreen extends StatefulWidget {
  final Gym gym;

  const GymDetailScreen({super.key, required this.gym});

  @override
  State<GymDetailScreen> createState() => _GymDetailScreenState();
}

class _GymDetailScreenState extends State<GymDetailScreen> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    // Muat data setelah frame pertama selesai.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload();
    });
  }

  void _reload() {
    final mgmt = context.read<ManagementProvider>();
    final booking = context.read<BookingProvider>();
    mgmt.loadMembers(widget.gym.gymId);
    mgmt.loadFacilities(widget.gym.gymId);
    mgmt.loadSchedules(widget.gym.gymId);
    booking.loadBookings(widget.gym.gymId);
    booking.loadAttendance(widget.gym.gymId);
    booking.loadSettings(widget.gym.gymId);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ['Anggota', 'Fasilitas', 'Jadwal', 'Booking', 'Kehadiran', 'Pengaturan'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gym.gymName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: Column(
        children: [
          // Segmented control sederhana (dua baris agar muat 6 tab)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < tabs.length; i++)
                  ChoiceChip(
                    label: Text(tabs[i]),
                    selected: _tabIndex == i,
                    onSelected: (_) => setState(() => _tabIndex = i),
                  ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: [
                _MembersTab(gym: widget.gym),
                _FacilitiesTab(gym: widget.gym),
                _SchedulesTab(gym: widget.gym),
                _BookingsTab(gym: widget.gym),
                _AttendanceTab(gym: widget.gym),
                _SettingsTab(gym: widget.gym),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Members Tab ----------

class _MembersTab extends StatelessWidget {
  final Gym gym;

  const _MembersTab({required this.gym});

  @override
  Widget build(BuildContext context) {
    final mgmt = context.watch<ManagementProvider>();

    if (mgmt.members.isEmpty) {
      return _EmptyState(
        icon: Icons.people,
        message: 'Belum ada anggota',
        actionLabel: 'Tambah Anggota',
        onAction: () => _showMemberDialog(context),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          itemCount: mgmt.members.length,
          itemBuilder: (context, i) {
            final m = mgmt.members[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(m.fullName.isNotEmpty ? m.fullName[0] : '?'),
                ),
                title: Text(m.fullName),
                subtitle: Text(m.email ?? '-'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatusChip(label: m.membershipStatus ?? '-'),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _showMemberDialog(context, member: m),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        _FloatingAddButton(
          onPressed: () => _showMemberDialog(context),
        ),
      ],
    );
  }

  void _showMemberDialog(BuildContext context, {Member? member}) {
    final nameCtrl = TextEditingController(text: member?.fullName ?? '');
    final emailCtrl = TextEditingController(text: member?.email ?? '');
    final phoneCtrl = TextEditingController(text: member?.phone ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(member == null ? 'Tambah Anggota' : 'Edit Anggota'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Telepon'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final mgmt = context.read<ManagementProvider>();
              Navigator.pop(ctx);
              if (member == null) {
                await mgmt.createMember(
                  gymId: gym.gymId,
                  userId: '',
                  fullName: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                );
              } else {
                await mgmt.updateMember(
                  memberId: member.memberId,
                  fullName: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

// ---------- Facilities Tab ----------

class _FacilitiesTab extends StatelessWidget {
  final Gym gym;

  const _FacilitiesTab({required this.gym});

  @override
  Widget build(BuildContext context) {
    final mgmt = context.watch<ManagementProvider>();

    if (mgmt.facilities.isEmpty) {
      return _EmptyState(
        icon: Icons.fitness_center,
        message: 'Belum ada fasilitas',
        actionLabel: 'Tambah Fasilitas',
        onAction: () => _showFacilityDialog(context),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          itemCount: mgmt.facilities.length,
          itemBuilder: (context, i) {
            final f = mgmt.facilities[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.fitness_center)),
                title: Text(f.facilityName),
                subtitle: Text('Kapasitas: ${f.capacity}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatusChip(label: f.status ?? '-'),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () =>
                          _showFacilityDialog(context, facility: f),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        _FloatingAddButton(
          onPressed: () => _showFacilityDialog(context),
        ),
      ],
    );
  }

  void _showFacilityDialog(BuildContext context, {Facility? facility}) {
    final nameCtrl = TextEditingController(text: facility?.facilityName ?? '');
    final descCtrl = TextEditingController(text: facility?.description ?? '');
    final capCtrl = TextEditingController(
      text: facility != null ? facility.capacity.toString() : '1',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(facility == null ? 'Tambah Fasilitas' : 'Edit Fasilitas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Fasilitas'),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Deskripsi'),
            ),
            TextField(
              controller: capCtrl,
              decoration: const InputDecoration(labelText: 'Kapasitas'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final mgmt = context.read<ManagementProvider>();
              Navigator.pop(ctx);
              final capacity = int.tryParse(capCtrl.text.trim()) ?? 1;
              if (facility == null) {
                await mgmt.createFacility(
                  gymId: gym.gymId,
                  facilityName: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  capacity: capacity,
                );
              } else {
                await mgmt.updateFacility(
                  facilityId: facility.facilityId,
                  facilityName: nameCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                  capacity: capacity,
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

// ---------- Schedules Tab ----------

class _SchedulesTab extends StatelessWidget {
  final Gym gym;

  const _SchedulesTab({required this.gym});

  @override
  Widget build(BuildContext context) {
    final mgmt = context.watch<ManagementProvider>();

    if (mgmt.schedules.isEmpty) {
      return _EmptyState(
        icon: Icons.calendar_today,
        message: 'Belum ada jadwal',
        actionLabel: 'Tambah Jadwal',
        onAction: () => _showScheduleDialog(context),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
          itemCount: mgmt.schedules.length,
          itemBuilder: (context, i) {
            final s = mgmt.schedules[i];
            final facilityName = mgmt.facilities
                .where((f) => f.facilityId == s.facilityId)
                .map((f) => f.facilityName)
                .firstOrNull;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.event)),
                title: Text('${s.startTime} - ${s.endTime}'),
                subtitle: Text(
                  '${facilityName ?? s.facilityId} · ${s.scheduleDate}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatusChip(label: s.status ?? '-'),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () =>
                          _showScheduleDialog(context, schedule: s),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        _FloatingAddButton(
          onPressed: () => _showScheduleDialog(context),
        ),
      ],
    );
  }

  void _showScheduleDialog(BuildContext context, {Schedule? schedule}) {
    final mgmt = context.read<ManagementProvider>();
    final facilities = mgmt.facilities;

    String? facilityId =
        schedule?.facilityId ?? (facilities.isNotEmpty ? facilities.first.facilityId : null);
    final dateCtrl = TextEditingController(text: schedule?.scheduleDate ?? '');
    final startCtrl = TextEditingController(text: schedule?.startTime ?? '08:00');
    final endCtrl = TextEditingController(text: schedule?.endTime ?? '09:00');
    final capCtrl = TextEditingController(
      text: schedule != null ? schedule.capacity.toString() : '1',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(schedule == null ? 'Tambah Jadwal' : 'Edit Jadwal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: facilityId,
                  decoration: const InputDecoration(labelText: 'Fasilitas'),
                  items: facilities
                      .map((f) => DropdownMenuItem(
                            value: f.facilityId,
                            child: Text(f.facilityName),
                          ))
                      .toList(),
                  onChanged: (v) => setDialogState(() => facilityId = v),
                ),
                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal (YYYY-MM-DD)',
                  ),
                ),
                TextField(
                  controller: startCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mulai (HH:MM)',
                  ),
                ),
                TextField(
                  controller: endCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Selesai (HH:MM)',
                  ),
                ),
                TextField(
                  controller: capCtrl,
                  decoration: const InputDecoration(labelText: 'Kapasitas'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final capacity = int.tryParse(capCtrl.text.trim()) ?? 1;
                if (schedule == null) {
                  await mgmt.createSchedule(
                    gymId: gym.gymId,
                    facilityId: facilityId ?? '',
                    scheduleDate: dateCtrl.text.trim(),
                    startTime: startCtrl.text.trim(),
                    endTime: endCtrl.text.trim(),
                    capacity: capacity,
                  );
                } else {
                  await mgmt.updateSchedule(
                    scheduleId: schedule.scheduleId,
                    scheduleDate: dateCtrl.text.trim(),
                    startTime: startCtrl.text.trim(),
                    endTime: endCtrl.text.trim(),
                    capacity: capacity,
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Bookings Tab (Phase 4) ----------

class _BookingsTab extends StatelessWidget {
  final Gym gym;

  const _BookingsTab({required this.gym});

  @override
  Widget build(BuildContext context) {
    final mgmt = context.watch<ManagementProvider>();
    final booking = context.watch<BookingProvider>();

    return Stack(
      children: [
        Column(
          children: [
            if (booking.lastError != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.redTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  booking.lastError!,
                  style: const TextStyle(
                      color: AppColors.red, fontSize: 13),
                ),
              ),
            Expanded(
              child: booking.bookings.isEmpty
                  ? const Center(
                      child: Text('Belum ada booking',
                          style: TextStyle(color: AppColors.gray500)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      itemCount: booking.bookings.length,
                      itemBuilder: (context, i) {
                        final b = booking.bookings[i];
                        final memberName = mgmt.members
                            .where((m) => m.memberId == b.memberId)
                            .map((m) => m.fullName)
                            .firstOrNull;
                        final schedule = mgmt.schedules
                            .where((s) => s.scheduleId == b.scheduleId)
                            .firstOrNull;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                                child: Icon(Icons.event_available)),
                            title: Text(memberName ?? b.memberId),
                            subtitle: Text(schedule != null
                                ? '${schedule.scheduleDate} ${schedule.startTime}-${schedule.endTime}'
                                : b.scheduleId),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _BookingStatusChip(status: b.bookingStatus),
                                if (b.isActive)
                                  IconButton(
                                    icon: const Icon(Icons.cancel,
                                        size: 20,
                                        color: AppColors.red),
                                    tooltip: 'Batalkan',
                                    onPressed: () => _confirmCancel(
                                        context, gym.gymId, b),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        _FloatingAddButton(
          onPressed: () => _showBookingDialog(context),
        ),
      ],
    );
  }

  void _confirmCancel(BuildContext context, String gymId, Booking b) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan booking?'),
        content: const Text('Status booking akan menjadi Cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<BookingProvider>().cancelBooking(
                    gymId: gymId,
                    bookingId: b.bookingId,
                  );
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.red),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(BuildContext context) {
    final mgmt = context.read<ManagementProvider>();
    final members = mgmt.members;
    final schedules = mgmt.schedules;

    if (members.isEmpty || schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Butuh minimal 1 anggota dan 1 jadwal untuk membuat booking.'),
      ));
      return;
    }

    String? memberId = members.first.memberId;
    String? scheduleId = schedules.first.scheduleId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Booking Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: memberId,
                decoration: const InputDecoration(labelText: 'Anggota'),
                items: members
                    .map((m) => DropdownMenuItem(
                        value: m.memberId, child: Text(m.fullName)))
                    .toList(),
                onChanged: (v) => setDialogState(() => memberId = v),
              ),
              DropdownButtonFormField<String>(
                initialValue: scheduleId,
                decoration: const InputDecoration(labelText: 'Jadwal'),
                items: schedules
                    .map((s) => DropdownMenuItem(
                        value: s.scheduleId,
                        child: Text(
                            '${s.scheduleDate} ${s.startTime}-${s.endTime}')))
                    .toList(),
                onChanged: (v) => setDialogState(() => scheduleId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await context.read<BookingProvider>().createBooking(
                      gymId: gym.gymId,
                      memberId: memberId ?? '',
                      scheduleId: scheduleId ?? '',
                    );
              },
              child: const Text('Booking'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Attendance Tab (Phase 4) ----------

class _AttendanceTab extends StatelessWidget {
  final Gym gym;

  const _AttendanceTab({required this.gym});

  @override
  Widget build(BuildContext context) {
    final mgmt = context.watch<ManagementProvider>();
    final booking = context.watch<BookingProvider>();

    return Stack(
      children: [
        Column(
          children: [
            if (booking.lastError != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.redTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  booking.lastError!,
                  style: const TextStyle(
                      color: AppColors.red, fontSize: 13),
                ),
              ),
            Expanded(
              child: booking.attendance.isEmpty
                  ? const Center(
                      child: Text('Belum ada catatan kehadiran',
                          style: TextStyle(color: AppColors.gray500)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      itemCount: booking.attendance.length,
                      itemBuilder: (context, i) {
                        final a = booking.attendance[i];
                        final memberName = mgmt.members
                            .where((m) => m.memberId == a.memberId)
                            .map((m) => m.fullName)
                            .firstOrNull;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                                child: Icon(Icons.login)),
                            title: Text(memberName ?? a.memberId),
                            subtitle: Text(
                                'Check-in: ${a.checkInAt ?? '-'}\nMetode: ${a.attendanceMethod ?? '-'}'),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        _FloatingAddButton(
          onPressed: () => _showCheckinDialog(context),
        ),
      ],
    );
  }

  void _showCheckinDialog(BuildContext context) {
    final mgmt = context.read<ManagementProvider>();
    final booking = context.read<BookingProvider>();
    final members = mgmt.members;

    if (members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Butuh minimal 1 anggota untuk check-in.'),
      ));
      return;
    }

    String? memberId = members.first.memberId;
    String? bookingId; // opsional (walk-in jika policy mengizinkan)

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Check-in Manual'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: memberId,
                  decoration: const InputDecoration(labelText: 'Anggota'),
                  items: members
                      .map((m) => DropdownMenuItem(
                          value: m.memberId, child: Text(m.fullName)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => memberId = v),
                ),
                DropdownButtonFormField<String>(
                  initialValue: bookingId,
                  decoration: const InputDecoration(
                    labelText: 'Booking (opsional / walk-in)',
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                        value: null, child: Text('- tanpa booking -')),
                    ...booking.bookings
                        .where((b) => b.isActive)
                        .map((b) => DropdownMenuItem(
                              value: b.bookingId,
                              child: Text(b.bookingId.substring(0, 8)),
                            )),
                  ],
                  onChanged: (v) => setDialogState(() => bookingId = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await context.read<BookingProvider>().checkIn(
                      gymId: gym.gymId,
                      memberId: memberId ?? '',
                      bookingId: bookingId,
                    );
              },
              child: const Text('Check-in'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Settings Tab (Phase 4) ----------

class _SettingsTab extends StatefulWidget {
  final Gym gym;

  const _SettingsTab({required this.gym});

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingProvider>();
    final s = booking.settings;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (booking.lastError != null)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.redTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(booking.lastError!,
                style: const TextStyle(
                    color: AppColors.red, fontSize: 13)),
          ),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('Mode Perangkat Kehadiran'),
                subtitle: const Text(
                    'gym_camera / mobile_camera / both'),
                trailing: DropdownButton<String>(
                  value: (s['attendance_device_mode'] ?? 'both') ==
                          'gym_camera'
                      ? 'gym_camera'
                      : (s['attendance_device_mode'] == 'mobile_camera'
                          ? 'mobile_camera'
                          : 'both'),
                  items: const [
                    DropdownMenuItem(
                        value: 'gym_camera', child: Text('gym_camera')),
                    DropdownMenuItem(
                        value: 'mobile_camera',
                        child: Text('mobile_camera')),
                    DropdownMenuItem(value: 'both', child: Text('both')),
                  ],
                  onChanged: _saving
                      ? null
                      : (v) => _save(context,
                          {'attendance_device_mode': v ?? 'both'}),
                ),
              ),
              ListTile(
                title: const Text('Kebijakan Booking Kehadiran'),
                subtitle: const Text(
                    'booking_required / walk_in_allowed'),
                trailing: DropdownButton<String>(
                  value: (s['attendance_booking_policy'] ??
                          'booking_required') ==
                      'walk_in_allowed'
                      ? 'walk_in_allowed'
                      : 'booking_required',
                  items: const [
                    DropdownMenuItem(
                        value: 'booking_required',
                        child: Text('booking_required')),
                    DropdownMenuItem(
                        value: 'walk_in_allowed',
                        child: Text('walk_in_allowed')),
                  ],
                  onChanged: _saving
                      ? null
                      : (v) => _save(context,
                          {'attendance_booking_policy': v ?? 'booking_required'}),
                ),
              ),
              SwitchListTile(
                title: const Text('Kehadiran Manual'),
                subtitle: const Text(
                    'Izinkan staff mencatat kehadiran manual'),
                value: s['manual_attendance_enabled'] == 'true',
                onChanged: _saving
                    ? null
                    : (v) => _save(context,
                        {'manual_attendance_enabled': v.toString()}),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Hanya Owner yang dapat mengubah pengaturan.',
          style: const TextStyle(
              color: AppColors.gray500, fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _save(BuildContext context, Map<String, String> updates) async {
    setState(() => _saving = true);
    final ok = await context
        .read<BookingProvider>()
        .updateSettings(gymId: widget.gym.gymId, updates: updates);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(
      content: Text(ok ? 'Pengaturan disimpan' : 'Gagal menyimpan'),
    ));
  }
}

// ---------- Shared Widgets ----------

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.gray500),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.gray500)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _FloatingAddButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _FloatingAddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    // FAB merah (desain.md 8.8): FAB merah untuk tambah.
    return Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppColors.red,
        foregroundColor: AppColors.white,
        tooltip: 'Tambah',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    // Chip status terpusat (desain.md 3.4): bentuk + ikon + label.
    return StatusChip(
      label: label,
      style: StatusChip.styleFor(label),
    );
  }
}

class _BookingStatusChip extends StatelessWidget {
  final String? status;

  const _BookingStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    // Chip status booking terpusat (desain.md 3.4).
    return StatusChip(
      label: status ?? '-',
      style: StatusChip.styleFor(status),
    );
  }
}

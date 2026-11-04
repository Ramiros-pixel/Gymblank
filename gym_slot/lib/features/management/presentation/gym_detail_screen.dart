import 'package:flutter/material.dart';
import 'package:gym_slot/models/facility.dart';
import 'package:gym_slot/models/gym.dart';
import 'package:gym_slot/models/member.dart';
import 'package:gym_slot/models/schedule.dart';
import 'package:gym_slot/providers/management_provider.dart';
import 'package:provider/provider.dart';

/// Layar detail gym dengan tab Anggota / Fasilitas / Jadwal (Phase 3).
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
    mgmt.loadMembers(widget.gym.gymId);
    mgmt.loadFacilities(widget.gym.gymId);
    mgmt.loadSchedules(widget.gym.gymId);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ['Anggota', 'Fasilitas', 'Jadwal'];

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
          // Segmented control sederhana
          Padding(
            padding: const EdgeInsets.all(8),
            child: SegmentedButton<int>(
              segments: [
                for (var i = 0; i < tabs.length; i++)
                  ButtonSegment(value: i, label: Text(tabs[i])),
              ],
              selected: {_tabIndex},
              onSelectionChanged: (selection) {
                setState(() => _tabIndex = selection.first);
              },
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              children: [
                _MembersTab(gym: widget.gym),
                _FacilitiesTab(gym: widget.gym),
                _SchedulesTab(gym: widget.gym),
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
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey)),
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
    return Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton(
        onPressed: onPressed,
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
    final isActive = label == 'Active' || label == 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
        ),
      ),
    );
  }
}

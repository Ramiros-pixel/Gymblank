import 'package:flutter/material.dart';
import 'package:gym_slot/core/theme/app_colors.dart';
import 'package:gym_slot/core/theme/app_spacing.dart';
import 'package:gym_slot/features/dashboard/presentation/dashboard_stats_screen.dart';
import 'package:gym_slot/features/management/presentation/gym_detail_screen.dart';
import 'package:gym_slot/models/gym.dart';
import 'package:gym_slot/providers/auth_provider.dart';
import 'package:gym_slot/providers/gym_provider.dart';
import 'package:gym_slot/shared/widgets/app_card.dart';
import 'package:gym_slot/shared/widgets/app_states.dart';
import 'package:gym_slot/shared/widgets/status_chip.dart';
import 'package:provider/provider.dart';

/// Home setelah login (desain.md 7 & 8.1).
/// - Belum punya gym → dua kartu pilihan (8.3).
/// - Punya gym → pilih gym → navigasi 4 tab per role (7.1/7.2).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gyms = context.watch<GymProvider>().gyms;
    final user = context.watch<AuthProvider>().user;

    if (gyms.isEmpty) {
      return const _NoGymScreen();
    }

    // MVP: pakai gym pertama. Pemilih gym menyusul (desain.md 7).
    final gym = gyms.first;
    final role = gym.role ?? 'member';

    switch (role) {
      case 'owner':
      case 'admin':
        return _StaffNav(gym: gym, userName: user?.fullName ?? '');
      case 'trainer':
        return _TrainerNav(gym: gym);
      default:
        return _MemberNav(gym: gym, userName: user?.fullName ?? '');
    }
  }
}

// ---------- Belum punya gym (desain.md 8.3) ----------

class _NoGymScreen extends StatelessWidget {
  const _NoGymScreen();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MULAI',
          style: TextStyle(
            fontFamily: 'BarlowCondensed',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          Text(
            'Halo, ${user?.fullName ?? ''}.',
            style: const TextStyle(
              fontFamily: 'BarlowCondensed',
              fontSize: 28,
              height: 32 / 28,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
          Text(
            'Mau mulai dari mana?',
            style: TextStyle(fontSize: 14, color: AppColors.gray500),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ChoiceCard(
            icon: Icons.add_business,
            title: 'Buat gym baru',
            subtitle: 'Untuk pemilik gym',
            onTap: () {
              Navigator.of(context).pushNamed('/register-gym');
            },
          ),
          const SizedBox(height: AppSpacing.md),
          const _ChoiceCard(
            icon: Icons.mark_email_unread,
            title: 'Punya undangan',
            subtitle: 'Gabung ke gym yang ada',
          ),
          const SizedBox(height: AppSpacing.xl),
          // Profil + keluar tetap bisa diakses.
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Keluar'),
            onTap: () async {
              await context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 28, color: AppColors.red),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                      fontSize: 14, color: AppColors.gray500),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.gray500),
        ],
      ),
    );
  }
}

// ---------- Navigasi Owner/Admin (desain.md 7.2) ----------

class _StaffNav extends StatelessWidget {
  final Gym gym;
  final String userName;

  const _StaffNav({required this.gym, required this.userName});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('Dashboard', Icons.dashboard_outlined),
      ('Jadwal', Icons.calendar_today_outlined),
      ('Anggota', Icons.people_outline),
      ('Lainnya', Icons.grid_view_outlined),
    ];

    return _RoleNavShell(
      gym: gym,
      tabs: tabs,
      builders: [
        (_) => DashboardStatsScreen(gym: gym),
        (_) => _TabPlaceholder(title: 'Jadwal', gym: gym),
        (_) => _TabPlaceholder(title: 'Anggota', gym: gym),
        (_) => _MoreScreen(gym: gym, userName: userName),
      ],
    );
  }
}

// ---------- Navigasi Member (desain.md 7.1) ----------

class _MemberNav extends StatelessWidget {
  final Gym gym;
  final String userName;

  const _MemberNav({required this.gym, required this.userName});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('Beranda', Icons.home_outlined),
      ('Jadwal', Icons.calendar_today_outlined),
      ('Booking', Icons.event_available_outlined),
      ('Profil', Icons.person_outline),
    ];

    return _RoleNavShell(
      gym: gym,
      tabs: tabs,
      builders: [
        (_) => _TabPlaceholder(title: 'Beranda', gym: gym),
        (_) => _TabPlaceholder(title: 'Jadwal', gym: gym),
        (_) => _TabPlaceholder(title: 'Booking', gym: gym),
        (_) => _ProfileScreen(gym: gym, userName: userName),
      ],
    );
  }
}

// ---------- Navigasi Trainer: 2 tab read-only (desain.md 7.3) ----------

class _TrainerNav extends StatelessWidget {
  final Gym gym;

  const _TrainerNav({required this.gym});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('Jadwal', Icons.calendar_today_outlined),
      ('Profil', Icons.person_outline),
    ];

    return _RoleNavShell(
      gym: gym,
      tabs: tabs,
      builders: [
        (_) => _TabPlaceholder(title: 'Jadwal (baca saja)', gym: gym),
        (_) => _ProfileScreen(gym: gym, userName: ''),
      ],
    );
  }
}

/// Shell navigasi bawah bersama: ikon + label selalu terlihat,
/// tab aktif hitam (desain.md 6.5).
class _RoleNavShell extends StatefulWidget {
  final Gym gym;
  final List<(String, IconData)> tabs;
  final List<Widget Function(Gym gym)> builders;

  const _RoleNavShell({
    required this.gym,
    required this.tabs,
    required this.builders,
  });

  @override
  State<_RoleNavShell> createState() => _RoleNavShellState();
}

class _RoleNavShellState extends State<_RoleNavShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [for (var i = 0; i < widget.tabs.length; i++) widget.builders[i](widget.gym)],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final (label, icon) in widget.tabs)
            NavigationDestination(icon: Icon(icon), label: label),
        ],
      ),
    );
  }
}

// ---------- Layar Lainnya (desain.md 7.2) ----------

class _MoreScreen extends StatelessWidget {
  final Gym gym;
  final String userName;

  const _MoreScreen({required this.gym, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'LAINNYA',
          style: TextStyle(
            fontFamily: 'BarlowCondensed',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          if (gym.gymStatus != null && gym.gymStatus != 'Active') ...[
            GymBanner(status: gym.gymStatus!),
            const SizedBox(height: AppSpacing.md),
          ],
          _MoreItem(
            icon: Icons.fitness_center_outlined,
            label: 'Fasilitas',
            onTap: () => _openDetail(context, 1),
          ),
          _MoreItem(
            icon: Icons.calendar_month_outlined,
            label: 'Jadwal',
            onTap: () => _openDetail(context, 2),
          ),
          _MoreItem(
            icon: Icons.event_available_outlined,
            label: 'Booking',
            onTap: () => _openDetail(context, 3),
          ),
          _MoreItem(
            icon: Icons.login_outlined,
            label: 'Kehadiran',
            onTap: () => _openDetail(context, 4),
          ),
          _MoreItem(
            icon: Icons.settings_outlined,
            label: 'Pengaturan Gym',
            onTap: () => _openDetail(context, 5),
          ),
          _MoreItem(
            icon: Icons.cloud_sync_outlined,
            label: 'Koneksi Google',
            onTap: () => _openDetail(context, 5),
          ),
          _MoreItem(
            icon: Icons.person_outline,
            label: 'Profil',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      _ProfileScreen(gym: gym, userName: userName),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, int initialTab) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GymDetailScreen(gym: gym),
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        leading: Icon(icon, color: AppColors.black),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        trailing:
            const Icon(Icons.chevron_right, color: AppColors.gray500),
        onTap: onTap,
      ),
    );
  }
}

// ---------- Layar Profil (desain.md 7.1/7.2) ----------

class _ProfileScreen extends StatelessWidget {
  final Gym gym;
  final String userName;

  const _ProfileScreen({required this.gym, required this.userName});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PROFIL',
          style: TextStyle(
            fontFamily: 'BarlowCondensed',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? userName,
                  style: const TextStyle(
                    fontFamily: 'BarlowCondensed',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.gray500),
                ),
                const SizedBox(height: AppSpacing.sm),
                StatusChip(
                  label: gym.role ?? 'member',
                  style: StatusChipStyle.active,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Keluar'),
            onTap: () async {
              await context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
    );
  }
}

/// Placeholder tab yang belum punya layar khusus di fase ini.
class _TabPlaceholder extends StatelessWidget {
  final String title;
  final Gym gym;

  const _TabPlaceholder({required this.title, required this.gym});

  @override
  Widget build(BuildContext context) {
    // Tab Jadwal/Booking untuk staff membuka GymDetailScreen berisi data nyata.
    if (title == 'Jadwal') {
      return GymDetailScreen(gym: gym);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontFamily: 'BarlowCondensed',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: EmptyState(
        icon: Icons.construction,
        title: 'Segera hadir',
        message: 'Layar ini sedang disiapkan.',
      ),
    );
  }
}


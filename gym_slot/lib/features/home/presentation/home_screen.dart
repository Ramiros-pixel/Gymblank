import 'package:flutter/material.dart';
import 'package:gym_slot/features/dashboard/presentation/dashboard_stats_screen.dart';
import 'package:gym_slot/features/management/presentation/gym_detail_screen.dart';
import 'package:gym_slot/providers/auth_provider.dart';
import 'package:gym_slot/providers/gym_provider.dart';
import 'package:provider/provider.dart';

/// Entry point aplikasi setelah authentication.
/// Menampilkan Bottom Navigation setelah login berhasil.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const _HomeBody(),
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    final navState = context.watch<_BottomNavState>();
    final currentIndex = navState.currentIndex;

    final screens = [
      const DashboardScreen(),
      const MembersScreen(),
      const SchedulesScreen(),
      const ProfileScreen(),
    ];

    return IndexedStack(
      index: currentIndex,
      children: screens,
    );
  }
}

class _BottomNav extends StatefulWidget {
  const _BottomNav();

  @override
  State<_BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<_BottomNav> {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void navigateTo(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: navigateTo,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.people), label: 'Anggota'),
        NavigationDestination(icon: Icon(Icons.calendar_today), label: 'Jadwal'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }
}

// ---------- Screens ----------

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gyms = context.watch<GymProvider>().gyms;
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<GymProvider>().loadGyms();
            },
          ),
        ],
      ),
      body: gyms.isEmpty
          ? const _EmptyGymState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Halo, ${user?.fullName ?? "User"}!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pilih gym untuk mulai:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ...gyms.map((gym) => _GymCard(gym: gym)),
                const SizedBox(height: 16),
                // Akses cepat dashboard statistik gym pertama (PRD 15).
                if (gyms.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                DashboardStatsScreen(gym: gyms.first),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bar_chart),
                      label: const Text('Lihat Statistik Gym'),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _GymCard extends StatelessWidget {
  final dynamic gym;

  const _GymCard({required this.gym});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.fitness_center)),
        title: Text(gym.gymName),
        subtitle: Text(gym.gymStatus ?? 'Pending'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GymDetailScreen(gym: gym),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyGymState extends StatelessWidget {
  const _EmptyGymState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Belum ada gym',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Anda belum bergabung dengan gym manapun.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/register-gym');
              },
              icon: const Icon(Icons.add),
              label: const Text('Daftar Gym Baru'),
            ),
          ),
        ],
      ),
    );
  }
}

class MembersScreen extends StatelessWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anggota')),
      body: const Center(child: Text('Daftar Anggota')),
    );
  }
}

class SchedulesScreen extends StatelessWidget {
  const SchedulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jadwal')),
      body: const Center(child: Text('Daftar Jadwal')),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user?.photoUrl != null)
            CircleAvatar(
              backgroundImage: NetworkImage(user!.photoUrl!),
              radius: 40,
            ),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? '',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            user?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Keluar'),
            onTap: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
    );
  }
}

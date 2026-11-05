import 'package:flutter/material.dart';
import 'package:gym_slot/core/theme/app_colors.dart';
import 'package:gym_slot/models/gym.dart';
import 'package:gym_slot/providers/dashboard_provider.dart';
import 'package:gym_slot/shared/widgets/app_card.dart';
import 'package:gym_slot/shared/widgets/app_states.dart';
import 'package:gym_slot/shared/widgets/status_chip.dart';
import 'package:provider/provider.dart';

/// Dashboard statistik & grafik gym (Phase 5, PRD 8.1 & 15).
/// Data aktual dari backend; tanpa data dummy.
/// Grafik digambar dengan CustomPaint (tanpa dependency chart eksternal).
class DashboardStatsScreen extends StatefulWidget {
  final Gym gym;

  const DashboardStatsScreen({super.key, required this.gym});

  @override
  State<DashboardStatsScreen> createState() => _DashboardStatsScreenState();
}

class _DashboardStatsScreenState extends State<DashboardStatsScreen> {
  String _range = '7d';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  void _load() {
    context.read<DashboardProvider>().load(
          gymId: widget.gym.gymId,
          range: _range,
        );
  }

  Future<void> _refresh() async {
    await context.read<DashboardProvider>().load(
          gymId: widget.gym.gymId,
          range: _range,
        );
  }

  void _pickCustomRange() async {
    final now = DateTime.now();
    final initial = DateTimeRange(
      start: now.subtract(const Duration(days: 7)),
      end: now,
    );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: initial,
    );
    if (picked == null || !mounted) return;
    setState(() => _range = 'custom');
    await context.read<DashboardProvider>().load(
          gymId: widget.gym.gymId,
          range: 'custom',
          startDate: _fmtDate(picked.start),
          endDate: _fmtDate(picked.end),
        );
  }

  static String _fmtDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();

    // App bar hitam untuk halaman dashboard (desain.md 6.5 & 9).
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        title: Text(
          'DASHBOARD',
          style: const TextStyle(
            fontFamily: 'BarlowCondensed',
            fontSize: 22,
            height: 26 / 22,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: dash.isLoading ? null : _refresh,
          ),
        ],
      ),
      body: _buildBody(dash),
      // Filter rentang waktu di bottom bar agar tidak memenuhi appbar.
      bottomNavigationBar: _buildRangeFilter(dash),
    );
  }

  Widget _buildBody(DashboardProvider dash) {
    // Skeleton mengikuti bentuk konten (desain.md 10: skeleton, bukan
    // spinner layar penuh).
    if (dash.isLoading && dash.stats == null) {
      return const _DashboardSkeleton();
    }

    if (dash.hasError && dash.stats == null && dash.charts == null) {
      return ErrorState(
        message: 'Gagal memuat dashboard.',
        onRetry: _refresh,
      );
    }

    final stats = dash.stats;
    final charts = dash.charts;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner status gym non-aktif (desain.md 3.4 & 9).
          if (widget.gym.gymStatus != null &&
              widget.gym.gymStatus != 'Active') ...[
            GymBanner(
              status: widget.gym.gymStatus!,
              onRetry: _refresh,
            ),
            const SizedBox(height: 12),
          ],
          // Waktu pembaruan terakhir (PRD 15).
          if (stats != null && stats.generatedAt.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Diperbarui: ${stats.generatedAt.substring(0, 19).replaceAll("T", " ")} UTC',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.gray500),
              ),
            ),

          if (stats == null)
            const Center(child: Text('Belum ada data statistik'))
          else ...[
            // --- Kartu statistik (PRD 15). ---
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _StatCard(
                  icon: Icons.people,
                  label: 'Total Anggota',
                  value: stats.totalMembers,
                ),
                _StatCard(
                  icon: Icons.verified_user,
                  label: 'Anggota Aktif',
                  value: stats.activeMembers,
                ),
                _StatCard(
                  icon: Icons.event_available,
                  label: 'Booking Hari Ini',
                  value: stats.bookingsToday,
                ),
                _StatCard(
                  icon: Icons.upcoming,
                  label: 'Booking Mendatang',
                  value: stats.upcomingBookings,
                ),
                _StatCard(
                  icon: Icons.login,
                  label: 'Kehadiran Hari Ini',
                  value: stats.attendanceToday,
                ),
                _StatCard(
                  icon: Icons.event_busy,
                  label: 'Booking Dibatalkan',
                  value: stats.cancelledBookings,
                ),
              ],
            ),
          ],

          if (charts == null) ...[
            const SizedBox(height: 24),
            const Center(child: Text('Belum ada data grafik')),
          ] else ...[
            const SizedBox(height: 16),

            // --- Tren booking (PRD 8.1): hitam, titik tertinggi merah. ---
            _ChartCard(
              title: 'Tren Booking',
              subtitle: _rangeLabel(charts),
              child: _BarChart(
                data: charts.bookingTrend
                    .map((p) => _BarPoint(p.date.substring(5), p.count))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),

            // --- Tren kehadiran. ---
            _ChartCard(
              title: 'Tren Kehadiran',
              subtitle: _rangeLabel(charts),
              child: _BarChart(
                data: charts.attendanceTrend
                    .map((p) => _BarPoint(p.date.substring(5), p.count))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),

            // --- Status booking. ---
            _ChartCard(
              title: 'Status Booking',
              subtitle: _rangeLabel(charts),
              child: _StatusBreakdown(statusCounts: charts.bookingStatus),
            ),
            const SizedBox(height: 12),

            // --- Fasilitas populer: hitam dengan nomor peringkat. ---
            _ChartCard(
              title: 'Fasilitas Populer',
              subtitle: _rangeLabel(charts),
              child: charts.popularFacilities.isEmpty
                  ? const _EmptyChartHint()
                  : _RankedBars(
                      items: charts.popularFacilities
                          .map((e) => MapEntry(
                              e['facility'] as String? ?? '-',
                              (e['count'] as num?)?.toInt() ?? 0))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 12),

            // --- Jam ramai: bar tertinggi merah (desain.md 9). ---
            _ChartCard(
              title: 'Jam Ramai',
              subtitle: _rangeLabel(charts),
              child: charts.busyHours.isEmpty
                  ? const _EmptyChartHint()
                  : _BarChart(
                      data: charts.busyHours
                          .map((e) => _BarPoint(
                              (e['hour'] as String? ?? '-').substring(0, 2),
                              (e['count'] as num?)?.toInt() ?? 0))
                          .toList(),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  String _rangeLabel(DashboardCharts charts) {
    if (charts.range == 'custom') {
      return '${charts.startDate} s/d ${charts.endDate}';
    }
    switch (charts.range) {
      case 'today':
        return 'Hari ini';
      case '30d':
        return '30 hari terakhir';
      default:
        return '7 hari terakhir';
    }
  }

  Widget _buildRangeFilter(DashboardProvider dash) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8,
          alignment: WrapAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Hari ini'),
              selected: _range == 'today',
              onSelected: (_) {
                setState(() => _range = 'today');
                _load();
              },
            ),
            ChoiceChip(
              label: const Text('7 hari'),
              selected: _range == '7d',
              onSelected: (_) {
                setState(() => _range = '7d');
                _load();
              },
            ),
            ChoiceChip(
              label: const Text('30 hari'),
              selected: _range == '30d',
              onSelected: (_) {
                setState(() => _range = '30d');
                _load();
              },
            ),
            ChoiceChip(
              label: const Text('Kustom'),
              selected: _range == 'custom',
              onSelected: (_) => _pickCustomRange(),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Kartu Statistik ----------

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    // Angka display Barlow Condensed, label kecil, ikon kanan atas
    // (desain.md 6.2 kartu statistik).
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: AppColors.gray500),
            ],
          ),
          const Spacer(),
          Text(
            '$value',
            style: const TextStyle(
              fontFamily: 'BarlowCondensed',
              fontSize: 34,
              height: 38 / 34,
              fontWeight: FontWeight.bold,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Kartu Grafik ----------

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Judul section Barlow Condensed SemiBold (desain.md 4 title-md).
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'BarlowCondensed',
              fontSize: 18,
              height: 22 / 18,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.gray500),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 130, width: double.infinity, child: child),
        ],
      ),
    );
  }
}

// ---------- Grafik Bar Custom (CustomPaint) ----------

class _BarPoint {
  final String label;
  final int value;

  const _BarPoint(this.label, this.value);
}

class _BarChart extends StatelessWidget {
  final List<_BarPoint> data;

  const _BarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.every((p) => p.value == 0)) {
      return const _EmptyChartHint();
    }

    final maxValue =
        data.map((p) => p.value).reduce((a, b) => a > b ? a : b);

    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _BarChartPainter(
              data: data,
              maxValue: maxValue,
            ),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 4),
        // Label X (maks 8 label agar tidak tumpang tindih).
        SizedBox(
          height: 14,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < data.length; i++)
                if (data.length <= 8 ||
                    i % (data.length / 8).ceil() == 0)
                  Text(
                    data[i].label,
                    style: const TextStyle(
                        fontSize: 8, color: AppColors.gray500),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Grafik batang hitam dengan SATU sorotan merah (nilai tertinggi)
/// sesuai desain.md 9: "warna dasar hitam/abu, satu seri sorotan merah".
class _BarChartPainter extends CustomPainter {
  final List<_BarPoint> data;
  final int maxValue;

  _BarChartPainter({
    required this.data,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxValue <= 0) return;

    final barGap = 2.0;
    final barWidth = (size.width / data.length) - barGap;

    final blackPaint = Paint()..color = AppColors.black;
    final redPaint = Paint()..color = AppColors.red;

    for (var i = 0; i < data.length; i++) {
      final h = data[i].value / maxValue * (size.height - 8);
      final x = i * (barWidth + barGap);
      final rect = Rect.fromLTWH(
        x,
        size.height - h,
        barWidth < 2 ? 2 : barWidth,
        h,
      );
      // Nilai tertinggi = merah; sisanya hitam.
      final paint = data[i].value == maxValue ? redPaint : blackPaint;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

/// Bar horizontal berperingkat: hitam di atas track abu (desain.md 9).
class _RankedBars extends StatelessWidget {
  final List<MapEntry<String, int>> items;

  const _RankedBars({required this.items});

  @override
  Widget build(BuildContext context) {
    final maxV = items.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) {
        final e = items[i];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: [
              // Nomor peringkat.
              SizedBox(
                width: 18,
                child: Text(
                  '${i + 1}.',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray700,
                  ),
                ),
              ),
              SizedBox(
                width: 84,
                child: Text(
                  e.key,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.gray200, // gray-200 track
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: e.value / maxV,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.black, // isi hitam
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text('${e.value}',
                  style: const TextStyle(fontSize: 11)),
            ],
          ),
        );
      },
    );
  }
}

/// Rincian status booking: chip sesuai desain.md 3.4 (bukan warna bebas).
class _StatusBreakdown extends StatelessWidget {
  final Map<String, int> statusCounts;

  const _StatusBreakdown({required this.statusCounts});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in statusCounts.entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusChip(
                label: entry.key,
                style: StatusChip.styleFor(entry.key),
              ),
              const SizedBox(width: 4),
              Text(
                '${entry.value}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _EmptyChartHint extends StatelessWidget {
  const _EmptyChartHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Belum ada data',
        style: TextStyle(fontSize: 12, color: AppColors.gray500),
      ),
    );
  }
}

/// Skeleton dashboard mengikuti bentuk konten (desain.md 10):
/// 6 kotak kartu statistik + 2 blok grafik.
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SkeletonBox(height: 14, width: 160),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: const [
            SkeletonBox(height: 80),
            SkeletonBox(height: 80),
            SkeletonBox(height: 80),
            SkeletonBox(height: 80),
            SkeletonBox(height: 80),
            SkeletonBox(height: 80),
          ],
        ),
        const SizedBox(height: 16),
        const SkeletonBox(height: 160, radius: BorderRadius.all(Radius.circular(16))),
        const SizedBox(height: 12),
        const SkeletonBox(height: 160, radius: BorderRadius.all(Radius.circular(16))),
      ],
    );
  }
}

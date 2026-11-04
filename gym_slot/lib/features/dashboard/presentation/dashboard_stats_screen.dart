import 'package:flutter/material.dart';
import 'package:gym_slot/models/gym.dart';
import 'package:gym_slot/providers/dashboard_provider.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard ${widget.gym.gymName}'),
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
    if (dash.isLoading && dash.stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (dash.hasError && dash.stats == null && dash.charts == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            const Text('Gagal memuat dashboard'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _refresh, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }

    final stats = dash.stats;
    final charts = dash.charts;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Waktu pembaruan terakhir (PRD 15).
          if (stats != null && stats.generatedAt.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Diperbarui: ${stats.generatedAt.substring(0, 19).replaceAll("T", " ")} UTC',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
                  color: Colors.blue,
                ),
                _StatCard(
                  icon: Icons.verified_user,
                  label: 'Anggota Aktif',
                  value: stats.activeMembers,
                  color: Colors.green,
                ),
                _StatCard(
                  icon: Icons.event_available,
                  label: 'Booking Hari Ini',
                  value: stats.bookingsToday,
                  color: Colors.orange,
                ),
                _StatCard(
                  icon: Icons.upcoming,
                  label: 'Booking Mendatang',
                  value: stats.upcomingBookings,
                  color: Colors.teal,
                ),
                _StatCard(
                  icon: Icons.login,
                  label: 'Kehadiran Hari Ini',
                  value: stats.attendanceToday,
                  color: Colors.purple,
                ),
                _StatCard(
                  icon: Icons.event_busy,
                  label: 'Booking Dibatalkan',
                  value: stats.cancelledBookings,
                  color: Colors.red,
                ),
              ],
            ),
          ],

          if (charts == null) ...[
            const SizedBox(height: 24),
            const Center(child: Text('Belum ada data grafik')),
          ] else ...[
            const SizedBox(height: 16),

            // --- Tren booking (PRD 8.1). ---
            _ChartCard(
              title: 'Tren Booking',
              subtitle: _rangeLabel(charts),
              child: _BarChart(
                data: charts.bookingTrend
                    .map((p) => _BarPoint(p.date.substring(5), p.count))
                    .toList(),
                color: Colors.indigo,
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
                color: Colors.purple,
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

            // --- Fasilitas populer. ---
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
                      color: Colors.teal,
                    ),
            ),
            const SizedBox(height: 12),

            // --- Jam ramai. ---
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
                      color: Colors.orange,
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
  final MaterialColor color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            Text(subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            SizedBox(height: 130, width: double.infinity, child: child),
          ],
        ),
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
  final Color color;

  const _BarChart({required this.data, required this.color});

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
              color: color,
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
                    style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<_BarPoint> data;
  final Color color;
  final int maxValue;

  _BarChartPainter({
    required this.data,
    required this.color,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxValue <= 0) return;

    final barGap = 2.0;
    final barWidth = (size.width / data.length) - barGap;
    final paint = Paint()..color = color;

    for (var i = 0; i < data.length; i++) {
      final h = data[i].value / maxValue * (size.height - 8);
      final x = i * (barWidth + barGap);
      final rect = Rect.fromLTWH(
        x,
        size.height - h,
        barWidth < 2 ? 2 : barWidth,
        h,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}

/// Bar horizontal berperingkat (fasilitas populer).
class _RankedBars extends StatelessWidget {
  final List<MapEntry<String, int>> items;
  final MaterialColor color;

  const _RankedBars({required this.items, required this.color});

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
              SizedBox(
                width: 90,
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
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: e.value / maxV,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: color.shade300,
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

/// Rincian status booking (chips dengan jumlah).
class _StatusBreakdown extends StatelessWidget {
  final Map<String, int> statusCounts;

  const _StatusBreakdown({required this.statusCounts});

  @override
  Widget build(BuildContext context) {
    const colors = {
      'Pending': Colors.orange,
      'Confirmed': Colors.green,
      'Completed': Colors.blue,
      'Cancelled': Colors.grey,
      'Rejected': Colors.red,
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in statusCounts.entries)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (colors[entry.key] ?? Colors.grey).shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (colors[entry.key] ?? Colors.grey).shade200,
              ),
            ),
            child: Text(
              '${entry.key}: ${entry.value}',
              style: TextStyle(
                fontSize: 12,
                color: (colors[entry.key] ?? Colors.grey).shade700,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyChartHint extends StatelessWidget {
  const _EmptyChartHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Belum ada data',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/qr_downloader.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/sms_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../auth/Welcome_screen.dart';

/// Shared brand color for the whole admin shell — taken from
/// AppColors.primary (dark blue) to stay consistent with the rest of the
/// RepairTrack app, not the pink/red used in the reference/inspiration image.
const Color _kBrand = Color(0xFF1565C0);
const Color _kBg = Color(0xFFF5F7FA);
const Color _kCardBorder = Color(0xFFE5E7EB);
const Color _kTextDark = Color(0xFF111827);
const Color _kTextGray = Color(0xFF6B7280);

/// ── Admin Shell ───────────────────────────────────────────────────
/// This is the new "root" of the Admin side: has a sidebar (when the
/// screen is wide — desktop/web/tablet) or a bottom nav (when narrow —
/// mobile app), with 6 sections: Dashboard, Requests, Technicians,
/// Schedule, Reports, Settings.
///
/// The class name was left unchanged (still AdminDashboardScreen) so
/// the import/route doesn't need to be updated elsewhere in the app
/// (e.g. in Welcome_screen.dart or wherever the route to the admin
/// side is declared).
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  static const _sections = [
    _NavItem('Dashboard', Icons.dashboard_rounded),
    _NavItem('Requests', Icons.assignment_rounded),
    _NavItem('Technicians', Icons.engineering_rounded),
    _NavItem('Schedule', Icons.calendar_month_rounded),
    _NavItem('Reports', Icons.bar_chart_rounded),
    _NavItem('Settings', Icons.settings_rounded),
  ];

  static const List<Widget> _pages = [
    _OverviewPage(),
    _RequestsQueuePage(),
    _TechniciansPage(),
    _SchedulePage(),
    _ReportsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  _SideNav(
                    items: _sections,
                    selectedIndex: _selectedIndex,
                    onSelect: (i) => setState(() => _selectedIndex = i),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _TopBar(title: _sections[_selectedIndex].label),
                        Expanded(child: _pages[_selectedIndex]),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  _TopBar(title: _sections[_selectedIndex].label),
                  Expanded(child: _pages[_selectedIndex]),
                ],
              ),
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              backgroundColor: Colors.white,
              indicatorColor: _kBrand.withValues(alpha: 0.12),
              height: 64,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: _sections
                  .map(
                    (s) => NavigationDestination(
                      icon: Icon(s.icon, color: _kTextGray),
                      selectedIcon: Icon(s.icon, color: _kBrand),
                      label: s.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}

/// Sidebar for web/desktop/tablet width — follows the same pattern
/// as the reference image (logo at the top, list of nav items,
/// but without the "Pro Trial" upsell card, which was removed).
class _SideNav extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _SideNav({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded, color: _kBrand, size: 26),
                SizedBox(width: 8),
                Text(
                  'RepairTrack',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kBrand,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final selected = index == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: selected
                        ? _kBrand.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onSelect(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: selected ? _kBrand : _kTextGray,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: selected ? _kBrand : _kTextDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Divider(height: 1, color: _kCardBorder),
          ),
        ],
      ),
    );
  }
}

/// Simple top bar with just a title + date — no search/mail
/// icons that don't actually work (to avoid confusing the user).
class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final dateStr =
        '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day} ${now.year}';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kCardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _kTextDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Updated $dateStr',
                  style: const TextStyle(fontSize: 12, color: _kTextGray),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: _kBrand.withValues(alpha: 0.12),
            child: const Icon(Icons.person, color: _kBrand, size: 18),
          ),
        ],
      ),
    );
  }
}

/// Reusable stat card, used on the Dashboard/Overview page.
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: _kTextGray),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: _kTextDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Dashboard / Overview Page ────────────────────────────────────
class _OverviewPage extends StatelessWidget {
  const _OverviewPage();

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.streamRepairRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.only(top: 80),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          final allData =
              docs.map((d) => d.data() as Map<String, dynamic>).toList();

          final activeJobs = allData.where((d) {
            final s = d['status'];
            return s != 'Completed' && s != 'Declined';
          }).length;

          final today = DateTime.now();
          bool isToday(Timestamp? ts) {
            if (ts == null) return false;
            final d = ts.toDate();
            return d.year == today.year &&
                d.month == today.month &&
                d.day == today.day;
          }

          final completedToday = allData.where((d) {
            return d['status'] == 'Completed' &&
                isToday(d['updatedAt'] as Timestamp?);
          }).length;

          final pendingCount =
              allData.where((d) => d['status'] == 'Pending').length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWideRow = constraints.maxWidth > 700;
                  final cards = [
                    _StatCard(
                      label: 'Active Jobs',
                      value: '$activeJobs',
                      icon: Icons.work_outline_rounded,
                      iconColor: _kBrand,
                      iconBg: _kBrand.withValues(alpha: 0.1),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: firestoreService.streamTechnicians(),
                      builder: (context, techSnap) {
                        final count = techSnap.data?.docs.length ?? 0;
                        return _StatCard(
                          label: 'Technicians',
                          value: '$count',
                          icon: Icons.engineering_rounded,
                          iconColor: const Color(0xFF7E57C2),
                          iconBg:
                              const Color(0xFF7E57C2).withValues(alpha: 0.1),
                        );
                      },
                    ),
                    _StatCard(
                      label: 'Completed Today',
                      value: '$completedToday',
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: const Color(0xFF16A34A),
                      iconBg: const Color(0xFF16A34A).withValues(alpha: 0.1),
                    ),
                    _StatCard(
                      label: 'Pending Requests',
                      value: '$pendingCount',
                      icon: Icons.pending_actions_rounded,
                      iconColor: const Color(0xFFEA580C),
                      iconBg: const Color(0xFFEA580C).withValues(alpha: 0.1),
                    ),
                  ];

                  if (isWideRow) {
                    return Row(
                      children: cards
                          .map((c) => Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: c,
                                ),
                              ))
                          .toList(),
                    );
                  }
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: cards,
                  );
                },
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWideTrend = constraints.maxWidth > 900;
                  final trendPanel = _RepairTrendPanel(allRequests: allData);
                  final turnaroundPanel =
                      _TurnaroundPanel(allRequests: allData);

                  if (isWideTrend) {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 7, child: trendPanel),
                          const SizedBox(width: 16),
                          Expanded(flex: 3, child: turnaroundPanel),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
                      trendPanel,
                      const SizedBox(height: 16),
                      turnaroundPanel,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _TodayScheduleCard(allRequests: allData),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWideCols = constraints.maxWidth > 900;
                  final techniciansPanel =
                      _TechnicianStatusPanel(allRequests: allData);
                  final activityPanel =
                      _RecentActivityPanel(docs: docs.take(8).toList());

                  if (isWideCols) {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 4, child: techniciansPanel),
                          const SizedBox(width: 16),
                          Expanded(flex: 6, child: activityPanel),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
                      techniciansPanel,
                      const SizedBox(height: 16),
                      activityPanel,
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Bar chart of repairs completed per day, for the last 7 days.
class _RepairTrendPanel extends StatelessWidget {
  final List<Map<String, dynamic>> allRequests;
  const _RepairTrendPanel({required this.allRequests});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final dayCounts = <int>[];
    final dayLabels = <String>[];
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final count = allRequests.where((d) {
        if (d['status'] != 'Completed') return false;
        final ts = d['updatedAt'] as Timestamp?;
        if (ts == null) return false;
        final dt = ts.toDate();
        return dt.year == day.year &&
            dt.month == day.month &&
            dt.day == day.day;
      }).length;
      dayCounts.add(count);
      dayLabels.add(weekdayShort[day.weekday - 1]);
    }

    final maxCount =
        dayCounts.isEmpty ? 1 : dayCounts.reduce((a, b) => a > b ? a : b);
    final safeMax = maxCount < 1 ? 1 : maxCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Repair Trend',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: _kTextDark),
          ),
          const SizedBox(height: 2),
          const Text(
            'Repairs completed per day, last 7 days',
            style: TextStyle(fontSize: 12, color: _kTextGray),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(dayCounts.length, (i) {
                final barHeight = (dayCounts[i] / safeMax) * 90;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${dayCounts[i]}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: barHeight < 4 ? 4 : barHeight,
                          decoration: BoxDecoration(
                            color: _kBrand,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dayLabels[i],
                          style: const TextStyle(
                              fontSize: 11, color: _kTextGray),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Average turnaround time.
class _TurnaroundPanel extends StatelessWidget {
  final List<Map<String, dynamic>> allRequests;
  const _TurnaroundPanel({required this.allRequests});

  double? _averageDaysForCompletedInRange(
      List<Map<String, dynamic>> data, DateTime start, DateTime end) {
    final durations = <double>[];
    for (final d in data) {
      if (d['status'] != 'Completed') continue;
      final createdTs = d['createdAt'] as Timestamp?;
      final updatedTs = d['updatedAt'] as Timestamp?;
      if (createdTs == null || updatedTs == null) continue;
      final completedAt = updatedTs.toDate();
      if (completedAt.isBefore(start) || !completedAt.isBefore(end)) {
        continue;
      }
      final days = completedAt.difference(createdTs.toDate()).inMinutes / 1440;
      durations.add(days);
    }
    if (durations.isEmpty) return null;
    return durations.reduce((a, b) => a + b) / durations.length;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisWeekStart = now.subtract(const Duration(days: 7));
    final lastWeekStart = now.subtract(const Duration(days: 14));

    final thisWeekAvg =
        _averageDaysForCompletedInRange(allRequests, thisWeekStart, now);
    final lastWeekAvg = _averageDaysForCompletedInRange(
        allRequests, lastWeekStart, thisWeekStart);

    final hasData = thisWeekAvg != null;
    final displayValue =
        hasData ? thisWeekAvg.toStringAsFixed(1) : '—';

    String? badgeText;
    Color badgeColor = _kTextGray;
    IconData badgeIcon = Icons.remove_rounded;
    if (hasData && lastWeekAvg != null) {
      final diff = thisWeekAvg - lastWeekAvg;
      final improved = diff < 0;
      badgeColor =
          improved ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
      badgeIcon = improved
          ? Icons.arrow_downward_rounded
          : Icons.arrow_upward_rounded;
      badgeText = '${diff.abs().toStringAsFixed(1)} days vs last week';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Avg. Turnaround Time',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _kTextGray),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                displayValue,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _kTextDark,
                ),
              ),
              if (hasData) ...[
                const SizedBox(width: 6),
                const Text(
                  'days average',
                  style: TextStyle(fontSize: 13, color: _kTextGray),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (badgeText != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, size: 12, color: badgeColor),
                  const SizedBox(width: 4),
                  Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                    ),
                  ),
                ],
              ),
            )
          else
            const Text(
              'Not enough completed repairs yet to compare.',
              style: TextStyle(fontSize: 11, color: _kTextGray),
            ),
        ],
      ),
    );
  }
}

/// Full-width card showing only today's appointments.
class _TodayScheduleCard extends StatelessWidget {
  final List<Map<String, dynamic>> allRequests;
  const _TodayScheduleCard({required this.allRequests});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    bool isToday(DateTime d) =>
        d.year == now.year && d.month == now.month && d.day == now.day;

    final todayJobs = allRequests.where((d) {
      final ts = d['scheduledVisit'] as Timestamp?;
      if (ts == null) return false;
      return isToday(ts.toDate());
    }).toList();

    todayJobs.sort((a, b) {
      final aTs = (a['scheduledVisit'] as Timestamp).toDate();
      final bTs = (b['scheduledVisit'] as Timestamp).toDate();
      return aTs.compareTo(bTs);
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Schedule",
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: _kTextDark),
          ),
          const SizedBox(height: 2),
          Text(
            todayJobs.isEmpty
                ? 'No home visits scheduled for today'
                : '${todayJobs.length} appointment(s) scheduled today',
            style: const TextStyle(fontSize: 12, color: _kTextGray),
          ),
          const SizedBox(height: 14),
          if (todayJobs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No In Home visits scheduled for today.',
                style: TextStyle(fontSize: 13, color: _kTextGray),
              ),
            )
          else
            ...todayJobs.map((data) {
              final ts = data['scheduledVisit'] as Timestamp;
              final date = ts.toDate();
              final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
              final ampm = date.hour >= 12 ? 'PM' : 'AM';
              final timeLabel =
                  '$hour12:${date.minute.toString().padLeft(2, '0')} $ampm';
              final status = data['status'] ?? 'Pending';
              final colors = _statusColors(status);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 68,
                      child: Text(
                        timeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kTextDark,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data['applianceType'] ?? ''} repair',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kTextDark,
                            ),
                          ),
                          Text(
                            data['name'] ?? '',
                            style: const TextStyle(
                                fontSize: 11, color: _kTextGray),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        (data['assignedTechnician'] as String?) ??
                            'Unassigned',
                        style:
                            const TextStyle(fontSize: 12, color: _kTextGray),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.$1,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.$2,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Panel showing each technician.
class _TechnicianStatusPanel extends StatelessWidget {
  final List<Map<String, dynamic>> allRequests;
  const _TechnicianStatusPanel({required this.allRequests});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Technician Status',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: _kTextDark),
          ),
          const SizedBox(height: 2),
          const Text(
            'Current active job load per technician',
            style: TextStyle(fontSize: 12, color: _kTextGray),
          ),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot>(
            stream: FirestoreService().streamTechnicians(),
            builder: (context, snapshot) {
              final techs = snapshot.data?.docs ?? [];
              if (techs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No technicians yet. Add one from the Technicians tab.',
                    style: TextStyle(fontSize: 13, color: _kTextGray),
                  ),
                );
              }
              return Column(
                children: techs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? '';

                  final assignedJobs = allRequests.where((r) {
                    return r['assignedTechnician'] == name &&
                        r['status'] != 'Completed' &&
                        r['status'] != 'Declined';
                  }).toList();

                  String currentLocation = 'Available';
                  Color locColor = const Color(0xFF16A34A);
                  Color locBg = const Color(0xFF16A34A).withValues(alpha: .1);
                  if (assignedJobs.isNotEmpty) {
                    final currentStatus = assignedJobs.first['status'];
                    if (currentStatus == 'In Home') {
                      currentLocation = 'In Home';
                      locColor = const Color(0xFF5B21B6);
                      locBg = const Color(0xFF5B21B6).withValues(alpha: .1);
                    } else if (currentStatus == 'In Shop') {
                      currentLocation = 'In Shop';
                      locColor = const Color(0xFF1565C0);
                      locBg = const Color(0xFF1565C0).withValues(alpha: .1);
                    } else {
                      currentLocation = currentStatus ?? 'Assigned';
                      locColor = _kTextGray;
                      locBg = const Color(0xFFF3F4F6);
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: _kBrand.withValues(alpha: 0.1),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: _kBrand,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kTextDark,
                                ),
                              ),
                              Text(
                                '${assignedJobs.length} job(s) assigned',
                                style: const TextStyle(
                                    fontSize: 11, color: _kTextGray),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: locBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            currentLocation,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: locColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Replacement for the "Recent Activity" table.
class _RecentActivityPanel extends StatelessWidget {
  final List<QueryDocumentSnapshot> docs;
  const _RecentActivityPanel({required this.docs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: _kTextDark),
          ),
          const SizedBox(height: 2),
          Text(
            'Latest ${docs.length} repair requests',
            style: const TextStyle(fontSize: 12, color: _kTextGray),
          ),
          const SizedBox(height: 14),
          if (docs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No requests yet.',
                style: TextStyle(fontSize: 13, color: _kTextGray),
              ),
            )
          else
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'Pending';
              final colors = _statusColors(status);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        data['trackingId'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kTextDark,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        data['applianceType'] ?? '',
                        style:
                            const TextStyle(fontSize: 12, color: _kTextGray),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        (data['assignedTechnician'] as String?) ?? '—',
                        style:
                            const TextStyle(fontSize: 12, color: _kTextGray),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.$1,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.$2,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// ── Requests Page ────────────────────────────────────────────────
class _RequestsQueuePage extends StatefulWidget {
  const _RequestsQueuePage();

  @override
  State<_RequestsQueuePage> createState() => _RequestsQueuePageState();
}

class _RequestsQueuePageState extends State<_RequestsQueuePage>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: _kBrand,
            unselectedLabelColor: _kTextGray,
            indicatorColor: _kBrand,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'New Requests'),
              Tab(text: 'In Progress'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.streamRepairRequests(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final allDocs = snapshot.data?.docs ?? [];

              final pendingDocs = allDocs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return data['status'] == 'Pending';
              }).toList();

              final inProgressDocs = allDocs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final s = data['status'];
                return s != 'Pending' && s != 'Completed' && s != 'Declined';
              }).toList();

              final completedDocs = allDocs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return data['status'] == 'Completed';
              }).toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildList(pendingDocs,
                      emptyText: 'No new repair requests.'),
                  _buildList(inProgressDocs,
                      emptyText: 'No ongoing repairs right now.'),
                  _buildList(completedDocs,
                      emptyText: 'No completed repairs yet.'),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<QueryDocumentSnapshot> docs,
      {required String emptyText}) {
    if (docs.isEmpty) {
      return Center(
        child: Text(emptyText, style: const TextStyle(color: _kTextGray)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data() as Map<String, dynamic>;
        return _buildRequestCard(context, doc.id, data);
      },
    );
  }
}

/// ── Technicians Page ─────────────────────────────────────────────
class _TechniciansPage extends StatefulWidget {
  const _TechniciansPage();

  @override
  State<_TechniciansPage> createState() => _TechniciansPageState();
}

class _TechniciansPageState extends State<_TechniciansPage> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _showAddTechnicianDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Add New Technician'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Juan Dela Cruz',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBrand,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _firestoreService.addTechnician(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$result" added as a technician.')),
        );
      }
    }
  }

  Future<void> _deleteTechnician(String docId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Remove Technician?'),
        content: Text(
          '"$name" will be removed from your technician list. Existing '
          'repair records assigned to them will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(docId)
          .delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$name" removed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manage your repair technicians',
                style: TextStyle(fontSize: 13, color: _kTextGray),
              ),
              ElevatedButton.icon(
                onPressed: _showAddTechnicianDialog,
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Add Technician'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBrand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.streamRepairRequests(),
              builder: (context, requestsSnap) {
                final allData = (requestsSnap.data?.docs ?? [])
                    .map((d) => d.data() as Map<String, dynamic>)
                    .toList();

                return StreamBuilder<QuerySnapshot>(
                  stream: _firestoreService.streamTechnicians(),
                  builder: (context, techSnap) {
                    if (techSnap.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    final techs = techSnap.data?.docs ?? [];
                    if (techs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No technicians yet. Tap "Add Technician" '
                          'to add one.',
                          style: TextStyle(color: _kTextGray),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount =
                            (constraints.maxWidth / 320).floor().clamp(1, 4);
                        return GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.6,
                          ),
                          itemCount: techs.length,
                          itemBuilder: (context, index) {
                            final doc = techs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final name = data['name'] ?? '';

                            final assignedJobs = allData.where((r) {
                              return r['assignedTechnician'] == name &&
                                  r['status'] != 'Completed' &&
                                  r['status'] != 'Declined';
                            }).toList();

                            final completedJobs = allData.where((r) {
                              return r['assignedTechnician'] == name &&
                                  r['status'] == 'Completed';
                            }).length;

                            String currentLocation = 'Available';
                            Color locColor = const Color(0xFF16A34A);
                            Color locBg = const Color(0xFF16A34A)
                                .withValues(alpha: .1);
                            if (assignedJobs.isNotEmpty) {
                              final currentStatus =
                                  assignedJobs.first['status'];
                              if (currentStatus == 'In Home') {
                                currentLocation = 'In Home';
                                locColor = const Color(0xFF5B21B6);
                                locBg = const Color(0xFF5B21B6)
                                    .withValues(alpha: .1);
                              } else if (currentStatus == 'In Shop') {
                                currentLocation = 'In Shop';
                                locColor = const Color(0xFF1565C0);
                                locBg = const Color(0xFF1565C0)
                                    .withValues(alpha: .1);
                              } else {
                                currentLocation = currentStatus ?? 'Assigned';
                                locColor = _kTextGray;
                                locBg = const Color(0xFFF3F4F6);
                              }
                            }

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _kCardBorder),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor:
                                            _kBrand.withValues(alpha: 0.1),
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: _kBrand,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: _kTextDark,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 20),
                                        color: const Color(0xFFDC2626),
                                        visualDensity: VisualDensity.compact,
                                        tooltip: 'Remove technician',
                                        onPressed: () => _deleteTechnician(
                                            doc.id, name),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _MiniStat(
                                          label: 'Assigned',
                                          value: '${assignedJobs.length}',
                                        ),
                                      ),
                                      Expanded(
                                        child: _MiniStat(
                                          label: 'Completed',
                                          value: '$completedJobs',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6),
                                    decoration: BoxDecoration(
                                      color: locBg,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      currentLocation,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: locColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _kTextDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: _kTextGray),
        ),
      ],
    );
  }
}

/// ── Schedule Page ────────────────────────────────────────────────
class _SchedulePage extends StatelessWidget {
  const _SchedulePage();

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.streamRepairRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allDocs = snapshot.data?.docs ?? [];

        final scheduledDocs = allDocs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return data['status'] == 'In Home' && data['scheduledVisit'] != null;
        }).toList();

        scheduledDocs.sort((a, b) {
          final aTs = (a.data() as Map<String, dynamic>)['scheduledVisit']
              as Timestamp;
          final bTs = (b.data() as Map<String, dynamic>)['scheduledVisit']
              as Timestamp;
          return aTs.compareTo(bTs);
        });

        if (scheduledDocs.isEmpty) {
          return const Center(
            child: Text(
              'No In Home visits scheduled right now.\n\n'
              'Requests will show up here once their status is set '
              'to "In Home" with a schedule.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _kTextGray),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: scheduledDocs.length,
          itemBuilder: (context, index) {
            final data =
                scheduledDocs[index].data() as Map<String, dynamic>;
            final scheduledVisit = data['scheduledVisit'] as Timestamp;
            final date = scheduledVisit.toDate();

            const months = [
              'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
            ];
            final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
            final ampm = date.hour >= 12 ? 'PM' : 'AM';
            final dateLabel = '${months[date.month - 1]} ${date.day}, '
                '${date.year} • $hour12:${date.minute.toString().padLeft(2, '0')} $ampm';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kCardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B21B6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.home_repair_service_rounded,
                        color: Color(0xFF5B21B6), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['trackingId'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${data['applianceType'] ?? ''} • ${data['name'] ?? ''}',
                          style: const TextStyle(
                              fontSize: 12, color: _kTextGray),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded,
                                size: 13, color: _kTextGray),
                            const SizedBox(width: 4),
                            Text(
                              dateLabel,
                              style: const TextStyle(
                                  fontSize: 12, color: _kTextGray),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (data['assignedTechnician'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kBrand.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        data['assignedTechnician'],
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _kBrand,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// ── Reports Page ─────────────────────────────────────────────────
class _ReportsPage extends StatelessWidget {
  const _ReportsPage();

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.streamRepairRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allData = (snapshot.data?.docs ?? [])
            .map((d) => d.data() as Map<String, dynamic>)
            .toList();

        final total = allData.length;
        final completed =
            allData.where((d) => d['status'] == 'Completed').length;
        final declined =
            allData.where((d) => d['status'] == 'Declined').length;
        final completionRate =
            total == 0 ? 0.0 : (completed / total * 100);

        final now = DateTime.now();
        final dayLabels = <String>[];
        final dayCounts = <int>[];
        const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        for (int i = 6; i >= 0; i--) {
          final day = now.subtract(Duration(days: i));
          final count = allData.where((d) {
            if (d['status'] != 'Completed') return false;
            final ts = d['updatedAt'] as Timestamp?;
            if (ts == null) return false;
            final dt = ts.toDate();
            return dt.year == day.year &&
                dt.month == day.month &&
                dt.day == day.day;
          }).length;
          dayLabels.add(weekdayShort[day.weekday - 1]);
          dayCounts.add(count);
        }

        final maxCount = dayCounts.isEmpty
            ? 1
            : dayCounts.reduce((a, b) => a > b ? a : b).clamp(1, 999);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  final cards = [
                    _StatCard(
                      label: 'Total Requests',
                      value: '$total',
                      icon: Icons.inbox_rounded,
                      iconColor: _kBrand,
                      iconBg: _kBrand.withValues(alpha: 0.1),
                    ),
                    _StatCard(
                      label: 'Completed',
                      value: '$completed',
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: const Color(0xFF16A34A),
                      iconBg: const Color(0xFF16A34A).withValues(alpha: 0.1),
                    ),
                    _StatCard(
                      label: 'Declined',
                      value: '$declined',
                      icon: Icons.cancel_outlined,
                      iconColor: const Color(0xFFDC2626),
                      iconBg: const Color(0xFFDC2626).withValues(alpha: 0.1),
                    ),
                    _StatCard(
                      label: 'Completion Rate',
                      value: '${completionRate.toStringAsFixed(0)}%',
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFF7E57C2),
                      iconBg: const Color(0xFF7E57C2).withValues(alpha: 0.1),
                    ),
                  ];
                  if (isWide) {
                    return Row(
                      children: cards
                          .map((c) => Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: c,
                                ),
                              ))
                          .toList(),
                    );
                  }
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: cards,
                  );
                },
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kCardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Repairs Completed — Last 7 Days',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _kTextDark),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 160,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(dayCounts.length, (i) {
                          final barHeight =
                              (dayCounts[i] / maxCount) * 120;
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${dayCounts[i]}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _kTextDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height:
                                        barHeight < 4 ? 4 : barHeight,
                                    decoration: BoxDecoration(
                                      color: _kBrand,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    dayLabels[i],
                                    style: const TextStyle(
                                        fontSize: 11, color: _kTextGray),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// From "In Home" onward, the request already has a QR record (created
/// the first time it was set to "In Home") — so the "View QR" button
/// already shows starting here, rather than waiting for "Completed".
const _kQrEligibleStatuses = {
  'In Home',
  'In Shop',
  'In Process',
  'Waiting for Parts',
  'Completed',
};

Widget _buildRequestCard(BuildContext context, String docId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'Pending';
    final trackingId = data['trackingId'] ?? '';
    final name = data['name'] ?? '';
    final applianceType = data['applianceType'] ?? '';
    final contactNumber = data['contactNumber'] ?? '';
    final assignedTechnician = data['assignedTechnician'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _handleCardTap(context, docId, data),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    trackingId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 1,
                      color: Color(0xFF111827),
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$applianceType • $contactNumber',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
              if (assignedTechnician != null &&
                  assignedTechnician.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.engineering_outlined,
                        size: 13, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text(
                      assignedTechnician,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: _kQrEligibleStatuses.contains(status)
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.end,
                children: [
                  if (_kQrEligibleStatuses.contains(status))
                    TextButton.icon(
                      onPressed: () => _showQrDialog(context, trackingId, name),
                      icon: const Icon(Icons.qr_code_2, size: 16),
                      label: const Text('View QR'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF166534),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'I-update',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right,
                          size: 18, color: Color(0xFF2563EB)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

void _handleCardTap(BuildContext context, String docId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'Pending';
    if (status == 'Pending') {
      _openReviewSheet(context, docId, data);
    } else {
      _openUpdateSheet(context, docId, data);
    }
  }

void _showQrDialog(BuildContext context, String trackingId, String customerName) {
    showDialog(
      context: context,
      builder: (context) => _QrCodeDialog(
        trackingId: trackingId,
        customerName: customerName,
      ),
    );
  }

void _openReviewSheet(BuildContext context, String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReviewRequestSheet(
        docId: docId,
        trackingId: data['trackingId'] ?? '',
        name: data['name'] ?? '',
        contactNumber: data['contactNumber'] ?? '',
        address: data['address'] ?? '',
        applianceType: data['applianceType'] ?? '',
        problemDescription: data['problemDescription'] ?? '',
        initialPhotoUrl: data['initialPhotoUrl'] as String?,
      ),
    );
  }

void _openUpdateSheet(BuildContext context, String docId, Map<String, dynamic> data) {
    final scheduledVisit = data['scheduledVisit'] as Timestamp?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UpdateStatusSheet(
        docId: docId,
        currentStatus: data['status'] ?? 'Pending',
        trackingId: data['trackingId'] ?? '',
        contactNumber: data['contactNumber'] ?? '',
        applianceType: data['applianceType'] ?? '',
        currentTechnician: data['assignedTechnician'] as String?,
        initialScheduledDate: scheduledVisit?.toDate(),
      ),
    );
  }

Widget _buildStatusBadge(String status) {
    final colors = _statusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.$2,
        ),
      ),
    );
  }

(Color, Color) _statusColors(String status) {
  switch (status) {
    case 'Pending':
      return (const Color(0xFFFEF3C7), const Color(0xFF92400E));
    case 'Accepted':
      return (const Color(0xFFDBEAFE), const Color(0xFF1E40AF));
    case 'In Home':
    case 'In Shop':
      return (const Color(0xFFEDE9FE), const Color(0xFF5B21B6));
    case 'In Process':
      return (const Color(0xFFFCE7F3), const Color(0xFF9D174D));
    case 'Waiting for Parts':
      return (const Color(0xFFFEE2E2), const Color(0xFF991B1B));
    case 'Completed':
      return (const Color(0xFFDCFCE7), const Color(0xFF166534));
    case 'Declined':
      return (const Color(0xFFFEE2E2), const Color(0xFF7F1D1D));
    default:
      return (const Color(0xFFF3F4F6), const Color(0xFF374151));
  }
}

class _UpdateStatusSheet extends StatefulWidget {
  final String docId;
  final String currentStatus;
  final String trackingId;
  final String contactNumber;
  final String applianceType;
  final String? currentTechnician;
  final DateTime? initialScheduledDate;

  const _UpdateStatusSheet({
    required this.docId,
    required this.currentStatus,
    required this.trackingId,
    required this.contactNumber,
    required this.applianceType,
    this.currentTechnician,
    this.initialScheduledDate,
  });

  @override
  State<_UpdateStatusSheet> createState() => _UpdateStatusSheetState();
}

class _UpdateStatusSheetState extends State<_UpdateStatusSheet> {
  final FirestoreService _firestoreService = FirestoreService();
  final SmsService _smsService = SmsService();
  final StorageService _storageService = StorageService();
  final TextEditingController _noteController = TextEditingController();

  late String _selectedStatus;
  String? _partsSource;
  String? _selectedTechnician;
  DateTime? _scheduledDateTime;
  Uint8List? _selectedImage;
  bool _isSubmitting = false;

  int? _warrantyMonths = 3;
  final TextEditingController _warrantyTermsController =
      TextEditingController(
    text: 'Covers the same issue that was repaired. Does not cover new '
        'damage or misuse.',
  );

  // "In Process" is rarely used now — most in-home jobs go straight
  // from "In Home" to "Completed" (the technician has no dashboard
  // access, so it's a verbal report; the note on "Completed" contains
  // what was done, based on that report).
  static const _statusesNeedingPartsSource = {
    'In Process',
    'Waiting for Parts',
  };

  // "Completed" — the note is required because this is where the admin
  // enters the service summary (based on the technician's report) as
  // part of the service record. "Waiting for Parts" — also required so
  // it's clear which parts are being waited on.
  bool get _noteRequired =>
      _selectedStatus == 'Completed' || _selectedStatus == 'Waiting for Parts';
  bool get _partsSourceRelevant =>
      _statusesNeedingPartsSource.contains(_selectedStatus);
  bool get _scheduleRequired => _selectedStatus == 'In Home';
  bool get _warrantyRelevant => _selectedStatus == 'Completed';

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
    _selectedTechnician = widget.currentTechnician;
    _scheduledDateTime = widget.initialScheduledDate;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _warrantyTermsController.dispose();
    super.dispose();
  }

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _scheduledDateTime ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _scheduledDateTime != null
          ? TimeOfDay.fromDateTime(_scheduledDateTime!)
          : const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;

    setState(() {
      _scheduledDateTime =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  String _formatSchedule(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $hour:$minute $period';
  }

  Future<void> _pickPhoto() async {
    ImageSource source = ImageSource.gallery;

    if (!kIsWeb) {
      final chosen = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take Photo with Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (chosen == null) return;
      source = chosen;
    }

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _selectedImage = bytes);
    }
  }

  Future<String?> _showAddTechnicianDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Technician'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Technician name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitUpdate() async {
    if (_scheduleRequired && _scheduledDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select the date and time of the technician visit.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_partsSourceRelevant && _partsSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a parts source first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_noteRequired && _noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a note/remarks for this update.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? photoUrl;
      if (_selectedImage != null) {
        photoUrl = await _storageService.uploadPhoto(
          bytes: _selectedImage!,
          trackingId: widget.trackingId,
        );
      }

      await _firestoreService.updateRepairStatus(
        docId: widget.docId,
        trackingId: widget.trackingId,
        newStatus: _selectedStatus,
        note: _noteController.text,
        partsSource: _partsSourceRelevant ? _partsSource : null,
        assignedTechnician: _selectedTechnician,
        scheduledDate: _scheduleRequired ? _scheduledDateTime : null,
        photoUrl: photoUrl,
        warrantyMonths: _warrantyRelevant ? _warrantyMonths : null,
        warrantyTerms: _warrantyRelevant
            ? _warrantyTermsController.text
            : null,
      );

      // As soon as the status becomes "In Home", create the QR
      // record right away if it doesn't exist yet — so the technician
      // doesn't need to come back to the shop just to get the QR after
      // it's completed. The QR's content is permanent (just the
      // trackingId), so this only happens once; the details shown when
      // scanned are always live from Firestore, so they update automatically.
      if (_selectedStatus == 'In Home') {
        await FirebaseFirestore.instance
            .collection('repairRequests')
            .doc(widget.docId)
            .set({'hasQrCode': true}, SetOptions(merge: true));
      }

      final shopInfoDoc = await FirebaseFirestore.instance
          .collection('shopSettings')
          .doc('config')
          .get();
      final shopName = shopInfoDoc.data()?['shopName'] ?? 'RepairTrack';

      await _smsService.sendStatusUpdateSms(
        shopName: shopName,
        contactNumber: widget.contactNumber,
        trackingId: widget.trackingId,
        applianceType: widget.applianceType,
        newStatus: _selectedStatus,
        note: _noteController.text,
        technician: _selectedTechnician,
        scheduledDate: _scheduleRequired ? _scheduledDateTime : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated and customer notified.'),
            backgroundColor: Color(0xFF166534),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildTechnicianField() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.streamTechnicians(),
      builder: (context, snapshot) {
        final technicians = (snapshot.data?.docs ?? [])
            .map((doc) => (doc.data() as Map<String, dynamic>)['name'] as String)
            .toList();

        if (_selectedTechnician != null &&
            !technicians.contains(_selectedTechnician)) {
          technicians.add(_selectedTechnician!);
        }

        return DropdownButtonFormField<String>(
          initialValue: _selectedTechnician,
          hint: const Text('Not yet assigned'),
          items: [
            ...technicians.map(
              (name) => DropdownMenuItem(value: name, child: Text(name)),
            ),
            const DropdownMenuItem(
              value: '__add_new__',
              child: Row(
                children: [
                  Icon(Icons.add, size: 16, color: Color(0xFF2563EB)),
                  SizedBox(width: 6),
                  Text('Add New Technician',
                      style: TextStyle(color: Color(0xFF2563EB))),
                ],
              ),
            ),
          ],
          onChanged: (value) async {
            if (value == '__add_new__') {
              final newName = await _showAddTechnicianDialog();
              if (newName != null && newName.trim().isNotEmpty) {
                await _firestoreService.addTechnician(newName.trim());
                setState(() => _selectedTechnician = newName.trim());
              }
            } else {
              setState(() => _selectedTechnician = value);
            }
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Update Status — ${widget.trackingId}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 20),

              const Text('New Status',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151))),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                items: AppConstants.allStatuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedStatus = value);
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_scheduleRequired) ...[
                const Text('Technician Visit Schedule',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151))),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickSchedule,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 18, color: Color(0xFF2563EB)),
                        const SizedBox(width: 10),
                        Text(
                          _scheduledDateTime != null
                              ? _formatSchedule(_scheduledDateTime!)
                              : 'Select date and time',
                          style: TextStyle(
                            fontSize: 13,
                            color: _scheduledDateTime != null
                                ? const Color(0xFF111827)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_partsSourceRelevant) ...[
                const Text('Parts Source',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151))),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Customer Supplied'),
                        selected: _partsSource == 'Customer Supplied',
                        onSelected: (_) => setState(
                            () => _partsSource = 'Customer Supplied'),
                        selectedColor: const Color(0xFF2563EB),
                        backgroundColor: const Color(0xFFF9FAFB),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _partsSource == 'Customer Supplied'
                              ? Colors.white
                              : const Color(0xFF6B7280),
                        ),
                        side: BorderSide(
                          color: _partsSource == 'Customer Supplied'
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Shop Supplied'),
                        selected: _partsSource == 'Shop Supplied',
                        onSelected: (_) =>
                            setState(() => _partsSource = 'Shop Supplied'),
                        selectedColor: const Color(0xFF2563EB),
                        backgroundColor: const Color(0xFFF9FAFB),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _partsSource == 'Shop Supplied'
                              ? Colors.white
                              : const Color(0xFF6B7280),
                        ),
                        side: BorderSide(
                          color: _partsSource == 'Shop Supplied'
                              ? const Color(0xFF2563EB)
                              : const Color(0xFFE5E7EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (_warrantyRelevant) ...[
                const Text('Warranty Period',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [1, 3, 6, 12].map((months) {
                    final isSelected = _warrantyMonths == months;
                    return ChoiceChip(
                      label: Text(months == 1 ? '1 month' : '$months months'),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _warrantyMonths = months),
                      selectedColor: const Color(0xFF166534),
                      backgroundColor: const Color(0xFFF9FAFB),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF6B7280),
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF166534)
                            : const Color(0xFFE5E7EB),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('Warranty Terms',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151))),
                const SizedBox(height: 6),
                TextField(
                  controller: _warrantyTermsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'What does this warranty cover?',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const Text('Assigned Technician',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151))),
              const SizedBox(height: 6),
              _buildTechnicianField(),
              const SizedBox(height: 16),

              Text(
                _selectedStatus == 'Completed'
                    ? 'Service Notes (required — what the technician did)'
                    : _noteRequired
                        ? 'Notes / Remarks (required)'
                        : 'Notes / Remarks (optional — a template message is used)',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151)),
              ),
              if (_selectedStatus == 'Completed') ...[
                const SizedBox(height: 4),
                const Text(
                  'Based on the technician\'s verbal report — this will '
                  'appear in the service record and be visible to the customer.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              ],
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _selectedStatus == 'Completed'
                      ? 'e.g. Checked and cleaned the compressor, replaced '
                          'the capacitor. Now working properly.'
                      : _noteRequired
                          ? 'e.g. Checked the compressor, needs a new fan motor...'
                          : 'Optional — extra details to add to the template message',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text('Appliance Photo (optional)',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151))),
              const SizedBox(height: 6),
              if (_selectedImage != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _selectedImage!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                )
              else
                InkWell(
                  onTap: _pickPhoto,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.add_a_photo_outlined,
                            color: Color(0xFF9CA3AF), size: 24),
                        SizedBox(height: 6),
                        Text(
                          'Tap to add a photo',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('I-update at Notify Customer'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewRequestSheet extends StatefulWidget {
  final String docId;
  final String trackingId;
  final String name;
  final String contactNumber;
  final String address;
  final String applianceType;
  final String problemDescription;
  final String? initialPhotoUrl;

  const _ReviewRequestSheet({
    required this.docId,
    required this.trackingId,
    required this.name,
    required this.contactNumber,
    required this.address,
    required this.applianceType,
    required this.problemDescription,
    this.initialPhotoUrl,
  });

  @override
  State<_ReviewRequestSheet> createState() => _ReviewRequestSheetState();
}

class _ReviewRequestSheetState extends State<_ReviewRequestSheet> {
  final FirestoreService _firestoreService = FirestoreService();
  final SmsService _smsService = SmsService();
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _decide(String newStatus) async {
    if (newStatus == 'Declined' && _noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a reason for declining.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _firestoreService.updateRepairStatus(
        docId: widget.docId,
        trackingId: widget.trackingId,
        newStatus: newStatus,
        note: _noteController.text,
      );

      final shopInfoDoc = await FirebaseFirestore.instance
          .collection('shopSettings')
          .doc('config')
          .get();
      final shopName = shopInfoDoc.data()?['shopName'] ?? 'RepairTrack';

      await _smsService.sendStatusUpdateSms(
        shopName: shopName,
        contactNumber: widget.contactNumber,
        trackingId: widget.trackingId,
        applianceType: widget.applianceType,
        newStatus: newStatus,
        note: _noteController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'Accepted'
                  ? 'Request accepted and customer notified.'
                  : 'Request declined and customer notified.',
            ),
            backgroundColor: newStatus == 'Accepted'
                ? const Color(0xFF166534)
                : const Color(0xFF7F1D1D),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9CA3AF))),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        widget.initialPhotoUrl != null && widget.initialPhotoUrl!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Pending — Need Review',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Review Request — ${widget.trackingId}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),

              if (hasPhoto) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    widget.initialPhotoUrl!,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 160,
                        alignment: Alignment.center,
                        child:
                            const CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      alignment: Alignment.center,
                      color: const Color(0xFFF3F4F6),
                      child: const Text('Unable to load photo'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              _buildDetailRow(
                  Icons.person_outline, 'Customer', widget.name),
              _buildDetailRow(
                  Icons.phone_outlined, 'Contact', widget.contactNumber),
              _buildDetailRow(
                  Icons.location_on_outlined, 'Address', widget.address),
              _buildDetailRow(
                  Icons.kitchen_outlined, 'Appliance', widget.applianceType),
              _buildDetailRow(Icons.description_outlined, 'Problem',
                  widget.problemDescription),

              const SizedBox(height: 12),
              const Text('Remarks',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151))),
              const SizedBox(height: 6),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Optional kapag Accept • Required kapag Decline (reason)',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSubmitting ? null : () => _decide('Declined'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF991B1B),
                        side: const BorderSide(color: Color(0xFF991B1B)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isSubmitting ? null : () => _decide('Accepted'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Accept'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrCodeDialog extends StatefulWidget {
  final String trackingId;
  final String customerName;

  const _QrCodeDialog({
    required this.trackingId,
    required this.customerName,
  });

  @override
  State<_QrCodeDialog> createState() => _QrCodeDialogState();
}

class _QrCodeDialogState extends State<_QrCodeDialog> {
  final GlobalKey _qrBoundaryKey = GlobalKey();
  bool _isSaving = false;

  String get _qrData => 'repairtrack://track/${widget.trackingId}';

  Future<void> _downloadQr() async {
    setState(() => _isSaving = true);
    try {
      final boundary = _qrBoundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Unable to convert the QR image to PNG.');
      }
      final bytes = byteData.buffer.asUint8List();
      final fileName = 'QR_${widget.trackingId}.png';

      if (kIsWeb) {
        downloadBytesAsFile(bytes, fileName);
      } else {
        await Share.shareXFiles(
          [XFile.fromData(bytes, name: fileName, mimeType: 'image/png')],
          text: 'RepairTrack QR Code — ${widget.trackingId}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download QR: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle,
                color: Color(0xFF166534), size: 32),
            const SizedBox(height: 8),
            Text(
              widget.customerName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF111827),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              widget.trackingId,
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 1,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            RepaintBoundary(
              key: _qrBoundaryKey,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: QrImageView(
                  data: _qrData,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan to view the full service record',
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _qrData,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    color: const Color(0xFF6B7280),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Copy',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _qrData));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('QR data copied to clipboard.'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _downloadQr,
                    icon: _isSaving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.download, size: 18),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// ── Settings Page (v2 — icon-edit pattern, no large               ─
//    buttons, auto-populated shop info, dropdown notification       ─
//    settings with pre-filled default SMS templates)                ─
// ══════════════════════════════════════════════════════════════════
// Only 4 sections now: Shop/Business Info, Account/Profile,
// Notifications, Data & Security. App Info was removed (merged
// below as a simple footer) and QR Code Settings was removed (not
// needed — the QR should be permanent as part of the service record).
//
// Design pattern: instead of a large "Save"/"Change Password"
// button always on display, there's a small edit icon (pencil)
// next to each field/section. When tapped, it opens the editable
// form (dialog or inline) — cleaner look and less confusing.
//
// Shop Name: automatically pulled from when the shop profile was
// first created (entered during admin registration/setup) — no
// longer a blank form that needs to be filled out again; there's
// just an edit icon if you want to change it.
//
// Notification Settings: dropdown/accordion per status. Each status
// has a DEFAULT scripted message (taken from the same templates in
// sms_service.dart _buildMessage()) — no longer a blank editor.
// There's just an edit icon next to it to customize if the admin wants.

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _settingsStorageService = StorageService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShopInfoSection(storageService: _settingsStorageService),
            const SizedBox(height: 20),
            const _AccountSettingsSection(),
            const SizedBox(height: 20),
            const _NotificationSettingsSection(),
            const SizedBox(height: 20),
            const _DataSecuritySection(),
            const SizedBox(height: 20),
            const _AppInfoSettingsSection(),
          ],
        ),
      ),
    );
  }
}

// ── Shared section shell ─────────────────────────────────────────
class _SettingsPageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _SettingsPageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kBrand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _kBrand, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _kTextDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: _kTextGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Reusable "label + value + edit pencil icon" row — replaces the
/// old large Save/Change buttons. When the pencil is tapped, it
/// calls the onEdit callback (usually opens a dialog).
class _SettingsInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onEdit;
  final bool isPlaceholder;

  const _SettingsInfoRow({
    required this.label,
    required this.value,
    required this.onEdit,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kTextGray,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isPlaceholder ? _kTextGray : _kTextDark,
                    fontStyle:
                        isPlaceholder ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kBrand.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_outlined, size: 16, color: _kBrand),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple dialog helper — a single text field, Cancel/Save. Reused
/// throughout for all the "edit icon → dialog" patterns across the
/// Settings page.
Future<String?> _showEditFieldDialog(
  BuildContext context, {
  required String title,
  required String initialValue,
  String? hint,
  int maxLines = 1,
  TextInputType? keyboardType,
}) {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: _settingsFieldDecoration(hint: hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          style: ElevatedButton.styleFrom(
              backgroundColor: _kBrand, foregroundColor: Colors.white),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

InputDecoration _settingsFieldDecoration({String? hint}) => InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kCardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kCardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _kBrand, width: 1.5),
      ),
    );

// ══════════════════════════════════════════════════════════════════
// 1. Shop/Business Info — auto-populated, just an edit icon per field
// ══════════════════════════════════════════════════════════════════

class _ShopInfoSection extends StatefulWidget {
  final StorageService storageService;
  const _ShopInfoSection({required this.storageService});

  @override
  State<_ShopInfoSection> createState() => _ShopInfoSectionState();
}

class _ShopInfoSectionState extends State<_ShopInfoSection> {
  String _shopName = '';
  String _address = '';
  String _contactNumber = '';
  String _businessHours = '';
  String? _logoUrl;
  bool _isLoading = true;
  bool _isUploadingLogo = false;
  String? _loadError;

  DocumentReference get _docRef =>
      FirebaseFirestore.instance.collection('shopSettings').doc('config');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final doc = await _docRef.get();
      if (!mounted) return;
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _shopName = data['shopName'] ?? '';
          _address = data['address'] ?? '';
          _contactNumber = data['contactNumber'] ?? '';
          _businessHours = data['businessHours'] ?? '';
          _logoUrl = data['logoUrl'] as String?;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Unable to load shop info: $e';
      });
    }
  }

  Future<void> _saveField(String field, String value) async {
    try {
      await _docRef.set({
        field: value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Na-save.'),
              backgroundColor: Color(0xFF16A34A)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _editShopName() async {
    final result = await _showEditFieldDialog(
      context,
      title: 'Shop Name',
      initialValue: _shopName,
      hint: 'e.g. RepairTrack Shop',
    );
    if (result != null && result != _shopName) {
      setState(() => _shopName = result);
      await _saveField('shopName', result);
    }
  }

  Future<void> _editAddress() async {
    final result = await _showEditFieldDialog(
      context,
      title: 'Address',
      initialValue: _address,
      hint: 'e.g. Calatagan, Virac, Catanduanes',
      maxLines: 2,
    );
    if (result != null && result != _address) {
      setState(() => _address = result);
      await _saveField('address', result);
    }
  }

  Future<void> _editContactNumber() async {
    final result = await _showEditFieldDialog(
      context,
      title: 'Contact Number',
      initialValue: _contactNumber,
      hint: 'e.g. 09171234567',
      keyboardType: TextInputType.phone,
    );
    if (result != null && result != _contactNumber) {
      setState(() => _contactNumber = result);
      await _saveField('contactNumber', result);
    }
  }

  Future<void> _editBusinessHours() async {
    final result = await _showEditFieldDialog(
      context,
      title: 'Business Hours',
      initialValue: _businessHours,
      hint: 'e.g. Mon–Sat, 8:00 AM – 5:00 PM',
    );
    if (result != null && result != _businessHours) {
      setState(() => _businessHours = result);
      await _saveField('businessHours', result);
    }
  }

  Future<void> _pickAndUploadLogo() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _isUploadingLogo = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await widget.storageService.uploadPhoto(
        bytes: bytes,
        trackingId: 'shop-logo',
      );
      await _docRef.set({'logoUrl': url}, SetOptions(merge: true));
      if (mounted) {
        setState(() {
          _logoUrl = url;
          _isUploadingLogo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingLogo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsPageCard(
      title: 'Shop / Business Info',
      subtitle: 'This is shown in customer notifications and receipts',
      icon: Icons.storefront_outlined,
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : _loadError != null
              ? _SettingsErrorRetry(message: _loadError!, onRetry: _load)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _isUploadingLogo ? null : _pickAndUploadLogo,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: _kBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _kCardBorder),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _isUploadingLogo
                                ? const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  )
                                : (_logoUrl != null && _logoUrl!.isNotEmpty)
                                    ? Image.network(_logoUrl!,
                                        fit: BoxFit.cover)
                                    : Icon(Icons.storefront_outlined,
                                        color: _kTextGray, size: 28),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _shopName.isEmpty ? 'No shop name' : _shopName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _shopName.isEmpty
                                      ? _kTextGray
                                      : _kTextDark,
                                  fontStyle: _shopName.isEmpty
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap the logo to change it',
                                style: const TextStyle(
                                    fontSize: 11, color: _kTextGray),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _editShopName,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _kBrand.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_outlined,
                                size: 16, color: _kBrand),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28, color: _kCardBorder),
                    _SettingsInfoRow(
                      label: 'Address',
                      value: _address.isEmpty ? 'Not yet set' : _address,
                      isPlaceholder: _address.isEmpty,
                      onEdit: _editAddress,
                    ),
                    const Divider(height: 1, color: _kCardBorder),
                    _SettingsInfoRow(
                      label: 'Contact Number',
                      value: _contactNumber.isEmpty
                          ? 'Not yet set'
                          : _contactNumber,
                      isPlaceholder: _contactNumber.isEmpty,
                      onEdit: _editContactNumber,
                    ),
                    const Divider(height: 1, color: _kCardBorder),
                    _SettingsInfoRow(
                      label: 'Business Hours',
                      value: _businessHours.isEmpty
                          ? 'Not yet set'
                          : _businessHours,
                      isPlaceholder: _businessHours.isEmpty,
                      onEdit: _editBusinessHours,
                    ),
                  ],
                ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 2. Account / Profile Settings — edit icons, no large button
// ══════════════════════════════════════════════════════════════════

class _AccountSettingsSection extends StatefulWidget {
  const _AccountSettingsSection();

  @override
  State<_AccountSettingsSection> createState() =>
      _AccountSettingsSectionState();
}

class _AccountSettingsSectionState extends State<_AccountSettingsSection> {
  String _name = '';
  String _email = '';
  String? _photoUrl;
  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  String? _loadError;
  final _storageService = StorageService();

  DocumentReference? get _docRef {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('admins').doc(uid);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    final ref = _docRef;
    if (ref == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await ref.get();
      if (!mounted) return;
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _name = data['name'] ?? '';
          _email =
              data['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '';
          _photoUrl = data['profilePhotoUrl'] as String?;
          _isLoading = false;
        });
      } else {
        setState(() {
          _email = FirebaseAuth.instance.currentUser?.email ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Unable to load account info: $e';
      });
    }
  }

  Future<void> _editName() async {
    final result = await _showEditFieldDialog(
      context,
      title: 'Admin Name',
      initialValue: _name,
      hint: 'Your full name',
    );
    if (result == null || result == _name) return;

    final ref = _docRef;
    if (ref == null) return;
    try {
      await ref.set({'name': result}, SetOptions(merge: true));
      if (mounted) {
        setState(() => _name = result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pangalan na-update.'),
              backgroundColor: Color(0xFF16A34A)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 85,
    );
    if (picked == null) return;

    final ref = _docRef;
    if (ref == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await _storageService.uploadPhoto(
        bytes: bytes,
        trackingId: 'admin-profile-${FirebaseAuth.instance.currentUser?.uid}',
      );
      await ref.set({'profilePhotoUrl': url}, SetOptions(merge: true));
      if (mounted) {
        setState(() {
          _photoUrl = url;
          _isUploadingPhoto = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  Future<void> _requestPasswordReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Change Password'),
        content: Text(
          'We\'ll send a password reset link to $_email. '
          'Follow the link to set a new password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kBrand, foregroundColor: Colors.white),
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );

    if (confirmed != true || _email.isEmpty) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset link sent to $_email.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsPageCard(
      title: 'Account / Profile Settings',
      subtitle: 'Your admin name, email, and profile photo',
      icon: Icons.person_outline,
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : _loadError != null
              ? _SettingsErrorRetry(message: _loadError!, onRetry: _load)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap:
                              _isUploadingPhoto ? null : _pickAndUploadPhoto,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _kBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: _kCardBorder),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _isUploadingPhoto
                                ? const Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  )
                                : (_photoUrl != null && _photoUrl!.isNotEmpty)
                                    ? Image.network(_photoUrl!,
                                        fit: BoxFit.cover)
                                    : Icon(Icons.person, color: _kTextGray),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tap the photo to change it',
                            style: const TextStyle(
                                fontSize: 11, color: _kTextGray),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28, color: _kCardBorder),
                    _SettingsInfoRow(
                      label: 'Admin Name',
                      value: _name.isEmpty ? 'Not yet set' : _name,
                      isPlaceholder: _name.isEmpty,
                      onEdit: _editName,
                    ),
                    const Divider(height: 1, color: _kCardBorder),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Email Address',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _kTextGray,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _email,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _kTextDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: _kCardBorder),
                    _SettingsInfoRow(
                      label: 'Password',
                      value: '••••••••',
                      onEdit: _requestPasswordReset,
                    ),
                  ],
                ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 3. Notification Settings — dropdown/accordion per status, with
//    pre-filled default SMS templates from sms_service.dart
// ══════════════════════════════════════════════════════════════════

const List<String> _kNotifiableStatuses = [
  'Accepted',
  'In Home',
  'In Shop',
  'In Process',
  'Waiting for Parts',
  'Completed',
  'Declined',
];

/// Default scripted messages — follows the same template used in
/// sms_service.dart _buildMessage(), to keep the SMS tone consistent
/// even before the admin customizes it. Placeholders:
/// {trackingId}, {applianceType}, {technician}, {note}. The
/// scheduledDate is not included here because it's dynamic and
/// depends on the actual time — it stays handled by SmsService at runtime.
const Map<String, String> _kDefaultSmsTemplates = {
  'Accepted':
      'RepairTrack: Your repair request (ID: {trackingId}) for your '
          '{applianceType} has been ACCEPTED. Technician {technician} will '
          'be assisting you.',
  'In Home':
      'RepairTrack: Technician {technician} will visit your home to '
          'repair your {applianceType}. Please be available at that time.',
  'In Shop':
      'RepairTrack: Your {applianceType} (ID: {trackingId}) has been '
          'brought to our shop for repair. Assigned to technician '
          '{technician}. We will notify you once it is ready for pickup.',
  'In Process':
      'RepairTrack: Your {applianceType} repair (ID: {trackingId}) is '
          'now IN PROCESS.',
  'Waiting for Parts':
      'RepairTrack: Your {applianceType} repair (ID: {trackingId}) is '
          'currently waiting for parts.',
  'Completed':
      'RepairTrack: Great news! Your {applianceType} repair '
          '(ID: {trackingId}) is now COMPLETE and ready for pickup. Thank '
          'you for trusting RepairTrack!',
  'Declined':
      'RepairTrack: We\'re sorry, your repair request (ID: {trackingId}) '
          'for your {applianceType} has been DECLINED.',
};

class _NotificationSettingsSection extends StatefulWidget {
  const _NotificationSettingsSection();

  @override
  State<_NotificationSettingsSection> createState() =>
      _NotificationSettingsSectionState();
}

class _NotificationSettingsSectionState
    extends State<_NotificationSettingsSection> {
  final Map<String, bool> _smsToggles = {
    for (final s in _kNotifiableStatuses) s: true,
  };
  final Map<String, String> _customTemplates = {};
  bool _emailEnabled = false;
  bool _isLoading = true;
  String? _loadError;
  String? _expandedStatus;

  DocumentReference get _settingsDocRef => FirebaseFirestore.instance
      .collection('notificationSettings')
      .doc('config');

  DocumentReference get _templatesDocRef =>
      FirebaseFirestore.instance.collection('smsTemplates').doc('config');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final settingsDoc = await _settingsDocRef.get();
      final templatesDoc = await _templatesDocRef.get();
      if (!mounted) return;

      if (settingsDoc.exists) {
        final data = settingsDoc.data() as Map<String, dynamic>;
        final smsMap = data['smsEnabledByStatus'] as Map<String, dynamic>?;
        if (smsMap != null) {
          for (final s in _kNotifiableStatuses) {
            _smsToggles[s] = smsMap[s] as bool? ?? true;
          }
        }
        _emailEnabled = data['emailEnabled'] as bool? ?? false;
      }

      if (templatesDoc.exists) {
        final data = templatesDoc.data() as Map<String, dynamic>;
        for (final s in _kNotifiableStatuses) {
          final custom = data[s] as String?;
          if (custom != null && custom.trim().isNotEmpty) {
            _customTemplates[s] = custom;
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Unable to load notification settings: $e';
      });
    }
  }

  Future<void> _toggleSms(String status, bool value) async {
    setState(() => _smsToggles[status] = value);
    try {
      await _settingsDocRef.set({
        'smsEnabledByStatus': _smsToggles,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _toggleEmail(bool value) async {
    setState(() => _emailEnabled = value);
    try {
      await _settingsDocRef.set({
        'emailEnabled': value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _editTemplate(String status) async {
    final currentValue =
        _customTemplates[status] ?? _kDefaultSmsTemplates[status] ?? '';

    final controller = TextEditingController(text: currentValue);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('SMS Template — $status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Placeholders: {trackingId}, {applianceType}, {technician}, {note}',
              style: TextStyle(fontSize: 11, color: _kTextGray),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: _settingsFieldDecoration(
                  hint: 'Custom message for this status'),
            ),
          ],
        ),
        actions: [
          if (_customTemplates.containsKey(status))
            TextButton(
              onPressed: () => Navigator.pop(context, '__reset_to_default__'),
              child: const Text('Reset to Default',
                  style: TextStyle(color: Color(0xFFDC2626))),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kBrand, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      if (result == '__reset_to_default__') {
        await _templatesDocRef.set(
            {status: FieldValue.delete()}, SetOptions(merge: true));
        if (mounted) {
          setState(() => _customTemplates.remove(status));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reset "$status" to default.')),
          );
        }
      } else {
        await _templatesDocRef.set({status: result}, SetOptions(merge: true));
        if (mounted) {
          setState(() => _customTemplates[status] = result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Template for "$status" saved.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsPageCard(
      title: 'Notification Settings',
      subtitle: 'SMS templates (Semaphore) and which events trigger sending',
      icon: Icons.notifications_outlined,
      child: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : _loadError != null
              ? _SettingsErrorRetry(message: _loadError!, onRetry: _load)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SMS per Status',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kTextDark),
                    ),
                    const SizedBox(height: 4),
                    ..._kNotifiableStatuses.map((status) {
                      final isExpanded = _expandedStatus == status;
                      final isCustomized =
                          _customTemplates.containsKey(status);
                      final previewText = _customTemplates[status] ??
                          _kDefaultSmsTemplates[status] ??
                          '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: _kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kCardBorder),
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => setState(() {
                                _expandedStatus =
                                    isExpanded ? null : status;
                              }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(status,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: _kTextDark)),
                                          if (isCustomized) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _kBrand.withValues(
                                                    alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        8),
                                              ),
                                              child: const Text(
                                                'Custom',
                                                style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: _kBrand),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _smsToggles[status] ?? true,
                                      activeColor: _kBrand,
                                      onChanged: (v) => _toggleSms(status, v),
                                    ),
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      color: _kTextGray,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isExpanded)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    12, 0, 12, 12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Divider(
                                        height: 1, color: _kCardBorder),
                                    const SizedBox(height: 10),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            previewText,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: _kTextGray,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: () => _editTemplate(status),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: _kBrand.withValues(
                                                  alpha: 0.08),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                                Icons.edit_outlined,
                                                size: 16,
                                                color: _kBrand),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: _kBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kCardBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Email Notifications',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _kTextDark)),
                                Text(
                                  'If you also have email notifications set up',
                                  style: const TextStyle(
                                      fontSize: 11, color: _kTextGray),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _emailEnabled,
                            activeColor: _kBrand,
                            onChanged: _toggleEmail,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 4. Data & Security
// ══════════════════════════════════════════════════════════════════

class _DataSecuritySection extends StatefulWidget {
  const _DataSecuritySection();

  @override
  State<_DataSecuritySection> createState() => _DataSecuritySectionState();
}

class _DataSecuritySectionState extends State<_DataSecuritySection> {
  bool _isExporting = false;

  Future<void> _exportRepairRequests() async {
    setState(() => _isExporting = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('repairRequests')
          .orderBy('createdAt', descending: true)
          .get();

      final records = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['docId'] = doc.id;
        data.updateAll((key, value) {
          if (value is Timestamp) return value.toDate().toIso8601String();
          if (value is List) {
            return value.map((e) {
              if (e is Map) {
                final copy = Map<String, dynamic>.from(e);
                copy.updateAll((k, v) =>
                    v is Timestamp ? v.toDate().toIso8601String() : v);
                return copy;
              }
              return e;
            }).toList();
          }
          return value;
        });
        return data;
      }).toList();

      final jsonStr = const JsonEncoder.withIndent('  ').convert(records);

      if (mounted) {
        setState(() => _isExporting = false);
        _showExportDialog(jsonStr, records.length);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _showExportDialog(String jsonStr, int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Export — $count repair record(s)'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              jsonStr,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard.')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy to Clipboard'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kBrand, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsPageCard(
      title: 'Data & Security',
      subtitle: 'Backup/export data of repair records',
      icon: Icons.security_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsPageTile(
            icon: Icons.download_outlined,
            label: 'Export Repair Data',
            subtitle: 'Export all repair requests as JSON',
            trailing: _isExporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right_rounded,
                    size: 18, color: _kTextGray),
            onTap: _isExporting ? null : _exportRepairRequests,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// 5. App Info (footer only, simple)
// ══════════════════════════════════════════════════════════════════

class _AppInfoSettingsSection extends StatelessWidget {
  const _AppInfoSettingsSection();

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService().logout();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showInfoDialog(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(title),
        content: Text(body, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsPageCard(
      title: 'App Info',
      subtitle: 'Version, terms, at contact/support info',
      icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SettingsPageTile(
            icon: Icons.info_outline,
            label: 'App Version',
            subtitle: '1.0.0',
            trailing: SizedBox.shrink(),
            onTap: null,
          ),
          _SettingsPageTile(
            icon: Icons.description_outlined,
            label: 'Terms of Service',
            subtitle: 'Basic terms of use for RepairTrack',
            trailing: const Icon(Icons.chevron_right_rounded,
                size: 18, color: _kTextGray),
            onTap: () => _showInfoDialog(
              context,
              'Terms of Service',
              'RepairTrack is a capstone/pilot app for tracking '
                  'appliance repair requests. By using it, you agree '
                  'to use it responsibly and not for any unlawful '
                  'purposes.',
            ),
          ),
          _SettingsPageTile(
            icon: Icons.privacy_tip_outlined,
            label: 'Privacy Policy',
            subtitle: 'How your data is used',
            trailing: const Icon(Icons.chevron_right_rounded,
                size: 18, color: _kTextGray),
            onTap: () => _showInfoDialog(
              context,
              'Privacy Policy',
              'Customer details (name, address, contact number) are '
                  'used only for processing repair requests and are not '
                  'shared with third parties except the SMS provider for '
                  'notifications.',
            ),
          ),
          _SettingsPageTile(
            icon: Icons.support_agent_outlined,
            label: 'Contact / Support',
            subtitle: 'For help with the app',
            trailing: const Icon(Icons.chevron_right_rounded,
                size: 18, color: _kTextGray),
            onTap: () => _showInfoDialog(
              context,
              'Contact / Support',
              'For issues or questions about the RepairTrack app, '
                  'please contact the developer/admin of this system.',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmSignOut(context),
              icon:
                  const Icon(Icons.logout, size: 18, color: Color(0xFFDC2626)),
              label: const Text('Sign Out',
                  style: TextStyle(color: Color(0xFFDC2626))),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: const BorderSide(color: Color(0xFFFECACA)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared row tile ──────────────────────────────────────────────
class _SettingsPageTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsPageTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _kBrand),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kTextDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: _kTextGray),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// Reusable error + retry widget for sections that fail to
/// load (e.g. Firestore rules issue, no internet, etc.) — so
/// there's no "silent hang"; the admin immediately sees an
/// error message and a retry button.
class _SettingsErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _SettingsErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Color(0xFFDC2626), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Retry'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kBrand,
            side: const BorderSide(color: _kCardBorder),
          ),
        ),
      ],
    );
  }
}
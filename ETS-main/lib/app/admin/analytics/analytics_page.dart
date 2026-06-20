import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:malhar_ets/shared/controllers/event_controller.dart';
import 'package:malhar_ets/shared/controllers/participation_controller.dart';
import 'package:malhar_ets/shared/controllers/contingent_controller.dart';
import 'package:malhar_ets/shared/controllers/department_controller.dart';
import 'package:malhar_ets/shared/controllers/audit_log_controller.dart';
import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/shared/models/event.dart';
import 'package:malhar_ets/shared/models/department.dart';
import 'package:malhar_ets/shared/models/audit_log.dart';
import 'package:malhar_ets/utils/app_feedback.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/ambient_glow_background.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  int _activeTab = 0; // 0 = Charts, 1 = Leaderboard, 2 = Logs
  List<MapEntry<String, double>> _contingentScores = [];
  List<MapEntry<String, double>> _departmentScores = [];

  @override
  void initState() {
    super.initState();
    // Load all data on init
    EventController().loadEvents();
    ParticipationController().loadParticipations();
    ContingentController().loadContingents();
    DepartmentController().loadDepartments();
    AuditLogController().loadAuditLogs();
  }

  void _calculateData() {
    final participations = ParticipationController().participations;
    final contingents = ContingentController().contingents;
    final events = EventController().events;
    final departments = DepartmentController().departments;

    // 1. Contingent scores
    final Map<int, double> contScoresMap = {};
    for (var p in participations) {
      if (p.marksScored != -1) {
        contScoresMap.update(p.contingentId, (v) => v + p.marksScored, ifAbsent: () => p.marksScored.toDouble());
      }
    }

    final List<MapEntry<String, double>> contEntries = [];
    for (var entry in contScoresMap.entries) {
      try {
        final contingent = contingents.firstWhere((c) => c.contingentId == entry.key);
        if (contingent.contingentCode.isNotEmpty) {
          contEntries.add(MapEntry(contingent.contingentCode, entry.value));
        }
      } catch (_) {
        contEntries.add(MapEntry('ID: ${entry.key}', entry.value));
      }
    }
    contEntries.sort((a, b) => b.value.compareTo(a.value));
    _contingentScores = contEntries;

    // 2. Department scores
    final Map<int, double> deptScoresMap = {};
    for (var p in participations) {
      if (p.marksScored != -1) {
        try {
          final event = events.firstWhere((e) => e.eventId == p.eventId);
          deptScoresMap.update(event.departmentId, (v) => v + p.marksScored, ifAbsent: () => p.marksScored.toDouble());
        } catch (_) {}
      }
    }

    final List<MapEntry<String, double>> deptEntries = [];
    for (var entry in deptScoresMap.entries) {
      try {
        final dept = departments.firstWhere((d) => d.id == entry.key);
        final label = dept.code ?? dept.name;
        if (label.isNotEmpty) {
          deptEntries.add(MapEntry(label, entry.value));
        }
      } catch (_) {
        deptEntries.add(MapEntry('Dept ID: ${entry.key}', entry.value));
      }
    }
    deptEntries.sort((a, b) => b.value.compareTo(a.value));
    _departmentScores = deptEntries;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PageRefreshController.refreshNotifier,
      builder: (context, value, child) {
        _calculateData();

        return AmbientGlowBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text('Analytics', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTabSelector(),
                  if (_activeTab == 0) ...[
                    _topContingentsChart(),
                    const SizedBox(height: 24),
                    _departmentParticipationChart(),
                  ] else if (_activeTab == 1) ...[
                    _buildLeaderboardView(),
                  ] else ...[
                    _buildAuditLogsView(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabSelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(80),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withAlpha(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(0, 'Charts', Icons.bar_chart),
          ),
          Expanded(
            child: _buildTabButton(1, 'Leaderboard', Icons.emoji_events),
          ),
          Expanded(
            child: _buildTabButton(2, 'Logs', Icons.history),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title, IconData icon) {
    final bool isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.black : AppColors.textWhite,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isSelected ? AppColors.black : AppColors.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardView() {
    if (_contingentScores.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events_outlined, size: 64, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                'No Scores Recorded Yet',
                style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _contingentScores.length,
      itemBuilder: (context, index) {
        final entry = _contingentScores[index];
        final rank = index + 1;

        Color rankColor = AppColors.textWhite;
        Color startGlowColor = Colors.transparent;
        if (rank == 1) {
          rankColor = const Color(0xFFFFD700); // Gold
          startGlowColor = const Color(0xFFFFD700);
        } else if (rank == 2) {
          rankColor = const Color(0xFFC0C0C0); // Silver
          startGlowColor = const Color(0xFFC0C0C0);
        } else if (rank == 3) {
          rankColor = const Color(0xFFCD7F32); // Bronze
          startGlowColor = const Color(0xFFCD7F32);
        }

        final bool isTop3 = rank <= 3;

        Widget rankWidget;
        if (isTop3) {
          rankWidget = Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rankColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: rankColor.withAlpha(80),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$rank',
                style: GoogleFonts.montserrat(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        } else {
          rankWidget = Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isTop3
                ? Color.lerp(startGlowColor.withAlpha(20), Colors.black, 0.8)
                : Colors.black.withAlpha(120),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTop3 ? rankColor.withAlpha(150) : AppColors.primary.withAlpha(20),
              width: isTop3 ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (isTop3)
                BoxShadow(
                  color: rankColor.withAlpha(30),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: ListTile(
            leading: SizedBox(
              width: 40,
              child: Center(
                child: rankWidget,
              ),
            ),
            title: Text(
              entry.key,
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: rankColor,
                fontSize: 16,
              ),
            ),
            trailing: Text(
              '${entry.value.toInt()} pts',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuditLogsView() {
    final controller = AuditLogController();
    final logs = controller.auditLogs;
    final error = controller.errorMessage;

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Failed to Load Logs',
                style: GoogleFonts.montserrat(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                error,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => controller.loadAuditLogs(),
                child: Text('Retry', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      );
    }

    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history_toggle_off_outlined, size: 64, color: Colors.white38),
              const SizedBox(height: 16),
              Text(
                'No Changes Recorded Yet',
                style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.secondary,
      onRefresh: () async {
        await AuditLogController().loadAuditLogs();
      },
      child: ListView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];
          final timestamp = DateFormat('dd MMM, hh:mm a').format(log.createdAt.toLocal());
          final description = _formatLogDescription(log);

          Color actionColor;
          String actionText = log.action;
          if (log.action == 'INSERT') {
            actionColor = AppColors.success;
          } else if (log.action == 'UPDATE') {
            actionColor = AppColors.accent;
          } else if (log.action == 'DELETE') {
            actionColor = AppColors.error;
          } else {
            actionColor = AppColors.primary;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(120),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withAlpha(10),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: actionColor.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: actionColor.withAlpha(120), width: 1),
                      ),
                      child: Text(
                        actionText,
                        style: GoogleFonts.montserrat(
                          color: actionColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      timestamp,
                      style: GoogleFonts.montserrat(
                        color: Colors.white38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: GoogleFonts.montserrat(
                    color: AppColors.textWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      'By: ${log.changedBy}',
                      style: GoogleFonts.montserrat(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatLogDescription(AuditLog log) {
    final Map<String, dynamic> data = log.newData ?? log.oldData ?? {};
    final int? contingentId = data['contingent_id'];
    final int? eventId = data['event_id'];

    final contingentCode = contingentId != null
        ? (ContingentController().getContingentById(contingentId)?.contingentCode ?? 'Contingent #$contingentId')
        : 'Unknown Contingent';

    final eventName = eventId != null
        ? (EventController().getEventById(eventId)?.eventName ?? 'Event #$eventId')
        : 'Unknown Event';

    if (log.action == 'INSERT') {
      final marks = data['marks_scored'] ?? 0;
      return '$contingentCode registered for $eventName with score $marks';
    } else if (log.action == 'UPDATE') {
      final oldMarks = log.oldData?['marks_scored'] ?? -1;
      final newMarks = log.newData?['marks_scored'] ?? -1;
      if (oldMarks != newMarks) {
        return '$contingentCode score in $eventName changed from $oldMarks to $newMarks';
      }
      return '$contingentCode entry in $eventName updated';
    } else if (log.action == 'DELETE') {
      return '$contingentCode participation in $eventName was deleted';
    }
    return 'Action ${log.action} on participation #${log.recordId}';
  }

  Widget _topContingentsChart() {
    final List<MapEntry<String, double>> top5 = _contingentScores.take(5).toList();
    if (top5.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text('No contingent data available', style: GoogleFonts.montserrat(color: Colors.white38)),
      );
    }

    final List<BarChartGroupData> bars = List.generate(top5.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: top5[i].value,
            color: AppColors.primary,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          )
        ],
      );
    });

    final List<String> labels = top5.map((e) => e.key).toList();

    return Card(
      color: Colors.black.withAlpha(120),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top 5 Contingents', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textWhite)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: bars,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${labels[groupIndex]}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: '${rod.toY.toInt()} pts',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int idx = value.toInt();
                          if (idx >= 0 && idx < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                labels[idx],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _departmentParticipationChart() {
    final List<MapEntry<String, double>> top5 = _departmentScores.take(5).toList();
    if (top5.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text('No department data available', style: GoogleFonts.montserrat(color: Colors.white38)),
      );
    }

    final List<BarChartGroupData> bars = List.generate(top5.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: top5[i].value,
            color: AppColors.accent,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          )
        ],
      );
    });

    final List<String> labels = top5.map((e) => e.key).toList();

    return Card(
      color: Colors.black.withAlpha(120),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Department Participation', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textWhite)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: bars,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${labels[groupIndex]}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: '${rod.toY.toInt()} pts',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final int idx = value.toInt();
                          if (idx >= 0 && idx < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                labels[idx],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malhar_ets/shared/controllers/event_controller.dart';
import 'package:malhar_ets/shared/controllers/participation_controller.dart';
import 'package:malhar_ets/shared/controllers/contingent_controller.dart';
import 'package:malhar_ets/shared/controllers/department_controller.dart';
import 'package:malhar_ets/utils/app_feedback.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/shared/models/event.dart';
import 'package:malhar_ets/helpers/ambient_glow_background.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  // Chart data
  List<BarChartGroupData> _contingentBars = [];
  List<BarChartGroupData> _departmentBars = [];
  @override
  void initState() {
    super.initState();
    // Load all required data then compute charts
    Future.wait([
      EventController().loadEvents(),
      ParticipationController().loadParticipations(),
      ContingentController().loadContingents(),
      DepartmentController().loadDepartments(),
    ]).then((_) => _computeCharts());
  }

  @override
  Widget build(BuildContext context) {
    return AmbientGlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Analytics', style: GoogleFonts.poppins()),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _topContingentsChart(),
              const SizedBox(height: 32),
              _departmentParticipationChart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topContingentsChart() {
    final bars = _contingentBars.isNotEmpty
        ? _contingentBars
        : List.generate(5, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: ((5 - i) * 10 + 5).toDouble(), color: AppColors.primary)]));

    return Card(
      color: Colors.black.withAlpha(120),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top 5 Contingents', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textWhite)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: bars,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barTouchData: BarTouchData(enabled: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _departmentParticipationChart() {
    final bars = _departmentBars.isNotEmpty
        ? _departmentBars
        : List.generate(5, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: ((i + 1) * 8).toDouble(), color: AppColors.accent)]));
    return Card(
      color: Colors.black.withAlpha(120),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Department Participation', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textWhite)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: bars,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barTouchData: BarTouchData(enabled: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compute chart data from controllers
  void _computeCharts() {
    final contingents = ContingentController().contingents;
    final participations = ParticipationController().participations;
    final events = EventController().events;
    final departments = DepartmentController().departments;

    // Contingent total scores
    final Map<int, int> contingentScores = {};
    for (var p in participations) {
      final int score = p.marksScored ?? 0;
      contingentScores.update(p.contingentId, (v) => v + score, ifAbsent: () => score);
    }
    final List<MapEntry<int, int>> sortedContingents = contingentScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topContingents = sortedContingents.take(5).toList();
    _contingentBars = topContingents.asMap().entries.map((e) {
      final idx = e.key;
      final double score = e.value.value.toDouble();
      return BarChartGroupData(x: idx, barRods: [BarChartRodData(toY: score, color: AppColors.primary, width: 20)]);
    }).toList();

    // Department scores via events
    final Map<int, int> deptScores = {};
    for (var p in participations) {
      Event? event;
      for (var ev in events) {
        if (ev.eventId == p.eventId) {
          event = ev;
          break;
        }
      }
      if (event != null) {
        final int deptId = event.departmentId;
        final int score = p.marksScored ?? 0;
        deptScores.update(deptId, (v) => v + score, ifAbsent: () => score);
      }
    }
    final List<MapEntry<int, int>> sortedDepts = deptScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topDepts = sortedDepts.take(5).toList();
    _departmentBars = topDepts.asMap().entries.map((e) {
      final idx = e.key;
      final double score = e.value.value.toDouble();
      return BarChartGroupData(x: idx, barRods: [BarChartRodData(toY: score, color: AppColors.accent, width: 20)]);
    }).toList();

    setState(() {});
  }

}

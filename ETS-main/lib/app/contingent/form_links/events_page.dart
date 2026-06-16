import 'package:flutter/material.dart';
import 'package:malhar_ets/app/contingent/cards/event_card.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/shared/controllers/event_controller.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/shared/models/department.dart';
import 'package:malhar_ets/shared/models/event.dart';
import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';

class EventsPage extends StatelessWidget {
  final Department department;
  final Contingent contingent;
  const EventsPage({
    required this.department,
    required this.contingent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    List<Event> events =
        EventController().events
            .where((e) => e.departmentId == department.id)
            .toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('${department.code} - ${department.name}'),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.secondary,
        onRefresh: () async {
          if (PageRefreshController.onRefresh != null) {
            PageRefreshController.onRefresh!();
          }
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: EventCard(event: events[index], contingent: contingent),
            );
          },
        ),
      ),
    );
  }
}

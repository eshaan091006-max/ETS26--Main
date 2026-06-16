import 'package:flutter/material.dart';
import 'package:malhar_ets/app/admin/cards/event_card.dart';
import 'package:malhar_ets/app/admin/event/contingents_participated_page.dart';
import 'package:malhar_ets/app/admin/modals/event_modal.dart';
import 'package:malhar_ets/helpers/widgets.dart';
import 'package:malhar_ets/shared/controllers/department_controller.dart';
import 'package:malhar_ets/shared/controllers/event_controller.dart';
import 'package:malhar_ets/shared/controllers/form_link_controller.dart';
import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';
import 'package:malhar_ets/utils/app_feedback.dart';
import 'package:malhar_ets/helpers/animated_card_wrapper.dart';
import 'package:malhar_ets/helpers/empty_state_widget.dart';

class EventManagementPage extends StatefulWidget {
  const EventManagementPage({super.key});

  @override
  State<EventManagementPage> createState() => _EventManagementPageState();
}

class _EventManagementPageState extends State<EventManagementPage> {
  final EventController _eventController = EventController();
  bool isLoading = true;

  String selectedDept = 'All';
  String selectedType = 'All';

  List<String> departments = ['All'];
  final List<String> types = ['All', 'Classic', 'Flagship'];

  @override
  void initState() {
    super.initState();
    _initFilters();
    isLoading = false;
  }

  void _initFilters() {
    final deptSet =
        _eventController.events
            .map(
              (e) =>
                  DepartmentController()
                      .getDepartmentById(e.departmentId.toInt())
                      ?.code ??
                  '',
            )
            .toSet();
    departments = ['All', ...deptSet];
  }

  List filteredEvents() {
    return _eventController.events.where((event) {
      final deptCode =
          DepartmentController()
              .getDepartmentById(event.departmentId.toInt())
              ?.code;
      final deptMatch = selectedDept == 'All' || deptCode == selectedDept;
      final typeMatch =
          selectedType == 'All' ||
          (selectedType == 'Classic' && event.eventType == 0) ||
          (selectedType == 'Flagship' && event.eventType == 1);
      return deptMatch && typeMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        // Filter Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.black.withAlpha(13),
          child: Row(
            children: [
              buildDropdown(
                label: 'Deptartment',
                value: selectedDept,
                options: departments,
                onChanged: (val) => setState(() => selectedDept = val!),
              ),
              const SizedBox(width: 12),
              buildDropdown(
                label: 'Type',
                value: selectedType,
                options: types,
                onChanged: (val) => setState(() => selectedType = val!),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.secondary,
            onRefresh: () async {
              if (PageRefreshController.onRefresh != null) {
                PageRefreshController.onRefresh!();
              }
              await Future.delayed(const Duration(seconds: 1));
            },
            child: ValueListenableBuilder(
              valueListenable: PageRefreshController.refreshNotifier,
              builder: (_, __, ___) {
                final events = filteredEvents();
                return events.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.6,
                          alignment: Alignment.center,
                          child: const EmptyStateWidget(
                            title: 'No Events Found',
                            subtitle: 'Try adjusting your type or department filters.',
                            icon: Icons.event_busy,
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return AnimatedCardWrapper(
                            key: ValueKey(event.eventId),
                            child: GestureDetector(
                              onDoubleTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (_) => ContingentsParticipatedPage(event: event),
                                  ),
                                );
                              },
                            child: EventCard(
                              event: event,
                              onEdit:
                                  () => showEventModal(
                                    context,
                                    event: event,
                                    onSubmit: (updatedEvent, links) async {
                                      await EventController().updateEvent(context, updatedEvent);
                                      await FormLinkController().syncFormLinks(context, updatedEvent.eventId, links);
                                    },
                                  ),
                              onDelete: () {
                                EventController().deleteEvent(context, event.eventId);
                              },
                            ),
                          ),
                        );
                      },
                    );
            },
          ),
        ),
      ),
      ],
    );
  }
}

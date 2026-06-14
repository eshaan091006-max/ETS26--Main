import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malhar_ets/app/admin/cards/grouped_participation_card.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/widgets.dart';
import 'package:malhar_ets/shared/controllers/contingent_controller.dart';
import 'package:malhar_ets/shared/controllers/department_controller.dart';
import 'package:malhar_ets/shared/controllers/event_controller.dart';
import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';
import 'package:malhar_ets/shared/controllers/participation_controller.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/shared/models/participation.dart';
import 'package:malhar_ets/app/admin/contingent/manage_event_modal.dart';
import 'package:malhar_ets/app/admin/modals/confirm_deletion.dart';
import 'package:malhar_ets/helpers/animated_card_wrapper.dart';
import 'package:malhar_ets/helpers/empty_state_widget.dart';
import 'package:malhar_ets/helpers/glowing_search_field.dart';

class ParticipationManagementPage extends StatefulWidget {
  const ParticipationManagementPage({super.key});

  @override
  State<ParticipationManagementPage> createState() =>
      _EventManagementPageState();
}

class _EventManagementPageState extends State<ParticipationManagementPage> {
  final ContingentController _contingentController = ContingentController();
  final ParticipationController _participationController =
      ParticipationController();

  String selectedDept = 'All';
  String selectedContingent = 'All';

  List<String> departments = ['All'];
  List<String> contingents = ['All'];

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initFilters();
  }

  void _initFilters() {
    final deptSet =
        _participationController.participations
            .map((p) {
              final event = EventController().getEventById(p.eventId);
              if (event == null) return '';
              return DepartmentController()
                      .getDepartmentById(event.departmentId.toInt())
                      ?.code ??
                  '';
            })
            .where((code) => code.isNotEmpty)
            .toSet();
    departments = ['All', ...deptSet];

    final contSet =
        _participationController.participations
            .map(
              (p) =>
                  _contingentController
                      .getContingentById(p.contingentId)
                      ?.contingentCode ??
                  '',
            )
            .where((code) => code.isNotEmpty)
            .toSet();
    contingents = ['All', ...contSet];
  }

  List<Participation> getFilteredParticipations() {
    return _participationController.participations.where((p) {
      final contingent =
          _contingentController.getContingentById(p.contingentId);
      final event = EventController().getEventById(p.eventId);
      if (event == null || contingent == null) return false;

      final deptCode =
          DepartmentController()
              .getDepartmentById(event.departmentId.toInt())
              ?.code;

      final deptMatch = selectedDept == 'All' || deptCode == selectedDept;
      final contMatch =
          selectedContingent == 'All' ||
          contingent.contingentCode == selectedContingent;

      return deptMatch && contMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PageRefreshController.refreshNotifier,
      builder: (context, value, child) {
        _initFilters();
        final filtered = getFilteredParticipations();

        // Group by contingent
        final Map<int, List<Participation>> grouped = {};
        for (var p in filtered) {
          grouped.putIfAbsent(p.contingentId, () => []).add(p);
        }

        // Apply search filter on grouped contingents
        final query = _searchController.text.trim().toLowerCase();
        final Map<int, List<Participation>> searchedGrouped = {};
        for (var entry in grouped.entries) {
          final contingent = _contingentController.getContingentById(entry.key);
          final code = contingent?.contingentCode.toLowerCase() ?? '';
          if (code.contains(query)) {
            searchedGrouped[entry.key] = entry.value;
          }
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.black12,
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
                    label: 'Contingent',
                    value: selectedContingent,
                    options: contingents,
                    onChanged: (val) => setState(() => selectedContingent = val!),
                  ),
                ],
              ),
            ),

            /// Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: GlowingSearchField(
                controller: _searchController,
                hintText: 'Search by Contingent Code...',
                onChanged: (text) {
                  setState(() {});
                },
                onClear: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
            ),

            (searchedGrouped.isEmpty)
                ? const Expanded(
                    child: EmptyStateWidget(
                      title: 'No Participations Found',
                      subtitle: '',
                      icon: Icons.how_to_vote,
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: searchedGrouped.length,
                      itemBuilder: (context, index) {
                        final contingentId = searchedGrouped.keys.elementAt(index);
                        final List<Participation> contingentParticipations =
                            searchedGrouped[contingentId]!;

                        final Contingent contingent =
                            _contingentController.getContingentById(
                              contingentId,
                            ) ??
                            Contingent();

                        return AnimatedCardWrapper(
                          key: ValueKey(contingentId),
                          child: GroupedParticipationCard(
                            contingent: contingent,
                            participations: contingentParticipations,
                            onEdit: (Participation p) {
                              showUpdateEventBottomSheet(context, [p], contingent);
                            },
                            onDelete: (Participation p) {
                              confirmDeletionModal(
                                context,
                                'Participation',
                                onSubmit: () {
                                  _participationController.deleteParticipation(context, p);
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ],
        );
      },
    );
  }
}

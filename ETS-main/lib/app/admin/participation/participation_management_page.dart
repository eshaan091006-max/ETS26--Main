import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malhar_ets/app/admin/cards/grouped_participation_card.dart';
import 'package:malhar_ets/app/admin/contingent/manage_event_modal.dart';
import 'package:malhar_ets/app/admin/modals/confirm_deletion.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/widgets.dart';
import 'package:malhar_ets/shared/controllers/contingent_controller.dart';
import 'package:malhar_ets/shared/controllers/department_controller.dart';
import 'package:malhar_ets/shared/controllers/event_controller.dart';
import 'package:malhar_ets/shared/controllers/participation_controller.dart';
import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/shared/models/participation.dart';
import 'package:malhar_ets/utils/app_feedback.dart';

class ParticipationManagementPage extends StatefulWidget {
  const ParticipationManagementPage({super.key});

  @override
  State<ParticipationManagementPage> createState() =>
      _EventManagementPageState();
}

class _EventManagementPageState extends State<ParticipationManagementPage> {
  final EventController _eventController = EventController();
  final ContingentController _contingentController = ContingentController();
  late ParticipationController _participationController;

  bool isLoading = true;

  String selectedDept = 'All';
  String selectedContingent = 'All';

  List<String> departments = ['All'];
  List<String> contingents = ['All'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppFeedback.showLoading(context);
    });
    _initializeParticipations();
  }

  Future<void> _initializeParticipations() async {
    _participationController =
        await ParticipationController().initializeParticipations();

    if (!mounted) return;

    // Prepare departments and contingent codes from data
    final eventIds =
        _participationController.participations
            .map((p) => p.eventId)
            .toSet()
            .toList();
    final contingentIds =
        _participationController.participations
            .map((p) => p.contingentId)
            .toSet()
            .toList();

    departments = [
      'All',
      ...{
        for (var id in eventIds)
          DepartmentController()
              .getDepartmentById(
                _eventController.getEventById(id)!.departmentId,
              )
              ?.code,
      }.whereType<String>(),
    ];

    contingents = [
      'All',
      ...{
        for (var id in contingentIds)
          _contingentController.getContingentById(id)?.contingentCode,
      }.whereType<String>(),
    ];

    AppFeedback.hideLoading(context);
    setState(() => isLoading = false);
  }

  List<Participation> getFilteredParticipations() {
    return _participationController.participations.where((p) {
      final event = _eventController.getEventById(p.eventId);
      final contingent = _contingentController.getContingentById(
        p.contingentId,
      );

      final dept = DepartmentController().getDepartmentById(event?.departmentId ?? -1);
      if (dept == null) return false;
      final deptCode = dept.code;

      final matchesDept = selectedDept == 'All' || selectedDept == deptCode;
      final matchesContingent =
          selectedContingent == 'All' ||
          selectedContingent == contingent?.contingentCode;

      return matchesDept && matchesContingent;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return ValueListenableBuilder<bool>(
      valueListenable: PageRefreshController.refreshNotifier,
      builder: (context, refresh, child) {
        final filteredParticipations = getFilteredParticipations();

        // Group filtered participations by contingentId
        final Map<int, List<Participation>> grouped = {};
        for (var p in filteredParticipations) {
          grouped.putIfAbsent(p.contingentId, () => []).add(p);
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
            (grouped.isEmpty)
                ? Expanded(
                    child: Center(
                      child: Text(
                        'No Participations Found!',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final contingentId = grouped.keys.elementAt(index);
                        final List<Participation> contingentParticipations =
                            grouped[contingentId]!;

                        final Contingent contingent =
                            _contingentController.getContingentById(
                              contingentId,
                            ) ??
                            Contingent();

                        return GroupedParticipationCard(
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malhar_ets/app/admin/cards/participation_card.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/widgets.dart';
import 'package:malhar_ets/shared/controllers/contingent_controller.dart';
import 'package:malhar_ets/shared/controllers/department_controller.dart';
import 'package:malhar_ets/shared/controllers/event_controller.dart';
import 'package:malhar_ets/shared/controllers/participation_controller.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/shared/models/event.dart';
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

    final filteredParticipations = getFilteredParticipations();

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
        (filteredParticipations.isEmpty)
            ? Text(
              'No Participations Found!',
              style: GoogleFonts.poppins(
                fontSize: 22,
                color: AppColors.primary,
              ),
            )
            : Expanded(
              child: ListView.builder(
                itemCount: filteredParticipations.length,
                itemBuilder: (context, index) {
                  final Participation participation =
                      filteredParticipations[index];
                  final Event event =
                      _eventController.getEventById(participation.eventId) ??
                      Event(dateTime: DateTime.now());

                  final Contingent contingent =
                      _contingentController.getContingentById(
                        participation.contingentId,
                      ) ??
                      Contingent();

                  return ParticipationCard(
                    participation: participation,
                    event: event,
                    contingent: contingent,
                    onEdit: () => {},
                    onDelete: () => {},
                  );
                },
              ),
            ),
      ],
    );
  }
}

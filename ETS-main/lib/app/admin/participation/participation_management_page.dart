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

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondary,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return _FilterBottomSheetContent(
          departments: departments,
          contingents: contingents,
          initialDept: selectedDept,
          initialContingent: selectedContingent,
          onApply: (dept, cont) {
            setState(() {
              selectedDept = dept;
              selectedContingent = cont;
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildFilterButton(BuildContext context) {
    int activeFiltersCount = 0;
    if (selectedDept != 'All') activeFiltersCount++;
    if (selectedContingent != 'All') activeFiltersCount++;

    final bool hasActiveFilters = activeFiltersCount > 0;

    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasActiveFilters ? AppColors.primary : AppColors.border.withValues(alpha: 0.3),
              width: hasActiveFilters ? 1.5 : 1.0,
            ),
          ),
          child: IconButton(
            icon: Icon(
              Icons.filter_list,
              color: hasActiveFilters ? AppColors.primary : AppColors.textWhite,
            ),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ),
        if (hasActiveFilters)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                activeFiltersCount.toString(),
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
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
            /// Search Bar and Filter row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
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
                  const SizedBox(width: 12),
                  _buildFilterButton(context),
                ],
              ),
            ),

            (searchedGrouped.isEmpty)
                ? Expanded(
                    child: EmptyStateWidget(
                      title: 'No Participations Found',
                      subtitle: 'Try adjusting your search queries or active filters.',
                      icon: Icons.how_to_vote,
                      action: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            selectedDept = 'All';
                            selectedContingent = 'All';
                            _searchController.clear();
                          });
                        },
                        child: Text(
                          "Clear Filters",
                          style: GoogleFonts.montserrat(
                            color: AppColors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

class _FilterBottomSheetContent extends StatefulWidget {
  final List<String> departments;
  final List<String> contingents;
  final String initialDept;
  final String initialContingent;
  final Function(String, String) onApply;

  const _FilterBottomSheetContent({
    required this.departments,
    required this.contingents,
    required this.initialDept,
    required this.initialContingent,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheetContent> createState() =>
      __FilterBottomSheetContentState();
}

class __FilterBottomSheetContentState extends State<_FilterBottomSheetContent> {
  late String _localDept;
  late String _localContingent;
  final TextEditingController _contingentSearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _localDept = widget.initialDept;
    _localContingent = widget.initialContingent;
  }

  @override
  void dispose() {
    _contingentSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _contingentSearchController.text.trim().toLowerCase();
    final filteredContingents = widget.contingents.where((c) {
      if (c == 'All') return true;
      return c.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Filter Participations",
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textWhite),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Department",
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.departments.length,
              itemBuilder: (context, index) {
                final dept = widget.departments[index];
                final isSelected = _localDept == dept;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(
                      dept == 'All' ? 'All Departments' : dept,
                      style: TextStyle(
                        color: isSelected ? AppColors.black : AppColors.textWhite,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.tertiary,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _localDept = dept;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Contingent",
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contingentSearchController,
            style: const TextStyle(color: AppColors.textWhite),
            decoration: InputDecoration(
              hintText: "Search contingent code...",
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _contingentSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: () {
                        _contingentSearchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.tertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: AppColors.tertiary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredContingents.length,
              itemBuilder: (context, index) {
                final cont = filteredContingents[index];
                final isSelected = _localContingent == cont;
                return ListTile(
                  dense: true,
                  title: Text(
                    cont == 'All' ? 'All Contingents' : cont,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textWhite,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                      : null,
                  onTap: () {
                    setState(() {
                      _localContingent = cont;
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    setState(() {
                      _localDept = 'All';
                      _localContingent = 'All';
                      _contingentSearchController.clear();
                    });
                  },
                  child: Text(
                    "Reset All",
                    style: GoogleFonts.montserrat(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    widget.onApply(_localDept, _localContingent);
                  },
                  child: Text(
                    "Apply Filters",
                    style: GoogleFonts.montserrat(
                      color: AppColors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malhar_ets/app/admin/cards/contingent_card.dart';
import 'package:malhar_ets/app/admin/contingent/events_participated_page.dart';
import 'package:malhar_ets/app/admin/modals/contingent_modal.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/shared/controllers/contingent_controller.dart';
import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/utils/app_feedback.dart';

class ContingentManagementPage extends StatefulWidget {
  const ContingentManagementPage({super.key});

  @override
  State<ContingentManagementPage> createState() =>
      _ContingentManagementPageState();
}

class _ContingentManagementPageState extends State<ContingentManagementPage> {
  final ContingentController _contingentController = ContingentController();
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    isLoading = false;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    return ValueListenableBuilder(
      valueListenable: PageRefreshController.refreshNotifier,
      builder: (context, value, child) {
        final query = _searchController.text.trim().toLowerCase();
        final List<Contingent> filteredContingents = _contingentController.contingents
            .where((c) => c.contingentCode.toLowerCase().contains(query))
            .toList();

        return Column(
          children: [
            /// Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textWhite),
                decoration: InputDecoration(
                  hintText: 'Search Contingents...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppColors.primary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.secondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (text) {
                  setState(() {});
                },
              ),
            ),

            /// Contingents List
            Expanded(
              child: filteredContingents.isEmpty
                  ? Center(
                      child: Text(
                        'No Contingents Found!',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredContingents.length,
                      itemBuilder: (context, index) {
                        Contingent contingent = filteredContingents[index];

                        final navigateToEvents = () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (_) => EventsParticipatedPage(contingent: contingent),
                          ),
                        );

                        return GestureDetector(
                          onDoubleTap: navigateToEvents,
                          child: ContingentCard(
                            contingent: contingent,
                            onEdit:
                                () => showContingentModal(
                                  context,
                                  contingent: contingent,
                                  onSubmit: (contingent) async {
                                    await ContingentController().updateContingent(
                                      context,
                                      contingent,
                                    );
                                  },
                                ),
                            onDelete: () async {
                              await ContingentController().deleteContingent(
                                context,
                                contingent.contingentId,
                              );
                            },
                            onViewEvents: navigateToEvents,
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

import 'package:flutter/material.dart';
import 'package:malhar_ets/app/admin/cards/contingent_card.dart';
import 'package:malhar_ets/app/admin/contingent/events_participated_page.dart';
import 'package:malhar_ets/app/admin/modals/contingent_modal.dart';
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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // AppFeedback.showLoading(context);
    });
    // _initializeContingents();
    // AppFeedback.hideLoading(context);
    isLoading = false;
  }

  // Future<void> _initializeContingents() async {
  // _contingentController =
  // await ContingentController().initializeContingents();
  //   if (!mounted) return;
  // }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Center(child: CircularProgressIndicator());
    return ValueListenableBuilder(
      valueListenable: PageRefreshController.refreshNotifier,
      builder: (context, value, child) {
        return ListView.builder(
          itemCount: _contingentController.contingents.length,
          itemBuilder: (context, index) {
            Contingent contingent = _contingentController.contingents[index];

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
        );
      },
    );
  }
}

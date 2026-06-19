import 'package:flutter/material.dart';
import 'package:malhar_ets/app/contingent/cards/department_card.dart';
import 'package:malhar_ets/app/contingent/form_links/events_page.dart';
import 'package:malhar_ets/shared/controllers/department_controller.dart';
import 'package:malhar_ets/shared/controllers/page_refresh_controller.dart';
import 'package:malhar_ets/helpers/page_transitions.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/shared/models/department.dart';
import 'package:vertical_card_pager/vertical_card_pager.dart';
import 'package:malhar_ets/helpers/shimmer_skeleton.dart';

class DepartmentsPage extends StatefulWidget {
  final Contingent contingent;

  const DepartmentsPage({required this.contingent, super.key});
  @override
  _DepartmentsPageState createState() => _DepartmentsPageState();
}

class _DepartmentsPageState extends State<DepartmentsPage> {
  double _currentPage = 0.0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: PageRefreshController.refreshNotifier,
      builder: (context, _, __) {
        final List<String> allowedCodes = ['WPA', 'LPA', 'ETCW', 'FA', 'LA'];
        final List<Department> departments = DepartmentController()
            .departments
            .where((d) => allowedCodes.contains(d.code.toUpperCase()))
            .toList();

        if (!PageRefreshController.initialLoadCompleted || departments.isEmpty) {
          return const ShimmerSkeletonList(
            itemCount: 3,
            cardHeight: 180.0,
          );
        }

        return SafeArea(
          child: Container(
            padding: const EdgeInsets.only(bottom: 75), // Clears the floating action button and bottom navigation bar
            child: VerticalCardPager(
              initialPage: 0,
              titles: departments.map((d) => "").toList(),
              images: departments.asMap().entries.map((entry) {
                int index = entry.key;
                Department d = entry.value;
                bool isFocused = (index - _currentPage).abs() <= 0.5;
                return DepartmentCard(d: d, isFocused: isFocused);
              }).toList(),
              onPageChanged: (page) {
                if (page != null) {
                  setState(() {
                    _currentPage = page;
                  });
                }
              },
              onSelectedItem: (index) {
                Navigator.push(
                  context,
                  LiquidPageRoute(
                    page: EventsPage(
                      department: departments[index],
                      contingent: widget.contingent,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

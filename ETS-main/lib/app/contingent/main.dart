import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:malhar_ets/app/contingent/form_links/departments_page.dart';
import 'package:malhar_ets/app/contingent/login/login_page.dart';
import 'package:malhar_ets/constants/app_theme.dart';
import 'package:malhar_ets/constants/supabase/credentials.dart';
import 'package:malhar_ets/shared/pages/home.dart';
import 'package:malhar_ets/app/contingent/profile/profile_page.dart';
import 'package:malhar_ets/app/contingent/scores/scores_page.dart';
import 'package:malhar_ets/constants/app_bar.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/shared/controllers/contingent_controller.dart';
import 'package:malhar_ets/shared/controllers/department_controller.dart';
import 'package:malhar_ets/shared/controllers/event_controller.dart';
import 'package:malhar_ets/shared/controllers/form_link_controller.dart';
import 'package:malhar_ets/shared/controllers/participation_controller.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseCredentials.url,
    anonKey: SupabaseCredentials.anonKey,
  );
  runApp(const Root());
}

class Root extends StatelessWidget {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: themeData,
      // darkTheme: AppTheme.darkTheme,
      // themeMode: ThemeMode.system,
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Main extends StatefulWidget {
  final Contingent contingent;
  const Main({required this.contingent, super.key});

  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> {
  int _currentIndex = 0;

  @override
  void initState() {
    // TODO: implement initState
    initializeVars();
    loadData();
    subscribeToChannels();
    super.initState();
  }

  void initializeVars() {
    _pages.addAll([
      Home(contingent: widget.contingent),
      DepartmentsPage(contingent: widget.contingent),
      ScoresPage(c: widget.contingent),
      ProfilePage(contingent: widget.contingent),
    ]);
  }

  void loadData() {
    DepartmentController().loadDepartments();
    EventController().loadEvents();
    ContingentController().loadContingents();
    ParticipationController().loadParticipations();
    FormLinkController().loadFormLinks();
  }

  void subscribeToChannels() {
    ContingentController().subscribeToContingents(navigatorKey);
    EventController().subscribeToEvents(navigatorKey);
    ParticipationController().subscribeToParticipations(navigatorKey);
    FormLinkController().subscribeToFormLinks(navigatorKey);
  }

  final List<Widget> _pages = [];
  final iconList = <IconData>[
    Icons.home,
    Icons.link_sharp,
    Icons.leaderboard_sharp,
    Icons.person,
  ];

  final labelList = <String>['Home', 'Form Links', 'Score', 'Profile'];

  @override
  Widget build(BuildContext context) {
    List<VoidCallback> actionList = [
      () {
        //Null Function
      },
      // () => AppFeedback.showInfo(context, 'Adding Contingent..'),
      () {
        //Null Function
      },
      () {
        //Null Function
      },
      () {
        //Null Function
      },
    ];
    return Scaffold(
      backgroundColor: AppColors.secondary,
      key: navigatorKey,
      appBar: getAppBar(context, true),
      body: _pages[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: actionList[_currentIndex],
        backgroundColor: AppColors.primary,
        child: Icon(iconList[_currentIndex], color: AppColors.textWhite),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        itemCount: iconList.length,
        tabBuilder: (int index, bool isActive) {
          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 250),
            tween: Tween<double>(begin: 0.0, end: isActive ? 1.0 : 0.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              final scale = 1.0 + 0.12 * value;
              final Color color = Color.lerp(Colors.white38, AppColors.primary, value)!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: scale,
                    child: Icon(iconList[index], size: 24, color: color),
                  ),
                  const SizedBox(height: 4),
                  Transform.scale(
                    scale: 1.0 + 0.05 * value,
                    child: Text(
                      labelList[index],
                      style: TextStyle(
                        color: color, 
                        fontSize: 11,
                        fontWeight: value > 0.5 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Growing glowing active line indicator
                  Container(
                    height: 2,
                    width: 14 * value,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha((value * 180).toInt()),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
        activeIndex: _currentIndex,
        backgroundColor: AppColors.secondary,
        splashColor: AppColors.accent,
        notchSmoothness: NotchSmoothness.softEdge,
        gapLocation: GapLocation.center,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

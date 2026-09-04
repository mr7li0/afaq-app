import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../shared/widgets/glassmorphism_bottom_nav_bar.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../dashboard/presentation/views/dashboard_view.dart';
import '../../../quran/presentation/controllers/quran_controller.dart';
import '../../../quran/presentation/views/quran_view.dart';
import '../../../athkar/presentation/controllers/athkar_controller.dart';
import '../../../athkar/presentation/views/athkar_categories_view.dart';
import '../../../settings_ecosystem/presentation/controllers/settings_controller.dart';
import '../../../settings_ecosystem/presentation/views/profile_view.dart';
import '../../../alarms/ui/alarms_view.dart';

class MainNavigationView extends StatefulWidget {
  const MainNavigationView({super.key});

  @override
  State<MainNavigationView> createState() => _MainNavigationViewState();
}

class _MainNavigationViewState extends State<MainNavigationView> {
  int _currentTab = 0;
  late final PageController _pageController;

  static const List<Widget> _tabViews = [
    DashboardView(),
    QuranView(),
    AthkarCategoriesView(),
    AlarmsView(),
    ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_currentTab != index) {
      setState(() => _currentTab = index);
    }
  }

  void _onTabTapped(int index) {
    if (_currentTab != index) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentTab = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardController()),
        ChangeNotifierProvider(create: (_) => QuranController()),
        ChangeNotifierProvider(create: (_) => AthkarController()),
        ChangeNotifierProvider(create: (_) => SettingsController()),
      ],
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const PageScrollPhysics(),
              children: _tabViews,
            ),
            GlassmorphicBottomNavBar(
              currentIndex: _currentTab,
              onTap: _onTabTapped,
            ),
          ],
        ),
      ),
    );
  }
}

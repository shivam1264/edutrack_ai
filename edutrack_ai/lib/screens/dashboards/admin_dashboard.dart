import 'package:flutter/material.dart';
import '../admin/dashboard_views/admin_home_view.dart';
import '../admin/dashboard_views/admin_analytics_view.dart';
import '../admin/dashboard_views/admin_alerts_view.dart';
import '../admin/dashboard_views/admin_profile_view.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_navigation_bar.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  final List<Widget> _views = [
    const AdminHomeView(),
    const AdminAnalyticsView(),
    const AdminAlertsView(),
    const AdminProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
       bottomNavigationBar: GlassNavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        accentColor: AppTheme.adminColor,
        secondaryColor: AppTheme.info,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: AppTheme.adminColor),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded, color: AppTheme.adminColor),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_active_rounded, color: AppTheme.adminColor),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppTheme.adminColor),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../admin/dashboard_views/admin_home_view.dart';
import '../admin/dashboard_views/admin_analytics_view.dart';
import '../admin/dashboard_views/admin_alerts_view.dart';
import '../admin/dashboard_views/admin_profile_view.dart';
import '../../utils/app_theme.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
       bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.adminLight,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 32, offset: const Offset(0, -12)),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              height: 74,
              backgroundColor: Colors.transparent,
              elevation: 0,
              indicatorColor: AppTheme.adminColor.withOpacity(0.1),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.adminColor);
                }
                return const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textHint);
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(color: AppTheme.adminColor, size: 26);
                }
                return IconThemeData(color: AppTheme.textHint, size: 24);
              }),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
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
          ),
        ),
      ),
    );
  }
}

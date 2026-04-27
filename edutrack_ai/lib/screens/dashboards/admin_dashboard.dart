import 'package:flutter/material.dart';
import '../admin/dashboard_views/admin_home_view.dart';
import '../admin/dashboard_views/admin_analytics_view.dart';
import '../admin/dashboard_views/admin_alerts_view.dart';
import '../admin/dashboard_views/admin_profile_view.dart';

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
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, -4)),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: Colors.transparent,
          elevation: 0,
          height: 64,
          indicatorColor: const Color(0xFF0F172A).withOpacity(0.08),
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A));
            }
            return const TextStyle(fontSize: 12, color: Color(0xFF64748B));
          }),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: Color(0xFF94A3B8)),
              selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF0F172A)),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined, color: Color(0xFF94A3B8)),
              selectedIcon: Icon(Icons.analytics_rounded, color: Color(0xFF0F172A)),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_none_rounded, color: Color(0xFF94A3B8)),
              selectedIcon: Icon(Icons.notifications_active_rounded, color: Color(0xFF0F172A)),
              label: 'Alerts',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: Color(0xFF94A3B8)),
              selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF0F172A)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

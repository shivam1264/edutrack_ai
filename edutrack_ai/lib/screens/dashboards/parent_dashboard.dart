import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/analytics_provider.dart';
import '../parent/views/parent_home_view.dart';
import '../parent/views/parent_child_view.dart';
import '../parent/views/parent_insights_view.dart';
import '../parent/views/parent_updates_view.dart';
import '../parent/views/parent_profile_view.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user?.parentOf != null && user!.parentOf!.isNotEmpty) {
        context.read<AnalyticsProvider>().loadStudentAnalytics(user.parentOf!.first);
      }
    });
  }

  final List<Widget> _views = [
    const ParentHomeView(),
    const ParentChildView(),
    const ParentInsightsView(),
    const ParentUpdatesView(),
    const ParentProfileView(),
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
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFF97316), // Warm Orange
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Child'),
            BottomNavigationBarItem(icon: Icon(Icons.lightbulb_outline_rounded), activeIcon: Icon(Icons.lightbulb_rounded), label: 'Insights'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_none_rounded), activeIcon: Icon(Icons.notifications_rounded), label: 'Updates'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

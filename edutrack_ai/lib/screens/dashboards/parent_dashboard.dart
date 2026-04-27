import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/providers/analytics_provider.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
import 'package:edutrack_ai/screens/parent/views/parent_home_view.dart';
import 'package:edutrack_ai/screens/parent/views/parent_child_view.dart';
import 'package:edutrack_ai/screens/parent/views/parent_insights_view.dart';
import 'package:edutrack_ai/screens/parent/views/parent_updates_view.dart';
import 'package:edutrack_ai/screens/parent/views/parent_profile_view.dart';

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
          color: AppTheme.surfaceLight,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 32, offset: const Offset(0, -10)),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              height: 78,
              backgroundColor: Colors.transparent,
              elevation: 0,
              indicatorColor: AppTheme.parentLight,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.parentColor);
                }
                return TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textHint);
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(color: AppTheme.parentColor, size: 26);
                }
                return IconThemeData(color: AppTheme.textHint, size: 24);
              }),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded, color: AppTheme.parentColor),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded, color: AppTheme.parentColor),
                  label: 'Child',
                ),
                NavigationDestination(
                  icon: Icon(Icons.lightbulb_outline_rounded),
                  selectedIcon: Icon(Icons.lightbulb_rounded, color: AppTheme.parentColor),
                  label: 'Insights',
                ),
                NavigationDestination(
                  icon: Icon(Icons.notifications_none_rounded),
                  selectedIcon: Icon(Icons.notifications_rounded, color: AppTheme.parentColor),
                  label: 'Updates',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings_rounded, color: AppTheme.parentColor),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/providers/analytics_provider.dart';
import 'package:edutrack_ai/providers/gamification_provider.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
import 'package:edutrack_ai/screens/student/dashboard_views/home_view.dart';
import 'package:edutrack_ai/screens/student/dashboard_views/missions_view.dart';
import 'package:edutrack_ai/screens/student/dashboard_views/progress_view.dart';
import 'package:edutrack_ai/screens/student/dashboard_views/student_profile_view.dart';
import 'package:edutrack_ai/screens/student/dashboard_views/communication_view.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        context.read<AnalyticsProvider>().loadStudentAnalytics(user.uid);
        context.read<GamificationProvider>().updateUserData(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const HomeView();
      case 1:
        return const MissionsView();
      case 2:
        return const CommunicationView(); // New View
      case 3:
        return const ProgressView();
      case 4:
        return const StudentProfileView();
      default:
        return const HomeView();
    }
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, -8)),
        ],
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 76,
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: AppTheme.primary.withOpacity(0.08),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primary);
            }
            return TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textHint);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppTheme.primary, size: 26);
            }
            return IconThemeData(color: AppTheme.textHint, size: 24);
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.rocket_launch_outlined),
              selectedIcon: Icon(Icons.rocket_launch_rounded, color: AppTheme.primary),
              label: 'Missions',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: Icon(Icons.chat_bubble_rounded, color: AppTheme.primary),
              label: 'Chat',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded, color: AppTheme.primary),
              label: 'Progress',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppTheme.primary),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

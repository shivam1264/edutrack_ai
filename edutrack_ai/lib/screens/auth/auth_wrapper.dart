import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../auth/loading_screen.dart';
import '../auth/login_screen.dart';
import '../dashboards/admin_dashboard.dart';
import '../dashboards/teacher_dashboard.dart';
import '../dashboards/student_dashboard.dart';
import '../dashboards/parent_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Show loading splash while checking auth state
    if (authProvider.isLoading) {
      return const LoadingScreen();
    }

    // Not authenticated → login
    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    // Route based on role
    return _routeByRole(authProvider.role);
  }

  Widget _routeByRole(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return const AdminDashboard();
      case UserRole.teacher:
        return const TeacherDashboard();
      case UserRole.student:
        return const StudentDashboard();
      case UserRole.parent:
        return const ParentDashboard();
      default:
        return const LoginScreen();
    }
  }
}

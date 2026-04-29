import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/providers/analytics_provider.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
import 'package:edutrack_ai/services/class_service.dart';
import 'package:edutrack_ai/models/class_model.dart';
import 'package:edutrack_ai/screens/teacher/dashboard_views/teacher_home_view.dart';
import 'package:edutrack_ai/screens/teacher/dashboard_views/teacher_classroom_view.dart';
import 'package:edutrack_ai/screens/teacher/dashboard_views/teacher_students_view.dart';
import 'package:edutrack_ai/screens/teacher/dashboard_views/teacher_reports_view.dart';
import 'package:edutrack_ai/screens/teacher/dashboard_views/teacher_more_view.dart';
import 'package:edutrack_ai/widgets/glass_navigation_bar.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _currentIndex = 0;
  String? _selectedClassId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null) {
        final classes = user.assignedClasses ?? (user.classId != null ? [user.classId!] : []);
        if (classes.isNotEmpty) {
          setState(() => _selectedClassId = classes.first);
          context.read<AnalyticsProvider>().loadClassAnalytics(_selectedClassId!);
        }
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final assignedIds = user?.assignedClasses ?? (user?.classId != null ? [user!.classId!] : []);

    return StreamBuilder<List<ClassModel>>(
      stream: ClassService().getClasses(),
      builder: (context, classSnap) {
        // Filter classes to only those assigned to the teacher
        final allAvailableClasses = classSnap.data ?? [];
        final myClasses = allAvailableClasses.where((c) => assignedIds.contains(c.id)).toList();
        
        final Map<String, String> classMap = { for (var c in myClasses) c.id : c.displayName };
        
        // Ensure _selectedClassId is valid for the Dropdown items
        final String? effectiveSelectedId = classMap.containsKey(_selectedClassId) 
            ? _selectedClassId 
            : (myClasses.isNotEmpty ? myClasses.first.id : null);
            
        final currentClassName = classMap[effectiveSelectedId] ?? (effectiveSelectedId != null ? 'Loading...' : 'N/A');

        final List<Widget> tabs = [
          TeacherHomeView(selectedClassId: effectiveSelectedId, currentClassName: currentClassName),
          TeacherClassroomView(selectedClassId: effectiveSelectedId, currentClassName: currentClassName),
          TeacherStudentsView(selectedClassId: effectiveSelectedId),
          TeacherReportsView(selectedClassId: effectiveSelectedId),
          const TeacherMoreView(),
        ];

        return Scaffold(
          extendBody: true,
          backgroundColor: AppTheme.bgLight,
          appBar: AppBar(
            toolbarHeight: 72,
            backgroundColor: AppTheme.surfaceLight,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: classMap.isEmpty 
              ? const Text('No Classes Assigned', style: TextStyle(fontSize: 16))
              : Container(
                  constraints: const BoxConstraints(maxWidth: 240),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: effectiveSelectedId,
                      dropdownColor: Colors.white,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.textPrimary,
                      ),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() => _selectedClassId = newValue);
                          context.read<AnalyticsProvider>().loadClassAnalytics(newValue);
                        }
                      },
                      items: classMap.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value, maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  if (_selectedClassId != null) {
                    context.read<AnalyticsProvider>().loadClassAnalytics(_selectedClassId!);
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: tabs,
          ),
          bottomNavigationBar: GlassNavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            accentColor: const Color(0xFF059669),
            secondaryColor: AppTheme.info,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF059669)),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school_rounded, color: Color(0xFF059669)),
                label: 'Classroom',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_alt_outlined),
                selectedIcon: Icon(Icons.people_alt_rounded, color: Color(0xFF059669)),
                label: 'Students',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart_rounded, color: Color(0xFF059669)),
                label: 'Reports',
              ),
              NavigationDestination(
                icon: Icon(Icons.more_horiz_outlined),
                selectedIcon: Icon(Icons.more_horiz_rounded, color: Color(0xFF059669)),
                label: 'More',
              ),
            ],
          ),
        );
      }
    );
  }
}

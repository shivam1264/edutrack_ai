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
        final currentClassName = classMap[_selectedClassId] ?? _selectedClassId ?? 'N/A';

        final List<Widget> tabs = [
          TeacherHomeView(selectedClassId: _selectedClassId, currentClassName: currentClassName),
          TeacherClassroomView(selectedClassId: _selectedClassId, currentClassName: currentClassName),
          TeacherStudentsView(selectedClassId: _selectedClassId),
          const TeacherReportsView(),
          const TeacherMoreView(),
        ];

        return Scaffold(
          backgroundColor: AppTheme.bgLight,
          appBar: AppBar(
            backgroundColor: const Color(0xFF059669),
            elevation: 0,
            centerTitle: true,
            title: classMap.isEmpty 
              ? const Text('No Classes Assigned', style: TextStyle(color: Colors.white, fontSize: 16))
              : Container(
                  constraints: const BoxConstraints(maxWidth: 220), // Constraint for center title
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true, // Crucial for long names
                      value: _selectedClassId,
                      dropdownColor: const Color(0xFF065F46),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
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
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                 BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF059669),
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
                BottomNavigationBarItem(icon: Icon(Icons.school_rounded), label: 'Classroom'),
                BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Students'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Reports'),
                BottomNavigationBarItem(icon: Icon(Icons.more_horiz_rounded), label: 'More'),
              ],
            ),
          ),
        );
      }
    );
  }
}

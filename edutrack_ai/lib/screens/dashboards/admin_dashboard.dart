import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../admin/add_user_screen.dart';
import '../admin/announcement_screen.dart';
import '../admin/class_management_screen.dart';
import '../admin/reports_screen.dart';
import '../admin/permissions_screen.dart';
import '../admin/school_analytics_screen.dart';
import '../admin/timetable_manager_screen.dart';
import '../admin/teacher_performance_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _AdminHomeView(),
          _SystemHealthView(),
          _AdminSettingsView(),
        ],
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
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: Colors.grey),
              selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF0F172A)),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.health_and_safety_outlined, color: Colors.grey),
              selectedIcon: Icon(Icons.health_and_safety_rounded, color: Color(0xFF0F172A)),
              label: 'Health',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined, color: Colors.grey),
              selectedIcon: Icon(Icons.settings_rounded, color: Color(0xFF0F172A)),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminHomeView extends StatelessWidget {
  const _AdminHomeView();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 260,
          floating: false,
          pinned: true,
          stretch: true,
          backgroundColor: const Color(0xFF0F172A), 
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white),
              onPressed: () => _showLogoutDialog(context),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
                    ),
                  ),
                ),
                Positioned(
                  right: -50,
                  top: -50,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blueAccent.withOpacity(0.05)),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  right: 40,
                  child: Icon(Icons.shield_moon_rounded, color: Colors.white.withOpacity(0.05), size: 180),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            const Text('SYSTEM ONLINE', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          ],
                        ),
                      ).animate().fadeIn().shimmer(duration: const Duration(seconds: 2)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle, 
                              gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent]),
                              boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 15)]
                            ),
                            child: const CircleAvatar(
                              radius: 32,
                              backgroundColor: Color(0xFF0F172A),
                              child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 30),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Command Center', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                                Text('Superadmin: ${user?.name ?? 'Admin'}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          const NotificationBell(userId: ''),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI & Core Metrics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    _AdminStatCard(label: 'Total Students', collection: 'students', filterField: null, filterValue: null, icon: Icons.people_alt_rounded, color: Colors.blue),
                    _AdminStatCard(label: 'Teachers Active', collection: 'teachers', filterField: null, filterValue: null, icon: Icons.school_rounded, color: Colors.purple),
                    _AdminStatCard(label: 'Active Hubs', collection: 'classes', filterField: null, filterValue: null, icon: Icons.hub_rounded, color: Colors.amber),
                    _AdminStatCard(label: 'AI Predictions', collection: 'ai_predictions', filterField: 'risk_level', filterValue: 'high', icon: Icons.gpp_maybe_rounded, color: Colors.redAccent),
                  ],
                ).animate().fadeIn(duration: const Duration(milliseconds: 500)).slideY(begin: 0.1),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('System Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                const SizedBox(height: 16),
                _buildAdminGrid(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminGrid(BuildContext context) {
    final actions = [
      {
        'icon': Icons.person_add_rounded,
        'label': 'Provision Users',
        'color': Colors.blue,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddUserScreen())),
      },
      {
        'icon': Icons.hub_rounded,
        'label': 'Manage Hubs',
        'color': Colors.indigo,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassManagementScreen())),
      },
      {
        'icon': Icons.insights_rounded,
        'label': 'Intelligence',
        'color': Colors.purple,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
      },
      {
        'icon': Icons.supervisor_account_rounded,
        'label': 'Teacher Tracking',
        'color': Colors.pink,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeacherPerformanceScreen())),
      },
      {
        'icon': Icons.security_rounded,
        'label': 'Access Control',
        'color': Colors.redAccent,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PermissionsScreen())),
      },
      {
        'icon': Icons.broadcast_on_personal_rounded,
        'label': 'Global Alerts',
        'color': Colors.orangeAccent,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementScreen())),
      },
      {
        'icon': Icons.analytics_rounded,
        'label': 'Institution Stats',
        'color': Colors.teal,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SchoolAnalyticsScreen())),
      },
      {
        'icon': Icons.calendar_today_rounded,
        'label': 'Master Timetable',
        'color': Colors.cyan,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimetableManagerScreen())),
      },
    ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return GestureDetector(
          onTap: action['onTap'] as VoidCallback,
          child: PremiumCard(
            opacity: 1,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (action['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(action['icon'] as IconData, color: action['color'] as Color, size: 32),
                ),
                const SizedBox(height: 12),
                Text(
                  action['label'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary),
                ),
              ],
            ),
          ),
        ).animate().scale(delay: (index * 50).ms, curve: Curves.easeOutBack);
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Server Disconnect'),
        content: const Text('Are you sure you want to exit the Command Center?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Disconnect', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String label;
  final String collection;
  final String? filterField;
  final dynamic filterValue;
  final IconData icon;
  final Color color;

  const _AdminStatCard({
    required this.label,
    required this.collection,
    this.filterField,
    this.filterValue,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: (() {
        final baseQuery = FirebaseFirestore.instance.collection(collection);
        if (filterField != null) {
          return baseQuery.where(filterField!, isEqualTo: filterValue).snapshots();
        }
        return baseQuery.snapshots();
      })(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, spreadRadius: -5, offset: const Offset(0, 8))],
            border: Border.all(color: color.withOpacity(0.1), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned(right: -10, top: -10, child: Icon(icon, size: 70, color: color.withOpacity(0.05))),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: color, size: 24),
                          const Spacer(),
                          if (snapshot.connectionState == ConnectionState.waiting)
                            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('$count', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color, height: 1)),
                      const SizedBox(height: 4),
                      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _SystemHealthView extends StatelessWidget {
  const _SystemHealthView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Enterprise Health', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0F766E), Color(0xFF0D9488)]),
              borderRadius: BorderRadius.circular(20)
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 40),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('All Systems Operational', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('No critical bottlenecks detected', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                )
              ],
            ),
          ).animate().slideX(),
          const SizedBox(height: 20),
          const Text('Database Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          _HealthMetric(title: 'Firestore Sync', progress: 1.0, color: Colors.amber),
          _HealthMetric(title: 'Backend Load', progress: 0.15, color: Colors.blue),
          _HealthMetric(title: 'AI Thread Usage', progress: 0.45, color: Colors.purple),
          const SizedBox(height: 30),
          const Text('Recent System Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          ...List.generate(5, (index) => ListTile(
            leading: const Icon(Icons.data_array_rounded, color: Colors.grey),
            title: Text('API Request OK - /ai-predict-$index'),
            subtitle: Text('${DateTime.now().subtract(Duration(minutes: index * 4)).toString().substring(11, 16)} GMT'),
            dense: true,
          ))
        ],
      ),
    );
  }
}

class _HealthMetric extends StatelessWidget {
  final String title;
  final double progress;
  final Color color;

  const _HealthMetric({required this.title, required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('${(progress * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }
}

class _AdminSettingsView extends StatelessWidget {
  const _AdminSettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Panel Settings', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PremiumCard(
            opacity: 1,
            padding: const EdgeInsets.all(0),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings, color: Colors.blue),
                  title: const Text('Update Profile'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: (){},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_rounded, color: Colors.redAccent),
                  title: const Text('Firebase Security Rules'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: (){},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup_rounded, color: Colors.green),
                  title: const Text('System Backup'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: (){},
                ),
              ],
            ),
          ).animate().fadeIn(),
        ],
      ),
    );
  }
}

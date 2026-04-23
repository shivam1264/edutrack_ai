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
import '../admin/teacher_performance_screen.dart';
import '../admin/user_management_screen.dart';
import '../settings/profile_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../admin/school_analytics_screen.dart';
import '../admin/timetable_manager_screen.dart';
import '../admin/ai_risk_report_screen.dart';
import '../admin/system_settings_screen.dart';
import '../attendance/attendance_history_screen.dart';

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
          SystemSettingsScreen(),
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
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle, 
                                    gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.purpleAccent]),
                                    boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 15)]
                                  ),
                                  child: CircleAvatar(
                                    radius: 32,
                                    backgroundColor: const Color(0xFF0F172A),
                                    backgroundImage: user?.avatarUrl != null ? CachedNetworkImageProvider(user!.avatarUrl!) : null,
                                    child: user?.avatarUrl == null 
                                      ? const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 30)
                                      : null,
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
                              ],
                            ),
                          ),
                          const NotificationBell(userId: ''),
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
                    _AdminStatCard(label: 'Total Students', collection: 'users', filterField: 'role', filterValue: 'student', icon: Icons.people_alt_rounded, color: Colors.blue),
                    _AdminStatCard(label: 'Teachers Active', collection: 'users', filterField: 'role', filterValue: 'teacher', icon: Icons.school_rounded, color: Colors.purple),
                    _AdminStatCard(label: 'Active Classes', collection: 'classes', filterField: null, filterValue: null, icon: Icons.hub_rounded, color: Colors.amber),
                    _AdminStatCard(label: 'AI Predictions', collection: 'ai_predictions', filterField: 'risk_level', filterValue: 'high', icon: Icons.gpp_maybe_rounded, color: Colors.redAccent),
                  ],
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
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
        'icon': Icons.manage_accounts_rounded,
        'label': 'Manage Users',
        'color': const Color(0xFF0F172A),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen())),
      },
      {
        'icon': Icons.hub_rounded,
        'label': 'Manage Classes',
        'color': Colors.indigo,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassManagementScreen())),
      },
      {
        'icon': Icons.history_edu_rounded,
        'label': 'Attendance Archive',
        'color': const Color(0xFF0F172A),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendanceHistoryScreen(isAdmin: true))),
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
      {
        'icon': Icons.person_add_rounded,
        'label': 'Provision New',
        'color': Colors.blue,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddUserScreen())),
      },
      {
        'icon': Icons.gpp_maybe_rounded,
        'label': 'Risk Monitor',
        'color': Colors.redAccent,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIRiskReportScreen())),
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
        title: const Text('System Diagnostics', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildHealthStatusCard(),
          const SizedBox(height: 32),
          const Text('TELEMETRY REAL-TIME', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: Colors.grey)),
          const SizedBox(height: 16),
          _HealthMetricStream(
            label: 'Firestore Pulse', 
            collection: 'users', 
            icon: Icons.sync_rounded, 
            color: Colors.blueAccent,
            desc: 'Real-time database synchronization status'
          ),
          _HealthMetricStream(
            label: 'AI Inference Load', 
            collection: 'ai_predictions', 
            icon: Icons.auto_awesome_rounded, 
            color: Colors.purpleAccent,
            desc: 'Volume of predictive analysis threads'
          ),
          _HealthMetricStream(
            label: 'Network Latency', 
            collection: 'announcements', 
            icon: Icons.speed_rounded, 
            color: Colors.tealAccent,
            desc: 'Average response time for global packets'
          ),
          const SizedBox(height: 32),
          const Text('RECENT SECURITY LOGS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: Colors.grey)),
          const SizedBox(height: 16),
          _buildLogList(),
        ],
      ),
    );
  }

  Widget _buildHealthStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.shield_rounded, color: Colors.greenAccent, size: 32),
          ),
          const SizedBox(width: 20),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CORE SECURE', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                Text('All systems operating at 100% efficiency', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    return PremiumCard(
      opacity: 1,
      padding: EdgeInsets.zero,
      child: Column(
        children: List.generate(4, (index) => ListTile(
          leading: Icon(index == 0 ? Icons.security_rounded : Icons.info_outline_rounded, 
                 color: index == 0 ? Colors.greenAccent : Colors.grey, size: 18),
          title: Text(index == 0 ? 'Admin Session Validated' : 'Access Log: Fetch users/$index', 
                 style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text('${index * 2} minutes ago', style: const TextStyle(fontSize: 11)),
          dense: true,
        )),
      ),
    );
  }
}

class _HealthMetricStream extends StatelessWidget {
  final String label;
  final String collection;
  final IconData icon;
  final Color color;
  final String desc;

  const _HealthMetricStream({required this.label, required this.collection, required this.icon, required this.color, required this.desc});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        final progress = (count / 100).clamp(0.1, 1.0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: PremiumCard(
            opacity: 1,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 12),
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    const Spacer(),
                    Text('${(progress * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.w900, color: color)),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withOpacity(0.05),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerLeft, child: Text(desc, style: const TextStyle(fontSize: 10, color: Colors.grey))),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../add_student_screen.dart';
import '../add_teacher_screen.dart';
import '../add_admin_screen.dart';
import '../add_parent_screen.dart';
import '../class_management_screen.dart';
import '../announcement_screen.dart';
import '../admin_students_screen.dart';
import '../admin_teachers_screen.dart';
import '../ai_risk_report_screen.dart';
import '../user_management_screen.dart';

class AdminHomeView extends StatelessWidget {
  const AdminHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildHeader(context, user),
        
        // ─── AI Risk Sentinel ──────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: _buildRiskSentinel(context),
          ),
        ),

        // ─── Core Management Metrics ─────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.55, // Increased aspect ratio to avoid overflow
            ),
            delegate: SliverChildListDelegate([
              _MetricBox(
                label: 'Student Hub',
                collection: 'users',
                filterField: 'role',
                filterValue: 'student',
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF3B82F6),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen())),
              ),
              _MetricBox(
                label: 'Faculty Pool',
                collection: 'users',
                filterField: 'role',
                filterValue: 'teacher',
                icon: Icons.school_rounded,
                color: const Color(0xFF8B5CF6),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen())),
              ),
              _MetricBox(
                label: 'Active Units',
                collection: 'classes',
                icon: Icons.hub_rounded,
                color: const Color(0xFFF59E0B),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassManagementScreen())),
              ),
              _MetricBox(
                label: 'System Alerts',
                collection: 'announcements',
                icon: Icons.campaign_rounded,
                color: const Color(0xFF10B981),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementScreen())),
              ),
            ]),
          ),
        ),

        // ─── Administration Hub ──────────────────────────────────
        SliverToBoxAdapter(
          child: _buildAdminActions(context),
        ),

        // ─── Recent Intelligence ──────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_toggle_off_rounded, size: 20, color: AppTheme.textHint),
                    SizedBox(width: 8),
                    Text('Administrative Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRecentAlerts(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, user) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                Text('Welcome back, ${user?.name ?? "Principal"}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white70),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildRiskSentinel(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIRiskReportScreen())),
      child: PremiumCard(
        opacity: 1,
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.redAccent.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.gpp_maybe_rounded, color: Colors.redAccent),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI RISK SENTINEL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2, color: Colors.redAccent)),
                    Text('Analyzing behavioral patterns...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildAdminActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text('Administrative Hub', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            children: [
              _ActionTile(label: 'Add Student', icon: Icons.person_add_rounded, color: Colors.blue, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStudentScreen()))),
              _ActionTile(label: 'Add Teacher', icon: Icons.school_rounded, color: Colors.purple, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTeacherScreen()))),
              _ActionTile(label: 'Add Parent', icon: Icons.family_restroom_rounded, color: Colors.green, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddParentScreen()))),
              _ActionTile(label: 'Add Admin', icon: Icons.admin_panel_settings_rounded, color: Colors.indigo, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAdminScreen()))),
              _ActionTile(label: 'Manage Unit', icon: Icons.hub_rounded, color: Colors.amber, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassManagementScreen()))),
              _ActionTile(label: 'Broadcast', icon: Icons.send_rounded, color: Colors.orange, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementScreen()))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAlerts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('announcements').orderBy('createdAt', descending: true).limit(3).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();
        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.orange),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['title'] ?? 'System Broadcast', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Text(data['content'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Text('Recently', style: TextStyle(color: Colors.grey, fontSize: 10)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String collection;
  final String? filterField;
  final dynamic filterValue;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MetricBox({required this.label, required this.collection, this.filterField, this.filterValue, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: PremiumCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reduced vertical padding
        child: StreamBuilder<QuerySnapshot>(
          stream: filterField != null 
              ? FirebaseFirestore.instance.collection(collection).where(filterField!, isEqualTo: filterValue).snapshots()
              : FirebaseFirestore.instance.collection(collection).snapshots(),
          builder: (context, snapshot) {
            final count = snapshot.data?.docs.length ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Use min size
              children: [
                Icon(icon, color: color, size: 20), // Reduced icon size
                const SizedBox(height: 4), // Reduced spacing
                Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
                Text(label, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: color.withOpacity(0.1)),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}

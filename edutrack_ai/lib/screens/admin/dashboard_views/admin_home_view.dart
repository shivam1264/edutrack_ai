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
                Row(
                  children: [
                    const Icon(Icons.history_toggle_off_rounded, size: 20, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    Text('Administrative Logs', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
      expandedHeight: 180,
      pinned: true,
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                ),
              ),
            ),
            Positioned(
              top: -20, right: -20,
              child: Icon(Icons.shield_rounded, color: const Color(0xFF6366F1).withOpacity(0.05), size: 220),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SCHOOL ADMINISTRATOR', style: TextStyle(color: Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 2),
                  const Text('Elite Dashboard', style: TextStyle(color: Color(0xFF0F172A), fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  const SizedBox(height: 4),
                  const Text('Real-time system oversight and metrics', style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0F172A),
                backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                child: user?.avatarUrl == null 
                  ? const Icon(Icons.person_outline, color: Color(0xFF0F172A), size: 20)
                  : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskSentinel(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIRiskReportScreen())),
      child: PremiumCard(
        opacity: 1,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF43F5E)]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI BEHAVIORAL SENTINEL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.2, color: Color(0xFFEF4444))),
                  const SizedBox(height: 2),
                  Text('Analyzing behavioral patterns for 424 students...', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.1));
  }

  Widget _buildAdminActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text('Administrative Center', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)),
        ),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            children: [
              _ActionTile(label: 'Add Student', icon: Icons.person_add_rounded, color: const Color(0xFF3B82F6), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStudentScreen()))),
              _ActionTile(label: 'Add Teacher', icon: Icons.school_rounded, color: const Color(0xFF8B5CF6), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTeacherScreen()))),
              _ActionTile(label: 'Add Parent', icon: Icons.family_restroom_rounded, color: const Color(0xFF10B981), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddParentScreen()))),
              _ActionTile(label: 'Add Admin', icon: Icons.admin_panel_settings_rounded, color: const Color(0xFF6366F1), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAdminScreen()))),
              _ActionTile(label: 'Units', icon: Icons.hub_rounded, color: const Color(0xFFF59E0B), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassManagementScreen()))),
              _ActionTile(label: 'Broadcast', icon: Icons.campaign_rounded, color: const Color(0xFFF43F5E), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementScreen()))),
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
                          Text(data['title'] ?? 'System Broadcast', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
                          Text(data['content'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                        ],
                      ),
                    ),
                    const Text('Recently', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
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
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 6)),
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.2)),
        ],
      ),
    );
  }
}

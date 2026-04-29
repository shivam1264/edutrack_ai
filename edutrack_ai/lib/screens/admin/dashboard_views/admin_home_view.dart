import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:edutrack_ai/l10n/app_localizations.dart';

import '../../../providers/auth_provider.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/premium_card.dart';
import '../add_admin_screen.dart';
import '../add_parent_screen.dart';
import '../add_student_screen.dart';
import '../add_teacher_screen.dart';
import '../ai_risk_report_screen.dart';
import '../announcement_screen.dart';
import '../class_management_screen.dart';
import '../user_management_screen.dart';
import '../bulk_import_screen.dart';

class AdminHomeView extends StatelessWidget {
  const AdminHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _buildHeader(user, context),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _buildRiskSentinel(context),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
            ),
            delegate: SliverChildListDelegate([
              _MetricBox(
                label: AppLocalizations.of(context)!.students,
                collection: 'users',
                filterField: 'role',
                filterValue: 'student',
                icon: Icons.people_alt_rounded,
                color: AppTheme.primary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                ),
              ),
              _MetricBox(
                label: 'Teachers',
                collection: 'users',
                filterField: 'role',
                filterValue: 'teacher',
                icon: Icons.school_rounded,
                color: AppTheme.accent,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserManagementScreen()),
                ),
              ),
              _MetricBox(
                label: 'Classes',
                collection: 'classes',
                icon: Icons.hub_rounded,
                color: AppTheme.warning,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ClassManagementScreen(),
                  ),
                ),
              ),
              _MetricBox(
                label: 'Broadcasts',
                collection: 'announcements',
                icon: Icons.campaign_rounded,
                color: AppTheme.secondary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnnouncementScreen()),
                ),
              ),
            ]),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildAdminActions(context),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Administrative Logs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Recent school-wide communication activity.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
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

  Widget _buildHeader(dynamic user, BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.adminDashboard,
                  style: const TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'School Operations Dashboard',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'System oversight, people management, and alerts.',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.surfaceSubtle,
            foregroundColor: AppTheme.adminColor,
            backgroundImage:
                user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
            child: user?.avatarUrl == null
                ? const Icon(Icons.person_outline, size: 22)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildRiskSentinel(BuildContext context) {
    return PremiumCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AIRiskReportScreen()),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppTheme.danger,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Risk Monitor',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Review high-priority behavioral and academic signals.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textHint,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    final actions = [
      {
        'label': 'Add Student',
        'icon': Icons.person_add_rounded,
        'color': AppTheme.primary,
        'screen': const AddStudentScreen(),
      },
      {
        'label': 'Bulk Import',
        'icon': Icons.group_add_rounded,
        'color': AppTheme.primary,
        'screen': const BulkImportScreen(),
      },
      {
        'label': 'Add Teacher',
        'icon': Icons.school_rounded,
        'color': AppTheme.accent,
        'screen': const AddTeacherScreen(),
      },
      {
        'label': 'Add Parent',
        'icon': Icons.family_restroom_rounded,
        'color': AppTheme.secondary,
        'screen': const AddParentScreen(),
      },
      {
        'label': 'Add Admin',
        'icon': Icons.admin_panel_settings_rounded,
        'color': AppTheme.info,
        'screen': const AddAdminScreen(),
      },
      {
        'label': 'Classes',
        'icon': Icons.hub_rounded,
        'color': AppTheme.warning,
        'screen': const ClassManagementScreen(),
      },
      {
        'label': 'Broadcast',
        'icon': Icons.campaign_rounded,
        'color': AppTheme.danger,
        'screen': const AnnouncementScreen(),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.quickActions,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Create records and manage core school entities.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (context, index) {
            final action = actions[index];
            return PremiumCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => action['screen']! as Widget),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (action['color']! as Color).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      action['icon']! as IconData,
                      color: action['color']! as Color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    action['label']! as String,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentAlerts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .limit(6)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const PremiumCard(
            child: Text(
              'No recent logs available.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['created_at'] as Timestamp?;
          final bTime = bData['created_at'] as Timestamp?;
          return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
        });

        return Column(
          children: docs.take(3).map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppTheme.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title'] ?? 'System Broadcast',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['content'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Recent',
                      style: TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 11,
                      ),
                    ),
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

  const _MetricBox({
    required this.label,
    required this.collection,
    this.filterField,
    this.filterValue,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<QuerySnapshot>(
        stream: filterField != null
            ? FirebaseFirestore.instance
                  .collection(collection)
                  .where(filterField!, isEqualTo: filterValue)
                  .snapshots()
            : FirebaseFirestore.instance.collection(collection).snapshots(),
        builder: (context, snapshot) {
          final count = snapshot.data?.docs.length ?? 0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

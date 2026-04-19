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

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: AppTheme.danger,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white),
                onPressed: () => _showLogoutDialog(context),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(decoration: const BoxDecoration(gradient: AppTheme.meshGradient)),
                  Positioned(
                    top: -10,
                    right: -10,
                    child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white.withOpacity(0.1), size: 180),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Admin Center',
                                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    'Logged in as ${user?.name ?? 'Head Administrator'}',
                                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
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
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // System Summary Text
                const Text('System Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),

                // Real-time Stats
                Row(
                  children: [
                    Expanded(
                      child: _AdminStatCard(
                        label: 'Students',
                        collection: 'students',
                        icon: Icons.people_alt_rounded,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _AdminStatCard(
                        label: 'Teachers',
                        collection: 'teachers',
                        icon: Icons.school_rounded,
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ).animate().fadeIn().scale(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _AdminStatCard(
                        label: 'Hubs',
                        collection: 'classes',
                        icon: Icons.hub_rounded,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _AdminStatCard(
                        label: 'Threats',
                        collection: 'ai_predictions',
                        filterField: 'risk_level',
                        filterValue: 'high',
                        icon: Icons.gpp_maybe_rounded,
                        color: AppTheme.danger,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms).scale(),

                const SizedBox(height: 32),

                // Management Console
                const Text('Management Console', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                const SizedBox(height: 16),
                _buildAdminActions(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context) {
    final actions = [
      {
        'icon': Icons.person_add_rounded,
        'label': 'Provision User',
        'subtitle': 'Deploy new student or staff access',
        'color': AppTheme.primary,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddUserScreen())),
      },
      {
        'icon': Icons.hub_rounded,
        'label': 'Manage Hubs',
        'subtitle': 'Configure classes and assignments',
        'color': AppTheme.secondary,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassManagementScreen())),
      },
      {
        'icon': Icons.insights_rounded,
        'label': 'Intelligence',
        'subtitle': 'View school-wide AI analytics',
        'color': const Color(0xFF8B5CF6),
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
      },
      {
        'icon': Icons.security_rounded,
        'label': 'Permissions',
        'subtitle': 'Audit and adjust access protocols',
        'color': AppTheme.danger,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PermissionsScreen())),
      },
      {
        'icon': Icons.broadcast_on_personal_rounded,
        'label': 'Broadcasting',
        'subtitle': 'Send global system alerts',
        'color': AppTheme.accent,
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementScreen())),
      },
      {
        'icon': Icons.refresh_rounded,
        'label': 'Calibrate AI',
        'subtitle': 'Sync neural prediction metrics',
        'color': AppTheme.warning,
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calibrating AI engines...')));
        },
      },
    ];

    return Column(
      children: actions.asMap().entries.map((entry) {
        final i = entry.key;
        final action = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: action['onTap'] as VoidCallback,
            child: PremiumCard(
              opacity: 1,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: (action['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: Icon(action['icon'] as IconData, color: action['color'] as Color, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(action['label'] as String, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textPrimary)),
                        const SizedBox(height: 2),
                        Text(action['subtitle'] as String, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.1),
        );
      }).toList(),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exit Console?'),
        content: const Text('Confirm secure sign-out from Admin Control?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
        return PremiumCard(
          opacity: 1,
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        );
      },
    );
  }
}

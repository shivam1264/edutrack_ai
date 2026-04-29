import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:edutrack_ai/l10n/app_localizations.dart';

import 'package:edutrack_ai/models/knowledge_node.dart';
import 'package:edutrack_ai/providers/analytics_provider.dart';
import 'package:edutrack_ai/providers/auth_provider.dart';
import 'package:edutrack_ai/providers/gamification_provider.dart';
import 'package:edutrack_ai/screens/assignments/student_assignments_screen.dart';
import 'package:edutrack_ai/screens/student/academic_calendar_screen.dart';
import 'package:edutrack_ai/screens/student/dashboard_views/progress_view.dart';
import 'package:edutrack_ai/screens/student/global_search_screen.dart';
import 'package:edutrack_ai/screens/student/notifications_screen.dart';
import 'package:edutrack_ai/services/brain_dna_service.dart';
import 'package:edutrack_ai/utils/app_theme.dart';
import 'package:edutrack_ai/widgets/brain_dna_visualizer.dart';
import 'package:edutrack_ai/widgets/premium_card.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    // Check and generate Learning DNA after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final userId = auth.user?.uid ?? '';
      _checkAndGenerateDNA(userId);
    });
  }

  Future<void> _checkAndGenerateDNA(String userId) async {
    if (userId.isEmpty) return;
    
    try {
      // Check if DNA already exists
      final dnaSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('brain_dna')
          .limit(1)
          .get();
      
      // If no DNA exists, generate from existing quiz/assignment data
      if (dnaSnap.docs.isEmpty) {
        debugPrint('No Learning DNA found for $userId, generating from existing data...');
        await BrainDNAService.instance.generateDNAFromExistingData(userId);
      }
    } catch (e) {
      debugPrint('Error checking/generating DNA: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final gamify = context.watch<GamificationProvider>();
    final userId = user?.uid ?? '';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
          );
        },
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.search, color: Colors.white),
        label: Text(
          l10n.search,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  _buildHeader(context, user, gamify),
                  const SizedBox(height: 20),
                  _buildOverview(gamify, context),
                  const SizedBox(height: 20),
                  _buildCalendarShortcut(context),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                    l10n.learningDNA,
                    l10n.seeStrengthsDeveloping,
                    l10n.openProgress,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProgressView()),
                      );
                    },
                    trailing: IconButton(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.syncingLearningDNA)),
                        );
                        await BrainDNAService.instance.generateDNAFromExistingData(userId);
                        setState(() {}); // Refresh UI
                      },
                      icon: const Icon(Icons.sync, color: AppTheme.primary, size: 20),
                      tooltip: l10n.syncDnaFromHistory,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PremiumCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 280,
                          child: StreamBuilder<List<KnowledgeNode>>(
                            stream: BrainDNAService.instance.getBrainDNA(userId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 12),
                                      Text(
                                        l10n.loadingYourLearningDNA,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              final nodes = snapshot.data ?? [];
                              if (nodes.isEmpty) {
                                return _buildEmptyDNA(context);
                              }
                              return Center(
                                child: BrainDNAVisualizer(
                                  nodes: nodes,
                                  size: 260,
                                  enableInteractions: true,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Legend
                        _buildDNALegend(context),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildSectionHeader(
                    l10n.performanceSummary,
                    l10n.academicAssignmentProgress,
                    l10n.viewDetails,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProgressView()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildLearningDNA(context),
                  const SizedBox(height: 28),
                  _buildSectionHeader(
                    l10n.pendingWork,
                    l10n.assignmentsNeedAttention,
                    l10n.viewAssignments,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StudentAssignmentsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildContinueLearning(context, user?.classId ?? ''),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    dynamic user,
    GamificationProvider gamify,
  ) {
    final progress = gamify.progressToNextLevel;

    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.studentDashboard,
                      style: const TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${AppLocalizations.of(context)!.welcomeBack}, ${user?.name.split(' ').first ?? 'Student'}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.dailyOverviewReady,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Stack(
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                      // Notification badge (show if there are notifications)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryLight,
                backgroundImage:
                    user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
                child: user?.avatarUrl == null
                    ? const Icon(Icons.person_outline, color: AppTheme.primary)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderLight),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppLocalizations.of(context)!.level} ${gamify.user?.level ?? 1}',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${gamify.user?.xp ?? 0} / ${gamify.xpToNextLevel} ${AppLocalizations.of(context)!.xp}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppTheme.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(GamificationProvider gamify, BuildContext ctx) {
    final classId = gamify.user?.classId ?? '';

    return Row(
      children: [
        Consumer<AnalyticsProvider>(
          builder: (context, analytics, _) {
            final avg = (analytics.studentAnalytics?['avg_score'] as num?)
                ?.toDouble();
            return _StatCard(
              label: AppLocalizations.of(context)!.average,
              value: avg == null ? 'N/A' : '${avg.toStringAsFixed(0)}%',
              icon: Icons.track_changes_rounded,
              color: AppTheme.primary,
            );
          },
        ),
        const SizedBox(width: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('assignments')
              .where('class_id', isEqualTo: classId)
              .snapshots(),
          builder: (context, snapshot) {
            final count = snapshot.data?.docs.length ?? 0;
            return _StatCard(
              label: AppLocalizations.of(context)!.tasks,
              value: '$count',
              icon: Icons.assignment_outlined,
              color: AppTheme.secondary,
            );
          },
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: AppLocalizations.of(ctx)!.streak,
          value: '${gamify.user?.streak ?? 0}',
          icon: Icons.local_fire_department_rounded,
          color: AppTheme.warning,
        ),
      ],
    );
  }

  Widget _buildCalendarShortcut(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AcademicCalendarScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.academicCalendar,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.viewAllAssignmentsQuizzesNotesByDate,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.primary,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String subtitle,
    String actionLabel,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
        TextButton(onPressed: onTap, child: Text(actionLabel)),
      ],
    );
  }

  Widget _buildContinueLearning(BuildContext context, String classId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('assignments')
          .where('class_id', isEqualTo: classId)
          .limit(2)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(
              l10n.allCaughtUp,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          );
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assignment_outlined,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title'] ?? l10n.assignment,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['subject'] ?? l10n.subject,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StudentAssignmentsScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.borderStrong),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.open,
                        style: const TextStyle(fontWeight: FontWeight.w700),
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

  Widget _buildLearningDNA(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();
    final data = analytics.studentAnalytics;
    final avg = (data?['avg_score'] as num?)?.toDouble() ?? 0.0;
    final completion = (data?['course_completion'] as num?)?.toDouble() ?? 0.0;

    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildMetricRow(
            AppLocalizations.of(context)!.quizAverage,
            '${avg.toStringAsFixed(0)}%',
            avg / 100,
            AppTheme.primary,
          ),
          const SizedBox(height: 18),
          _buildMetricRow(
            AppLocalizations.of(context)!.assignmentsProgress,
            '${completion.toStringAsFixed(0)}%',
            completion / 100,
            AppTheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    String label,
    String value,
    double progress,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppTheme.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildDNALegend(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(const Color(0xFF10B981), l10n.mastered, '≥80%'),
          _buildLegendItem(const Color(0xFFF59E0B), l10n.learning, '50-80%'),
          _buildLegendItem(const Color(0xFFEF4444), l10n.focus, '<50%'),
          _buildLegendItem(Colors.grey, l10n.review, 'Low'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, String range) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              range,
              style: TextStyle(
                fontSize: 8,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyDNA(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary.withOpacity(0.2),
                  AppTheme.primary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology_outlined,
              size: 40,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.yourLearningDNAIsForming,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.completeAssignmentsAndQuizzesToBuild,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PremiumCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

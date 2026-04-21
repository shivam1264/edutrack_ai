import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final classId = user?.classId ?? '';
    final today = _getDayName(DateTime.now().weekday);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF0F766E),
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(decoration: const BoxDecoration(gradient: AppTheme.meshGradient)),
                  Positioned(
                    top: -10, right: -10,
                    child: Icon(Icons.schedule_rounded, color: Colors.white.withOpacity(0.1), size: 180),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Daily Schedule', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                        Row(
                          children: [
                            const Icon(Icons.event_available_rounded, color: Colors.white70, size: 14),
                            const SizedBox(width: 8),
                            Text('Today is $today', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _TimetableBody(classId: classId, today: today),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
}

class _TimetableBody extends StatefulWidget {
  final String classId;
  final String today;

  const _TimetableBody({required this.classId, required this.today});

  @override
  State<_TimetableBody> createState() => _TimetableBodyState();
}

class _TimetableBodyState extends State<_TimetableBody> {
  late String _selectedDay;
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    _selectedDay = _days.contains(widget.today) ? widget.today : 'Monday';
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          // High-end Day selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final day = _days[i];
                  final selected = day == _selectedDay;
                  final isToday = day == widget.today;
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: selected ? AppTheme.meshGradient : null,
                        color: selected ? null : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isToday && !selected ? Border.all(color: const Color(0xFF0F766E), width: 1.5) : null,
                        boxShadow: selected ? [BoxShadow(color: const Color(0xFF0F766E).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
                      ),
                      child: Center(
                        child: Text(
                          day.substring(0, 3).toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 12,
                            letterSpacing: 0.5,
                            color: selected ? Colors.white : AppTheme.textHint,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ).animate().fadeIn().slideX(begin: 0.1),
          
          const SizedBox(height: 12),
          
          // Periods List
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('timetable')
                .doc(widget.classId)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || !snap.data!.exists) {
                return Padding(
                  padding: const EdgeInsets.all(80),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy_rounded, size: 64, color: AppTheme.textHint.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      const Text('Schedule Unavailable', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textHint)),
                      const SizedBox(height: 8),
                      const Text('No data synced for this sector yet.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textHint, fontSize: 12)),
                    ],
                  ),
                );
              }
              final data = snap.data!.data() as Map<String, dynamic>;
              final periods = (data[_selectedDay] as List<dynamic>?) ?? [];
              
              if (periods.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(60),
                  child: Column(
                    children: [
                      const Icon(Icons.celebration_rounded, size: 64, color: AppTheme.secondary),
                      const SizedBox(height: 16),
                      Text('Free Day Sector!', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.secondary, fontSize: 18)),
                      const Text('No missions assigned for today.', style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
                    ],
                  ),
                ).animate().scale();
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: periods.length,
                itemBuilder: (context, i) {
                  final p = periods[i] as Map<String, dynamic>;
                  return _TimelineNode(period: p, index: i, isLast: i == periods.length - 1)
                      .animate().fadeIn(delay: (i * 100).ms).slideY(begin: 0.2);
                },
              );
            },
          ),
        ]),
      ),
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final Map<String, dynamic> period;
  final int index;
  final bool isLast;

  const _TimelineNode({required this.period, required this.index, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF6366F1), const Color(0xFF0F766E), const Color(0xFFFF6B35),
      const Color(0xFF7C3AED), const Color(0xFFEF4444), const Color(0xFF059669),
      const Color(0xFFF59E0B), const Color(0xFF3B82F6),
    ];
    final color = colors[index % colors.length];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time Panel
          SizedBox(
            width: 65,
            child: Column(
              children: [
                Text(period['startTime'] ?? '00:00', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(period['endTime'] ?? '00:00', style: const TextStyle(color: AppTheme.textHint, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 12, height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 4)]),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(1)))),
            ],
          ),
          const SizedBox(width: 16),
          
          // Lesson Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: PremiumCard(
                opacity: 1,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                      child: Icon(Icons.hub_rounded, color: color, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(period['subject'] ?? 'System Sync', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textPrimary, fontSize: 15)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 12, color: AppTheme.textHint),
                              const SizedBox(width: 4),
                              Text(period['teacher'] ?? 'AI Faculty', style: const TextStyle(fontSize: 11, color: AppTheme.textHint, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          if (period['room'] != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textHint),
                                const SizedBox(width: 4),
                                Text('Sector ${period['room']}', style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

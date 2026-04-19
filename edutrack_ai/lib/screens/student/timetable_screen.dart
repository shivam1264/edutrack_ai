import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF0F766E),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -10, right: -10,
                      child: Icon(Icons.calendar_today_rounded, color: Colors.white.withOpacity(0.1), size: 180),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Timetable', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                          Text('Today is $today', style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
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
    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Day selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final selected = _days[i] == _selectedDay;
                  final isToday = _days[i] == widget.today;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = _days[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFF0F766E) : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: isToday && !selected ? Border.all(color: const Color(0xFF0F766E), width: 2) : null,
                        boxShadow: selected ? [BoxShadow(color: const Color(0xFF0F766E).withOpacity(0.3), blurRadius: 8)] : [],
                      ),
                      child: Text(
                        _days[i].substring(0, 3) + (isToday ? ' •' : ''),
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13,
                            color: selected ? Colors.white : const Color(0xFF0F766E)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Periods
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('timetable')
                .doc(widget.classId)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData || !snap.data!.exists) {
                return const Padding(
                  padding: EdgeInsets.all(60),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No timetable set yet.\nAsk your admin to configure it.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              final data = snap.data!.data() as Map<String, dynamic>;
              final periods = (data[_selectedDay] as List<dynamic>?) ?? [];
              if (periods.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Text('No classes on this day 🎉', style: TextStyle(color: Colors.grey, fontSize: 16)),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: periods.length,
                itemBuilder: (context, i) {
                  final p = periods[i] as Map<String, dynamic>;
                  return _PeriodCard(period: p, index: i)
                      .animate().fadeIn(delay: (i * 80).ms).slideX(begin: 0.3);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final Map<String, dynamic> period;
  final int index;

  const _PeriodCard({required this.period, required this.index});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF6366F1), const Color(0xFF0F766E), const Color(0xFFFF6B35),
      const Color(0xFF7C3AED), const Color(0xFFEF4444), const Color(0xFF059669),
      const Color(0xFFF59E0B), const Color(0xFF3B82F6),
    ];
    final color = colors[index % colors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Column(
              children: [
                Text(period['startTime'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                Text(period['endTime'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 4, height: 80, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 12),
          Expanded(
            child: PremiumCard(
              opacity: 1,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.school_rounded, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(period['subject'] ?? 'Subject', style: const TextStyle(
                            fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
                        Text(period['teacher'] ?? '', style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                        if (period['room'] != null)
                          Text('Room: ${period['room']}', style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

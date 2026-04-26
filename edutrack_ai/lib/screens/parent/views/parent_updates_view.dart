import 'package:flutter/material.dart';
import '../../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ParentUpdatesView extends StatelessWidget {
  const ParentUpdatesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Updates', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              isScrollable: true,
              labelColor: Color(0xFFF97316),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFFF97316),
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'All'),
                Tab(text: 'Notices'),
                Tab(text: 'Messages'),
                Tab(text: 'Alerts'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildUpdatesList(),
                  const Center(child: Text('Notices')),
                  const Center(child: Text('Messages')),
                  const Center(child: Text('Alerts')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdatesList() {
    final updates = [
      {'type': 'Notice', 'title': 'School Notice', 'msg': 'Annual Sports Day on April 30.', 'time': '2h ago', 'icon': Icons.campaign_rounded, 'color': Colors.orange},
      {'type': 'Assignment', 'title': 'New Assignment', 'msg': 'Math Homework - Chapter 5', 'time': '5h ago', 'icon': Icons.assignment_rounded, 'color': Colors.blue},
      {'type': 'Alert', 'title': 'Fee Reminder', 'msg': 'April month fees due on May 5.', 'time': '1d ago', 'icon': Icons.payments_rounded, 'color': Colors.red},
      {'type': 'Message', 'title': 'Teacher Message', 'msg': 'DI participated well in Science activity.', 'time': '2d ago', 'icon': Icons.chat_bubble_rounded, 'color': Colors.green},
      {'type': 'Notice', 'title': 'Holiday Notice', 'msg': 'School will remain closed on May 1.', 'time': '3d ago', 'icon': Icons.holiday_village_rounded, 'color': Colors.amber},
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: updates.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) {
        final u = updates[i];
        return PremiumCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: (u['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(u['icon'] as IconData, color: u['color'] as Color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(u['msg'] as String, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
              Text(u['time'] as String, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.1);
      },
    );
  }
}

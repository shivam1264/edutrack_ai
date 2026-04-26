import 'package:flutter/material.dart';
import '../../../widgets/premium_card.dart';
import '../../../utils/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ParentChildView extends StatelessWidget {
  const ParentChildView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Student Profile', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert_rounded), onPressed: () {}),
        ],
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            _buildProfileHeader(),
            const TabBar(
              labelColor: Color(0xFFF97316),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFFF97316),
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Academics'),
                Tab(text: 'Wellness'),
                Tab(text: 'Activity'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildOverviewTab(),
                  const Center(child: Text('Academics Tab')),
                  const Center(child: Text('Wellness Tab')),
                  const Center(child: Text('Activity Tab')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage('https://api.dicebear.com/7.x/avataaars/png?seed=Felix'),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DI', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const Text('Grade 5 • Roll No. 15', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const Text('EduTrack Primary Hub', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Text('Active', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About DI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: [
              _infoTile('Date of Birth', 'May 12, 2014'),
              const SizedBox(width: 24),
              _infoTile('Blood Group', 'O+'),
            ],
          ),
          const SizedBox(height: 20),
          _infoTile('School', 'EduTrack Primary Hub'),
          const SizedBox(height: 32),
          PremiumCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: Color(0xFFF97316), child: Icon(Icons.person, color: Colors.white)),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Class Teacher', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('Ms. Priya Sharma', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFF97316)), onPressed: () {}),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('Quick Stats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: [
              _statBox('85%', 'Avg Score', Colors.green),
              const SizedBox(width: 12),
              _statBox('8/32', 'Class Rank', Colors.blue),
              const SizedBox(width: 12),
              _statBox('B+', 'Overall Grade', Colors.purple),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.1))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology_rounded, color: Color(0xFF6366F1)),
                    const SizedBox(width: 12),
                    const Text("DI's Strength", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                  ],
                ),
                const SizedBox(height: 12),
                const Text("DI is a quick learner and shows great curiosity in science activities.", style: TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _statBox(String val, String label, Color color) {
    return Expanded(
      child: PremiumCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'user_management_screen.dart';
import 'class_management_screen.dart';
import 'reports_screen.dart';
import 'ai_risk_report_screen.dart';

class DataManagementScreen extends StatelessWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
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
                        colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0), Color(0xFFCBD5E1)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -20, right: -20,
                    child: Icon(Icons.storage_rounded, color: const Color(0xFF334155).withOpacity(0.05), size: 220),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Data Management', style: TextStyle(color: Color(0xFF0F172A), fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                        SizedBox(height: 4),
                        Text('System integrity and collection metrics', style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
          _buildSectionHeader('SYSTEM STORAGE OVERVIEW'),
          const SizedBox(height: 16),
          _buildUsageStats(),
          const SizedBox(height: 32),
          _buildSectionHeader('COLLECTION METRICS (TAP TO VIEW)'),
          const SizedBox(height: 16),
          _buildCollectionCard(
            context,
            'Users & Roles', 
            'users', 
            Icons.people_rounded, 
            Colors.blue,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementScreen())),
          ),
          _buildCollectionCard(
            context,
            'Academic Content', 
            'classes', 
            Icons.hub_rounded, 
            Colors.purple,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClassManagementScreen())),
          ),
          _buildCollectionCard(
            context,
            'Student Submissions', 
            'submissions', 
            Icons.upload_file_rounded, 
            Colors.orange,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
          ),
          _buildCollectionCard(
            context,
            'Attendance Logs', 
            'attendance', 
            Icons.fact_check_rounded, 
            Colors.green,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())),
          ),
          _buildCollectionCard(
            context,
            'AI Intelligence Data', 
            'ai_predictions', 
            Icons.psychology_rounded, 
            Colors.red,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AIRiskReportScreen())),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('DATA OPERATIONS'),
          const SizedBox(height: 16),
          _buildOperationTile(
            context,
            'Optimize Database',
            'Remove redundant logs and optimize indexes',
            Icons.speed_rounded,
            Colors.teal,
          ),
          _buildOperationTile(
            context,
            'Export School Data',
            'Generate a full CSV backup of school records',
            Icons.download_rounded,
            Colors.blue,
          ),
          const SizedBox(height: 100),
        ])),
      ),
    ],
  ),
);
}

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5, color: Colors.grey),
    );
  }

  Widget _buildUsageStats() {
    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Cloud Integrity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Storage Used', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const Text('1.2 GB', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Uptime', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const Text('99.9%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(
              value: 0.12,
              minHeight: 10,
              backgroundColor: AppTheme.bgLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          const Text('12% of free tier quota consumed', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildCollectionCard(BuildContext context, String title, String collection, IconData icon, Color color, VoidCallback onTap) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: PremiumCard(
              opacity: 1,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Collection: $collection', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text('$count', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOperationTile(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  const SizedBox(width: 16),
                  Text('Starting: $title...'),
                ],
              ),
              backgroundColor: const Color(0xFF0F172A),
            ),
          );
        },
        child: PremiumCard(
          opacity: 1,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../announcement_screen.dart';

class AdminAlertsView extends StatelessWidget {
  const AdminAlertsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Global Alerts', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert_rounded), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('announcements').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final alerts = snapshot.data?.docs ?? [];
          
          if (alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text('No global alerts found', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: alerts.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final data = alerts[index].data() as Map<String, dynamic>;
              final isCritical = data['priority'] == 'High' || data['priority'] == 'Critical';
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isCritical ? Colors.red : Colors.blue).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCritical ? Icons.gpp_maybe_rounded : Icons.info_outline_rounded,
                          color: isCritical ? Colors.red : Colors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isCritical ? 'Critical Warning' : 'System Notice',
                                  style: TextStyle(
                                    color: isCritical ? Colors.red : Colors.blue,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(data['category'] ?? 'General', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['title'] ?? 'New Alert',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['content'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                TextButton(onPressed: () {}, child: const Text('Resolve')),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnnouncementScreen())), 
                                  child: const Text('Edit'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1),
              );
            },
          );
        },
      ),
    );
  }
}

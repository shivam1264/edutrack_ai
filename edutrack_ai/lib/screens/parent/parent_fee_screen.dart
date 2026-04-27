import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ParentFeeScreen extends StatelessWidget {
  const ParentFeeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final parent = context.watch<AuthProvider>().user;
    final childId = (parent?.parentOf != null && parent!.parentOf!.isNotEmpty)
        ? parent.parentOf!.first
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Fee Management', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: childId == null
          ? const Center(child: Text('No student linked'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('fees')
                  .where('student_id', isEqualTo: childId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                final records = docs
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .toList()
                  ..sort((a, b) => _dateOf(b).compareTo(_dateOf(a)));

                final pending = records.where((fee) {
                  final status = fee['status']?.toString().toLowerCase() ?? 'pending';
                  return status == 'pending' || status == 'unpaid' || status == 'due';
                });
                final pendingBalance = pending.fold<double>(
                  0,
                  (sum, fee) => sum + ((fee['amount'] ?? fee['pending_amount'] ?? 0) as num).toDouble(),
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBalanceCard(pendingBalance),
                      const SizedBox(height: 32),
                      const Text('Payment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      const SizedBox(height: 16),
                      if (records.isEmpty)
                        const Center(child: Text('No fee records available.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))
                      else
                        ...records.map(_buildHistoryItem),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: pendingBalance <= 0
                              ? null
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Payment gateway is not connected yet. Please contact school accounts.')),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('PAY PENDING DUES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildBalanceCard(double pendingBalance) {
    final isPaid = pendingBalance <= 0;
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('CURRENT PENDING BALANCE', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 12),
          Text('Rs ${pendingBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: (isPaid ? Colors.green : Colors.orange).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(isPaid ? 'ALL DUES PAID' : 'DUES PENDING', style: TextStyle(color: isPaid ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    ).animate().fadeIn().scale(delay: 200.ms);
  }

  Widget _buildHistoryItem(Map<String, dynamic> fee) {
    final status = fee['status']?.toString().toLowerCase() ?? 'pending';
    final success = status == 'paid' || status == 'completed';
    final title = fee['title'] ?? fee['description'] ?? 'Fee Record';
    final amount = ((fee['amount'] ?? fee['paid_amount'] ?? fee['pending_amount'] ?? 0) as num).toDouble();
    final date = _dateOf(fee);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: (success ? Colors.green : Colors.orange).withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(success ? Icons.check_rounded : Icons.schedule_rounded, color: success ? Colors.green : Colors.orange, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(DateFormat('dd MMM yyyy').format(date), style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text('Rs ${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        ],
      ),
    );
  }

  static DateTime _dateOf(Map<String, dynamic> fee) {
    final value = fee['paid_at'] ?? fee['due_date'] ?? fee['created_at'];
    if (value is Timestamp) return value.toDate();
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}

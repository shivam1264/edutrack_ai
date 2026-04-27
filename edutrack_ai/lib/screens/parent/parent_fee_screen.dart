import 'package:flutter/material.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ParentFeeScreen extends StatelessWidget {
  const ParentFeeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Fee Management', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 32),
            const Text('Payment History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            _buildHistoryItem('April Tuition Fee', '₹15,000', '12 Apr 2024', true),
            _buildHistoryItem('March Tuition Fee', '₹15,000', '08 Mar 2024', true),
            _buildHistoryItem('Exam Fee (Term 1)', '₹2,500', '15 Feb 2024', true),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
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
      ),
    );
  }

  Widget _buildBalanceCard() {
    return PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('CURRENT PENDING BALANCE', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 12),
          const Text('₹0.00', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: const Text('ALL DUES PAID', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    ).animate().fadeIn().scale(delay: 200.ms);
  }

  Widget _buildHistoryItem(String title, String amount, String date, bool success) {
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
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        ],
      ),
    );
  }
}

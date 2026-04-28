import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/doubt_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';

class DoubtBoxScreen extends StatefulWidget {
  const DoubtBoxScreen({super.key});

  @override
  State<DoubtBoxScreen> createState() => _DoubtBoxScreenState();
}

class _DoubtBoxScreenState extends State<DoubtBoxScreen> {
  int _selectedTabIndex = 1;
  final List<String> _tabs = ['Ask', 'My Doubts', 'Answered'];
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _questionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Doubt Box'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _buildTabs(),
              ),
              Expanded(
                child: _selectedTabIndex == 0
                    ? _buildAskForm(userId)
                    : StreamBuilder<List<DoubtModel>>(
                    stream: FirebaseFirestore.instance
                        .collection('doubts')
                        .where('studentId', isEqualTo: userId)
                        .snapshots()
                        .map((snap) => snap.docs
                            .map((doc) => DoubtModel.fromMap(doc.id, doc.data()))
                            .toList()),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final doubts = snapshot.data ?? [];
                    final filteredDoubts = doubts.where((d) {
                      final status = d.status.toLowerCase();
                      if (_selectedTabIndex == 1) return status == 'pending' || status == 'ai_answered';
                      if (_selectedTabIndex == 2) return status == 'answered';
                      return true;
                    }).toList();

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          if (filteredDoubts.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: Text('No doubts found.', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold))),
                            )
                          else
                            ...filteredDoubts.map((doubt) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _DoubtCard(
                                  subject: doubt.subject,
                                  question: doubt.question,
                                  date: DateFormat('MMM dd, yyyy').format(doubt.createdAt),
                                  status: doubt.status,
                                  answer: doubt.answer,
                                  icon: _getIconForSubject(doubt.subject),
                                  color: _getColorForSubject(doubt.subject),
                                ),
                              );
                            }),
                          const SizedBox(height: 100), // padding for bottom button
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // Only show floating button when NOT on Ask tab
          if (_selectedTabIndex != 0)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: ElevatedButton(
                onPressed: () => setState(() => _selectedTabIndex = 0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('+ Ask a Doubt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAskForm(String userId) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(hintText: 'e.g. Mathematics, Science...'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter a subject' : null,
            ),
            const SizedBox(height: 20),
            const Text('Your Question', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _questionController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'Describe your doubt in detail...'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Enter your question' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _isSubmitting = true);
                  
                  try {
                    final user = context.read<AuthProvider>().user;
                    await FirebaseFirestore.instance.collection('doubts').add({
                      'studentId': userId, // Matched with teacher panel
                      'studentName': user?.name ?? 'Student',
                      'classId': user?.classId ?? '',
                      'schoolId': user?.schoolId ?? '',
                      'subject': _subjectController.text.trim(),
                      'question': _questionController.text.trim(),
                      'status': 'pending', // Matched with teacher panel
                      'createdAt': FieldValue.serverTimestamp(),
                      'isAI': false,
                    });

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Doubt submitted to teachers! ✅'), backgroundColor: Colors.green),
                      );
                      _subjectController.clear();
                      _questionController.clear();
                      setState(() { _isSubmitting = false; _selectedTabIndex = 1; });
                    }
                  } catch (e) {
                    setState(() => _isSubmitting = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit doubt. Try again.')));
                    }
                  }
                },
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Doubt'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: _TabItem(_tabs[index], isSelected: _selectedTabIndex == index),
            ),
          );
        }),
      ),
    );
  }

  IconData _getIconForSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math': return Icons.calculate;
      case 'science': return Icons.science;
      case 'english': return Icons.book;
      case 'history': return Icons.history_edu;
      case 'computer': return Icons.computer;
      default: return Icons.help_outline;
    }
  }

  Color _getColorForSubject(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'math': return Colors.blue;
      case 'science': return Colors.green;
      case 'english': return Colors.orange;
      case 'history': return Colors.purple;
      case 'computer': return Colors.teal;
      default: return AppTheme.primary;
    }
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _TabItem(this.label, {this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _DoubtCard extends StatelessWidget {
  final String subject;
  final String question;
  final String date;
  final String status;
  final String? answer;
  final IconData icon;
  final Color color;

  const _DoubtCard({
    required this.subject,
    required this.question,
    required this.date,
    required this.status,
    this.answer,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toLowerCase();
    final isPending = normalizedStatus == 'pending' || normalizedStatus == 'ai_answered';
    final displayStatus = normalizedStatus == 'answered'
        ? 'Answered'
        : normalizedStatus == 'ai_answered'
            ? 'AI Answered'
            : 'Pending';
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                    Text(
                      displayStatus,
                      style: TextStyle(
                        color: isPending ? Colors.blue : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(question, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                if (!isPending && answer != null && answer!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Colors.green, size: 14),
                            const SizedBox(width: 6),
                            const Text(
                              "Teacher's Expert Answer", 
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          answer!, 
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, height: 1.4, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(date, style: const TextStyle(color: AppTheme.textHint, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

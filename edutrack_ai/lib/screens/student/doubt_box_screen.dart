import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../../utils/config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';

class DoubtBoxScreen extends StatefulWidget {
  const DoubtBoxScreen({super.key});

  @override
  State<DoubtBoxScreen> createState() => _DoubtBoxScreenState();
}

class _DoubtBoxScreenState extends State<DoubtBoxScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _questionCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  String _selectedSubject = 'Mathematics';
  bool _isSubmitting = false;

  final List<String> _subjects = [
    'Mathematics', 'Science', 'Physics', 'Chemistry',
    'Biology', 'English', 'Hindi', 'History', 'Geography', 'Computer Science',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _questionCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitDoubt() async {
    if (_questionCtrl.text.trim().isEmpty) return;
    final user = context.read<AuthProvider>().user;
    setState(() => _isSubmitting = true);
    try {
      final docRef = await FirebaseFirestore.instance.collection('doubts').add({
        'studentId': user?.uid,
        'studentName': user?.name ?? 'Student',
        'classId': user?.classId ?? '',
        'subject': _selectedSubject,
        'question': _questionCtrl.text.trim(),
        'status': 'pending',
        'answer': '✨ Generating Best Answer for you...', // Temporary state
        'answeredBy': 'EduTrack AI',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      final questionText = _questionCtrl.text.trim();
      _questionCtrl.clear();

      // Trigger AI Best Answer asynchronously
      _generateAIBestAnswer(docRef.id, questionText, _selectedSubject, user?.classId ?? 'Grade 10');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Doubt submitted! Teacher will answer soon.'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _tabCtrl.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _generateAIBestAnswer(String docId, String question, String subject, String grade) async {
    try {
      final res = await http.post(
        Uri.parse(Config.endpoint('/generate-best-answer')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'question': question,
          'subject': subject,
          'grade': grade,
        }),
      ).timeout(const Duration(seconds: 40));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await FirebaseFirestore.instance.collection('doubts').doc(docId).update({
          'answer': data['answer'],
          'status': 'answered',
          'isAI': true,
        });
      } else {
        await FirebaseFirestore.instance.collection('doubts').doc(docId).update({
          'answer': 'Teacher will provide the best answer soon.',
          'answeredBy': null,
        });
      }
    } catch (e) {
      await FirebaseFirestore.instance.collection('doubts').doc(docId).update({
        'answer': 'Teacher will provide the best answer soon.',
        'answeredBy': null,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF7C3AED),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9F67FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -30, right: -20,
                      child: Icon(Icons.help_center_rounded,
                          color: Colors.white.withOpacity(0.1), size: 180),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 60, 24, 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Doubt Box', style: TextStyle(
                            color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900,
                          )),
                          Text('Ask your teacher anything', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.w800),
              tabs: const [
                Tab(text: '❓ Ask Doubt'),
                Tab(text: '📋 My Doubts'),
              ],
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildAskTab(),
                _buildMyDoubtsTab(user?.uid ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAskTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumCard(
            opacity: 1,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Subject', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setState(() => _selectedSubject = v!),
                ),
                const SizedBox(height: 16),
                const Text('Your Question', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                TextField(
                  controller: _questionCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Describe your doubt in detail...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitDoubt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('Submit Doubt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().scale(),
        ],
      ),
    );
  }

  Widget _buildMyDoubtsTab(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('doubts')
          .where('studentId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.help_outline_rounded, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('No doubts yet!\nAsk your first question.', textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final isPending = d['status'] == 'pending';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PremiumCard(
                opacity: 1,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(d['subject'] ?? '', style: const TextStyle(
                              fontSize: 11, color: Color(0xFF7C3AED), fontWeight: FontWeight.w700)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPending ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(isPending ? '⏳ Pending' : '✅ Answered', style: TextStyle(
                              fontSize: 11, color: isPending ? Colors.orange : Colors.green, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(d['question'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                    if (!isPending && d['answer'] != null) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                        if (d['isAI'] == true)
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 14),
                              const SizedBox(width: 6),
                              Text('BEST ANSWER (AI)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1)),
                            ],
                          ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.school_rounded, color: AppTheme.primary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(d['answer'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
                            ),
                          ],
                        ),
                      if (d['answeredBy'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('— ${d['answeredBy']}', style: const TextStyle(
                              fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ],
                ),
              ).animate().fadeIn(delay: (i * 80).ms),
            );
          },
        );
      },
    );
  }
}

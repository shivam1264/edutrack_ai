import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DoubtAnswerScreen extends StatelessWidget {
  const DoubtAnswerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final List<String> assignedClasses = user?.assignedClasses ?? 
        (user?.classId != null ? [user!.classId!] : []);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF7C3AED),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9F67FA)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Doubt Queue', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                      Text('Answer student questions', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('doubts')
                .where('classId', whereIn: assignedClasses.isNotEmpty ? assignedClasses : ['__none__'])
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) return SliverToBoxAdapter(child: Center(child: Text('Error: ${snap.error}')));
              if (!snap.hasData) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())));
              
              final docs = snap.data!.docs;
              
              // In-memory sorting to avoid composite index requirements
              final sortedDocs = docs.toList();
              sortedDocs.sort((a, b) {
                final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                // Descending: Newest first
                return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
              });

              final pending = sortedDocs.where((d) {
                final status = (d.data() as Map)['status'];
                return status == 'pending' || status == 'ai_answered';
              }).toList();
              final answered = sortedDocs.where((d) => (d.data() as Map)['status'] == 'answered').toList();

              if (docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(60),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No doubts to answer! 🎉', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (pending.isNotEmpty) ...[
                      _buildSectionHeader('⏳ Pending (${pending.length})', Colors.orange),
                      ...pending.asMap().entries.map((e) {
                          final status = (e.value.data() as Map)['status'];
                          final label = status == 'ai_answered' ? '🤖 AI Answered' : '⏳ Pending';
                          final color = status == 'ai_answered' ? AppTheme.primary : Colors.orange;
                          return _DoubtCard(doc: e.value, teacher: user, isPending: true, label: label, labelColor: color)
                                .animate().fadeIn(delay: (e.key * 80).ms);
                      }),
                    ],
                    if (answered.isNotEmpty) ...[
                      _buildSectionHeader('✅ Answered (${answered.length})', Colors.green),
                      ...answered.asMap().entries.map((e) =>
                          _DoubtCard(doc: e.value, teacher: user, isPending: false, label: '✅ Answered', labelColor: Colors.green)
                              .animate().fadeIn(delay: (e.key * 60).ms)),
                    ],
                  ]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: color)),
    );
  }
}

class _DoubtCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  final dynamic teacher;
  final bool isPending;
  final String label;
  final Color labelColor;

  const _DoubtCard({
    required this.doc, 
    required this.teacher, 
    required this.isPending,
    required this.label,
    required this.labelColor,
  });

  @override
  State<_DoubtCard> createState() => _DoubtCardState();
}

class _DoubtCardState extends State<_DoubtCard> {
  final _answerCtrl = TextEditingController();
  bool _isExpanded = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    if (_answerCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    await widget.doc.reference.update({
      'answer': _answerCtrl.text.trim(),
      'answeredBy': widget.teacher?.name ?? 'Teacher',
      'status': 'answered',
      'answeredAt': FieldValue.serverTimestamp(),
    });
    if (mounted) setState(() { _isSaving = false; _isExpanded = false; });
  }

  void _viewImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(url, fit: BoxFit.contain),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doc.data() as Map<String, dynamic>;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        opacity: 1,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: widget.labelColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(widget.label, style: TextStyle(fontSize: 11, color: widget.labelColor, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(d['question'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 15)),
            if (d['imageUrl'] != null && d['imageUrl'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _viewImage(context, d['imageUrl']),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    d['imageUrl'], 
                    height: 150, 
                    width: double.infinity, 
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) => progress == null ? child : Container(height: 150, color: Colors.grey.withOpacity(0.1), child: const Center(child: CircularProgressIndicator())),
                  ),
                ),
              ),
            ],
            if (d['isAI'] == true && widget.isPending == false)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 14),
                    const SizedBox(width: 4),
                    const Text('AI GENERATED PRE-ANSWER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                  ],
                ),
              ),
            if (!widget.isPending && d['answer'] != null) ...[
              const SizedBox(height: 10),
              const Divider(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(d['isAI'] == true ? Icons.auto_awesome_outlined : Icons.check_circle_rounded, 
                       color: d['isAI'] == true ? AppTheme.primary : Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(d['answer'], style: const TextStyle(color: AppTheme.textSecondary))),
                ],
              ),
              if (d['isAI'] == true)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => widget.doc.reference.update({'isAI': false, 'answeredBy': widget.teacher?.name ?? 'Teacher'}),
                      icon: const Icon(Icons.verified_user_rounded, size: 14),
                      label: const Text('Verify & Keep as Best Answer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
            ],
            if (widget.isPending) ...[
              const SizedBox(height: 12),
              if (_isExpanded) ...[
                TextField(
                  controller: _answerCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Type your answer...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submitAnswer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Submit Answer'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(onPressed: () => setState(() => _isExpanded = false), child: const Text('Cancel')),
                  ],
                ),
              ] else
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Answer'),
                  onPressed: () => setState(() => _isExpanded = true),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF7C3AED)),
                    foregroundColor: const Color(0xFF7C3AED),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

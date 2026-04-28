import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';

class TeacherAnnouncementsScreen extends StatefulWidget {
  final String classId;
  const TeacherAnnouncementsScreen({super.key, required this.classId});

  @override
  State<TeacherAnnouncementsScreen> createState() => _TeacherAnnouncementsScreenState();
}

class _TeacherAnnouncementsScreenState extends State<TeacherAnnouncementsScreen> {
  final _msgCtrl = TextEditingController();
  bool _isSending = false;

  Future<void> _sendAnnouncement() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    
    setState(() => _isSending = true);
    try {
      final user = context.read<AuthProvider>().user;
      await FirebaseFirestore.instance.collection('announcements').add({
        'class_id': widget.classId,
        'title': 'Class Announcement',
        'content': _msgCtrl.text.trim(),
        'teacher_id': user?.uid,
        'teacher_name': user?.name ?? 'Teacher',
        'type': 'announcement',
        'category': 'Class',
        'priority': 'Medium',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      _msgCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement broadcasted! 📢'), backgroundColor: Colors.blue),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Announcements', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('announcements')
                  .where(Filter.or(
                    Filter('class_id', isEqualTo: widget.classId),
                    Filter('target', isEqualTo: 'all'),
                    Filter('target', isEqualTo: 'teachers'),
                  ))
                  .snapshots(),


              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No announcements yet.'));
                
                // In-memory sorting to avoid composite index requirements
                final sortedDocs = docs.toList();
                sortedDocs.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  return (bTime ?? Timestamp.now()).compareTo(aTime ?? Timestamp.now());
                });

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: sortedDocs.length,
                  itemBuilder: (context, index) {
                    final d = sortedDocs[index].data() as Map<String, dynamic>;
                    return PremiumCard(
                      opacity: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.campaign_rounded, color: Colors.blue, size: 16),
                              const SizedBox(width: 8),
                              Text(d['teacher_name'] ?? 'Teacher', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(d['content'] ?? '', style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppTheme.borderLight))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'Type an announcement...',
                      filled: true,
                      fillColor: AppTheme.bgLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FloatingActionButton(
                  onPressed: _isSending ? null : _sendAnnouncement,
                  backgroundColor: Colors.blue,
                  mini: true,
                  child: _isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

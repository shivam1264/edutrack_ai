import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _target = 'all'; // all, teachers, class
  String? _selectedClassId;
  bool _isSending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Announcement'),
        backgroundColor: AppTheme.accent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'New Announcement',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Broadcast a message to school members via push notification.'),
            const SizedBox(height: 32),

            const Text('Target Audience', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildTargetSelector(),
            const SizedBox(height: 24),

            if (_target == 'class') ...[
              _buildClassSelector(),
              const SizedBox(height: 24),
            ],

            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Announcement Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Message Body',
                alignLabelWithHint: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _isSending ? null : _sendAnnouncement,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send Broadcast', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _target,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Members')),
            DropdownMenuItem(value: 'teachers', child: Text('Teachers Only')),
            DropdownMenuItem(value: 'class', child: Text('Specific Class')),
          ],
          onChanged: (val) => setState(() => _target = val!),
        ),
      ),
    );
  }

  Widget _buildClassSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('classes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        final classes = snapshot.data!.docs;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              hint: const Text('Select Class'),
              value: _selectedClassId,
              isExpanded: true,
              items: classes.map((doc) {
                return DropdownMenuItem(
                  value: doc.id,
                  child: Text(doc['name'] ?? doc.id),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedClassId = val),
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendAnnouncement() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _isSending = true);

    try {
      // Create notification document in Firestore
      // Cloud Function or Notification Service will pick this up to send FCM
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': _titleController.text,
        'message': _messageController.text,
        'type': 'announcement',
        'target': _target,
        if (_target == 'class') 'class_id': _selectedClassId,
        'timestamp': FieldValue.serverTimestamp(),
        'sender_id': 'admin',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement broadcasted!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}

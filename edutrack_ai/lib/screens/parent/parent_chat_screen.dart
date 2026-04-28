import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';

class ParentChatScreen extends StatefulWidget {
  final String? studentId;

  const ParentChatScreen({super.key, this.studentId});

  @override
  State<ParentChatScreen> createState() => _ParentChatScreenState();
}

class _ParentChatScreenState extends State<ParentChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parent = context.watch<AuthProvider>().user;
    final childId = widget.studentId ??
        ((parent?.parentOf != null && parent!.parentOf!.isNotEmpty)
            ? parent.parentOf!.first
            : '');

    return FutureBuilder<DocumentSnapshot>(
      future: childId.isNotEmpty
          ? FirebaseFirestore.instance.collection('users').doc(childId).get()
          : null,
      builder: (context, studentSnap) {
        final classId =
            (studentSnap.data?.data() as Map<String, dynamic>?)?['class_id'];

        return FutureBuilder<DocumentSnapshot>(
          future: classId != null && classId.toString().isNotEmpty
              ? FirebaseFirestore.instance.collection('classes').doc(classId).get()
              : null,
          builder: (context, classSnap) {
            final classData = classSnap.data?.data() as Map<String, dynamic>?;
            final teacherName = classData?['class_teacher_name']?.toString() ??
                classData?['teacher_name']?.toString() ??
                'Teacher';
            final teacherId = classData?['class_teacher_id']?.toString() ??
                classData?['teacher_id']?.toString() ??
                '';
            final chatId = childId.isNotEmpty && teacherId.isNotEmpty
                ? '${childId}_$teacherId'
                : '';

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Teacher Chat',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                    Text(
                      teacherId.isEmpty
                          ? 'Teacher link pending'
                          : '$teacherName | School chat',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 0,
              ),
              body: Column(
                children: [
                  Expanded(
                    child: chatId.isEmpty
                        ? const Center(
                            child: Text(
                              'Teacher chat will appear once the class teacher is linked.',
                            ),
                          )
                        : StreamBuilder<List<ChatMessage>>(
                            stream: _chatService.streamMessages(
                              chatId,
                              parent?.uid ?? '',
                            ),
                            builder: (context, msgSnap) {
                              if (msgSnap.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final messages = msgSnap.data ?? [];
                              if (messages.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline_rounded,
                                        size: 48,
                                        color: Colors.grey.withOpacity(0.3),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'No messages yet. Say hello!',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return ListView.builder(
                                reverse: true,
                                padding: const EdgeInsets.all(20),
                                itemCount: messages.length,
                                itemBuilder: (context, i) {
                                  final m = messages[i];
                                  return _buildMessage(
                                    m.text,
                                    DateFormat('hh:mm a').format(m.timestamp),
                                    m.isMe,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  _buildChatInput(chatId, parent?.uid ?? '', childId, teacherId),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessage(String text, String time, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFF97316) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(20),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput(
    String chatId,
    String senderId,
    String? studentId,
    String? teacherId,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _messageController,
                enabled: chatId.isNotEmpty,
                decoration: InputDecoration(
                  hintText: chatId.isEmpty
                      ? 'Teacher link required before chatting'
                      : 'Type a message...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(chatId, senderId, studentId, teacherId),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(chatId, senderId, studentId, teacherId),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: chatId.isEmpty ? Colors.grey.shade400 : const Color(0xFFF97316),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(
    String chatId,
    String senderId,
    String? studentId,
    String? teacherId,
  ) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || chatId.isEmpty) return;

    await _chatService.sendMessage(
      chatId: chatId,
      senderId: senderId,
      text: text,
      studentId: studentId,
      teacherId: teacherId,
    );
    _messageController.clear();
  }

}

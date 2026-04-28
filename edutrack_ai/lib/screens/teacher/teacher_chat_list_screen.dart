import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../../services/chat_service.dart';
import '../../models/user_model.dart';

class TeacherChatListScreen extends StatelessWidget {
  const TeacherChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final teacher = context.watch<AuthProvider>().user;
    final teacherId = teacher?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Parent & Student Messages', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: teacherId.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('teacher_id', isEqualTo: teacherId)
                  .orderBy('last_timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text('No active conversations', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text('Messages from parents will appear here.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final studentId = data['student_id'] ?? '';
                    final lastMessage = data['last_message'] ?? '';
                    final lastTimestamp = (data['last_timestamp'] as Timestamp?)?.toDate();
                    final lastSenderId = data['last_sender_id'] ?? '';
                    final isNew = lastSenderId != teacherId;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(studentId).get(),
                      builder: (context, userSnap) {
                        final studentData = userSnap.data?.data() as Map<String, dynamic>?;
                        final studentName = studentData?['name'] ?? 'Loading...';
                        final avatarUrl = studentData?['avatar_url'];

                        return PremiumCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _TeacherChatRoomScreen(
                                  studentId: studentId,
                                  studentName: studentName,
                                ),
                              ),
                            );
                          },
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.secondary.withOpacity(0.1),
                              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                              child: avatarUrl == null 
                                ? Text(studentName[0].toUpperCase(), style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold))
                                : null,
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    studentName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                if (lastTimestamp != null)
                                  Text(
                                    DateFormat('hh:mm a').format(lastTimestamp),
                                    style: TextStyle(color: Colors.grey, fontSize: 10),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isNew ? Colors.black87 : Colors.grey,
                                fontWeight: isNew ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: isNew 
                              ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))
                              : const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

// A slightly modified version of the chat room for teachers
class _TeacherChatRoomScreen extends StatefulWidget {
  final String studentId;
  final String studentName;

  const _TeacherChatRoomScreen({
    required this.studentId,
    required this.studentName,
  });

  @override
  State<_TeacherChatRoomScreen> createState() => _TeacherChatRoomScreenState();
}

class _TeacherChatRoomScreenState extends State<_TeacherChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final teacherId = context.watch<AuthProvider>().user?.uid ?? '';
    final chatId = '${widget.studentId}_$teacherId';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.studentName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const Text('Parent/Student Conversation', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.streamMessages(chatId, teacherId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? [];
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    return _buildMessage(m.text, DateFormat('hh:mm a').format(m.timestamp), m.isMe);
                  },
                );
              },
            ),
          ),
          _buildChatInput(chatId, teacherId),
        ],
      ),
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
          color: isMe ? const Color(0xFF059669) : Colors.white,
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
            Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 14, height: 1.4)),
            const SizedBox(height: 4),
            Text(time, style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput(String chatId, String senderId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(30)),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(hintText: 'Type a message...', border: InputBorder.none),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              if (_messageController.text.trim().isNotEmpty) {
                _chatService.sendMessage(
                  chatId: chatId,
                  senderId: senderId,
                  text: _messageController.text.trim(),
                  studentId: widget.studentId,
                  teacherId: senderId,
                );
                _messageController.clear();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Color(0xFF059669), shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

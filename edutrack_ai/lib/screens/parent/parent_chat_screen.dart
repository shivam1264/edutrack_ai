import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/class_service.dart';
import '../../models/class_model.dart';
import '../../services/chat_service.dart';
import 'package:intl/intl.dart';

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
  Widget build(BuildContext context) {
    final parent = context.watch<AuthProvider>().user;
    final childId = widget.studentId ?? ((parent?.parentOf != null && parent!.parentOf!.isNotEmpty) ? parent.parentOf!.first : '');

    return FutureBuilder<DocumentSnapshot>(
      future: childId.isNotEmpty ? FirebaseFirestore.instance.collection('users').doc(childId).get() : null,
      builder: (context, studentSnap) {
        final classId = (studentSnap.data?.data() as Map<String, dynamic>?)?['class_id'];
        
        return StreamBuilder<ClassModel>(
          stream: classId != null ? ClassService().getClassById(classId) : null,
          builder: (context, classSnap) {
            final teacherName = classSnap.data?.classTeacherName ?? 'Teacher';
            final teacherId = classSnap.data?.classTeacherId ?? '';
            final chatId = childId.isNotEmpty && teacherId.isNotEmpty ? '${childId}_$teacherId' : '';

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Teacher Chat', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    Text('$teacherName • Online', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 0,
                actions: [
                  IconButton(icon: const Icon(Icons.videocam_rounded), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.call_rounded), onPressed: () {}),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: chatId.isEmpty 
                      ? const Center(child: Text('Connecting to classroom...'))
                      : StreamBuilder<List<ChatMessage>>(
                          stream: _chatService.streamMessages(chatId, parent?.uid ?? ''),
                          builder: (context, msgSnap) {
                            if (msgSnap.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final messages = msgSnap.data ?? [];
                            if (messages.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.withOpacity(0.3)),
                                    const SizedBox(height: 12),
                                    const Text('No messages yet. Say hello!', style: TextStyle(color: Colors.grey)),
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
                                return _buildMessage(m.text, DateFormat('hh:mm a').format(m.timestamp), m.isMe);
                              },
                            );
                          },
                        ),
                  ),
                  _buildChatInput(chatId, parent?.uid ?? ''),
                ],
              ),
            );
          }
        );
      }
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
              if (_messageController.text.trim().isNotEmpty && chatId.isNotEmpty) {
                _chatService.sendMessage(chatId, senderId, _messageController.text.trim());
                _messageController.clear();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Color(0xFFF97316), shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

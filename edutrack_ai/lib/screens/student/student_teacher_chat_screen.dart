import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import '../../utils/app_theme.dart';

class StudentTeacherChatScreen extends StatefulWidget {
  final String teacherId;
  final String teacherName;

  const StudentTeacherChatScreen({
    super.key,
    required this.teacherId,
    required this.teacherName,
  });

  @override
  State<StudentTeacherChatScreen> createState() => _StudentTeacherChatScreenState();
}

class _StudentTeacherChatScreenState extends State<StudentTeacherChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = context.watch<AuthProvider>().user;
    final studentId = student?.uid ?? '';
    final chatId = studentId.isNotEmpty ? '${studentId}_${widget.teacherId}' : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Teacher Chat', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            Text(widget.teacherName, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
                ? const Center(child: Text('Student account not ready for chat.'))
                : StreamBuilder<List<ChatMessage>>(
                    stream: _chatService.streamMessages(chatId, studentId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final messages = snapshot.data ?? [];
                      if (messages.isEmpty) {
                        return const Center(
                          child: Text(
                            'No messages yet. Start the conversation.',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                        );
                      }

                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(20),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _MessageBubble(message: message);
                        },
                      );
                    },
                  ),
          ),
          _buildComposer(chatId, studentId),
        ],
      ),
    );
  }

  Widget _buildComposer(String chatId, String studentId) {
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
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(chatId, studentId),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _sendMessage(chatId, studentId),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String chatId, String studentId) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || chatId.isEmpty || studentId.isEmpty) return;

    await _chatService.sendMessage(chatId, studentId, text);
    _messageController.clear();
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: message.isMe ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: message.isMe ? const Radius.circular(20) : Radius.zero,
            bottomRight: message.isMe ? Radius.zero : const Radius.circular(20),
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isMe ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(message.timestamp),
              style: TextStyle(
                color: message.isMe ? Colors.white70 : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

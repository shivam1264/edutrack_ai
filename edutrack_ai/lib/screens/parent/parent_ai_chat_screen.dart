import 'package:flutter/material.dart';
import '../../widgets/premium_card.dart';
import '../../services/ai_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ParentAIChatScreen extends StatefulWidget {
  final String? studentId;
  const ParentAIChatScreen({super.key, this.studentId});

  @override
  State<ParentAIChatScreen> createState() => _ParentAIChatScreenState();
}

class _ParentAIChatScreenState extends State<ParentAIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'assistant',
      'content': 'Hello! I am your AI Education Assistant. Ask me anything about your child\'s performance or general academic advice.'
    }
  ];
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMsg = _controller.text.trim();
    setState(() {
      _messages.add({'role': 'user', 'content': userMsg});
      _isLoading = true;
    });
    _controller.clear();

    try {
      final reply = await AIService().chat(
        userMsg,
        context: 'parent',
        studentId: widget.studentId,
      );

      setState(() {
        _messages.add({'role': 'assistant', 'content': reply});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Error connecting to AI service.'});
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('EduTrack AI Assistant', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                final m = _messages[i];
                final isUser = m['role'] == 'user';
                return _buildBubble(m['content'], isUser);
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFF97316) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
          ),
        ),
        child: Text(text, style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500)),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ask about performance...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
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

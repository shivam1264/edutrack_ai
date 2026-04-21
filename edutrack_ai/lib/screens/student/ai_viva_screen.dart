import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../utils/config.dart';
import '../../utils/app_theme.dart';

class AIVivaScreen extends StatefulWidget {
  const AIVivaScreen({super.key});

  @override
  State<AIVivaScreen> createState() => _AIVivaScreenState();
}

class _AIVivaScreenState extends State<AIVivaScreen> {
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoadingReply = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messages.add({"role": "assistant", "text": "Hello! I am your AI Examiner. We are directly connected to the Backend now. Use your phone keyboard's Mic 🎤 to speak your answers!"});
  }

  Future<void> _sendMessage(String message) async {
    setState(() {
      _messages.add({"role": "user", "text": message});
      _isLoadingReply = true;
    });
    _msgController.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(Config.endpoint('/ai-viva')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'history': _messages.map((m) => {'role': m['role'], 'text': m['text']}).toList(),
          'topic': 'General Knowledge',
          'use_tts': false,
          'audio_base64': ''
        }),
      ).timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final reply = jsonDecode(response.body)['reply'] ?? 'I cannot evaluate that.';
        setState(() {
          _messages.add({"role": "assistant", "text": reply});
          _isLoadingReply = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _isLoadingReply = false;
        String errorMsg = "Network issue. Please try again.";
        if (e is TimeoutException) {
          errorMsg = "AI Examiner is taking too long to evaluate. Check connection.";
        }
        _messages.add({"role": "assistant", "text": errorMsg});
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('AI Viva Simulator', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.teal.shade50,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.teal,
                  child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. Gemini (Examiner)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                      Text('Use keyboard mic to answer!', style: TextStyle(color: Colors.black54, fontSize: 13)),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final isUser = _messages[index]['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.teal : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Text(
                      _messages[index]['text']!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (_isLoadingReply)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.teal),
            ),
            
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: 'Type answer or use Keyboard Mic...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) _sendMessage(val.trim());
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      if (_msgController.text.trim().isNotEmpty) {
                        _sendMessage(_msgController.text.trim());
                      }
                    },
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.teal,
                      child: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

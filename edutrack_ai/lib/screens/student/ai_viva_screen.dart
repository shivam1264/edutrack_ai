import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../../utils/config.dart';
import '../../utils/app_theme.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

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

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  bool _isRecording = false;
  String? _recordPath;

  @override
  void initState() {
    super.initState();
    _messages.add({
      "role": "assistant", 
      "text": "Hello! I am your AI examiner. Connect via Voice! Press and hold the Mic button to record your answer, or just type it out."
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        _recordPath = '${dir.path}/viva_audio.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000), 
          path: _recordPath!
        );
        setState(() {
          _isRecording = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission required!')));
      }
    } catch (e) {
      debugPrint("Record error: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        final File file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final base64Audio = base64Encode(bytes);
          _sendMessage("[Sent Audio Answer]", base64Audio: base64Audio);
        }
      }
    } catch (e) {
      debugPrint("Stop record error: $e");
    }
  }

  Future<void> _playBase64Audio(String base64Audio) async {
    try {
      final bytes = base64Decode(base64Audio);
      await _audioPlayer.play(BytesSource(bytes));
    } catch (e) {
      debugPrint("Audio play error: $e");
    }
  }

  Future<void> _sendMessage(String message, {String? base64Audio}) async {
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
          'message': base64Audio == null ? message : '',
          'history': _messages.where((m) => !m['text']!.startsWith('[Sent')).map((m) => {'role': m['role'], 'text': m['text']}).toList(),
          'topic': 'General Knowledge',
          'use_tts': true,
          'audio_base64': base64Audio ?? ''
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final replyText = jsonResponse['reply'] ?? 'I cannot evaluate that.';
        final replyBase64Audio = jsonResponse['reply_audio_base64'];

        setState(() {
          _messages.add({"role": "assistant", "text": replyText});
          _isLoadingReply = false;
        });
        _scrollToBottom();
        
        if (replyBase64Audio != null) {
          _playBase64Audio(replyBase64Audio);
        }
      } else {
        throw Exception("Server Error");
      }
    } catch (e) {
      setState(() {
        _isLoadingReply = false;
        _messages.add({"role": "assistant", "text": "Network issue. Please try again."});
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
        title: const Text('Real Voice AI Viva', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.teal,
                  backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=47'),
                  child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dr. Gemini (Examiner)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                      Text(_isRecording ? 'Listening carefully...' : 'Hold Mic 🎤 to speak your answer', style: TextStyle(color: _isRecording ? Colors.red : Colors.black54, fontSize: 13, fontWeight: _isRecording ? FontWeight.bold : FontWeight.normal)),
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
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(0),
                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(20),
                      ),
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
                        hintText: 'Type answer here...',
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
                    onTapDown: (_) => _startRecording(),
                    onTapUp: (_) => _stopRecording(),
                    onTapCancel: () => _stopRecording(),
                    onTap: () {
                      if (_msgController.text.trim().isNotEmpty) {
                        _sendMessage(_msgController.text.trim());
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isRecording ? 60 : 50,
                      height: _isRecording ? 60 : 50,
                      decoration: BoxDecoration(
                        color: _isRecording ? Colors.red : Colors.teal,
                        shape: BoxShape.circle,
                        boxShadow: _isRecording ? [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 15, spreadRadius: 5)] : [],
                      ),
                      child: Icon(
                        _isRecording ? Icons.mic : (_msgController.text.isEmpty ? Icons.mic_none_rounded : Icons.send_rounded), 
                        color: Colors.white,
                        size: _isRecording ? 30 : 24,
                      ),
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

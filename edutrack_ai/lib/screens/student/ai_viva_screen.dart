import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/app_theme.dart';
import '../../utils/config.dart';

class AIVivaScreen extends StatefulWidget {
  const AIVivaScreen({super.key});

  @override
  State<AIVivaScreen> createState() => _AIVivaScreenState();
}

class _AIVivaScreenState extends State<AIVivaScreen> {
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingReply = false;
  
  // Voice features
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _speechEnabled = false;
  bool _ttsEnabled = true;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _messages.add({
      'role': 'assistant',
      'text': 'Hello! I am your AI Examiner. You can speak or type your answers below and I will evaluate them one by one.'
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _sendMessage(String message) async {
    setState(() {
      _messages.add({'role': 'user', 'text': message});
      _isLoadingReply = true;
    });
    _msgController.clear();
    _scrollToBottom();

    try {
      final response = await http
          .post(
            Uri.parse(Config.endpoint('/ai-viva')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'history': _messages.map((m) => {'role': m['role'], 'text': m['text']}).toList(),
              'topic': 'General Knowledge',
              'use_tts': false,
              'audio_base64': '',
            }),
          )
          .timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final reply = jsonDecode(response.body)['reply'] ?? 'I cannot evaluate that.';
        setState(() {
          _messages.add({'role': 'assistant', 'text': reply.toString()});
          _isLoadingReply = false;
        });
        // Speak the reply if TTS is enabled
        if (_ttsEnabled) {
          _speak(reply.toString());
        }
      } else {
        setState(() {
          _messages.add({'role': 'assistant', 'text': 'The examiner is unavailable right now. Please try again.'});
          _isLoadingReply = false;
        });
      }
    } on TimeoutException {
      setState(() {
        _messages.add({'role': 'assistant', 'text': 'AI Examiner is taking too long to evaluate. Check connection.'});
        _isLoadingReply = false;
      });
    } catch (_) {
      setState(() {
        _messages.add({'role': 'assistant', 'text': 'Network issue. Please try again.'});
        _isLoadingReply = false;
      });
    }

    _scrollToBottom();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _initTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  void _startListening() async {
    // Request microphone permission first
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission is required for voice input')),
      );
      return;
    }
    
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }
    
    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _msgController.text = result.recognizedWords;
        });
        if (result.finalResult) {
          _stopListening();
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
      listenMode: ListenMode.confirmation,
      cancelOnError: true,
    );
    
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _toggleTts() {
    setState(() {
      _ttsEnabled = !_ttsEnabled;
    });
    if (!_ttsEnabled) {
      _flutterTts.stop();
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
        actions: [
          IconButton(
            icon: Icon(_ttsEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: _toggleTts,
            tooltip: 'Toggle Voice Output',
          ),
        ],
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
                      Text('Dr. Llama (AI Examiner)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                      Text('Type your answer to continue', style: TextStyle(color: Colors.black54, fontSize: 13)),
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
                  // Microphone button for voice input
                  GestureDetector(
                    onTap: _isListening ? _stopListening : _startListening,
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: _isListening ? Colors.red : Colors.grey.shade300,
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: InputDecoration(
                        hintText: _isListening ? 'Listening...' : 'Type or speak your answer...',
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
                    child: const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.send_rounded, color: Colors.white),
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

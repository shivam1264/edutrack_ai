import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/config.dart';
import '../../providers/auth_provider.dart';
import '../../services/class_service.dart';

class AIVivaScreen extends StatefulWidget {
  final String? initialTopic;
  const AIVivaScreen({super.key, this.initialTopic});

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

  // Topic & Grade
  String _selectedTopic = 'General Knowledge';
  String _studentGrade = '8';
  String _classId = '';
  final List<String> _askedQuestions = [];

  // Available topics
  final List<String> _topics = [
    'General Knowledge',
    'Mathematics',
    'Science',
    'Physics',
    'Chemistry',
    'Biology',
    'History',
    'Geography',
    'English',
    'Hindi',
    'Computer Science',
    'Social Studies',
    'Environmental Science',
  ];

  // Topic keywords for natural language detection
  final Map<String, List<String>> _topicKeywords = {
    'Mathematics': ['math', 'mathematics', 'algebra', 'geometry', 'calculus', 'number', 'equation', 'formula'],
    'Science': ['science', 'scientific', 'experiment', 'lab', 'laboratory'],
    'Physics': ['physics', 'force', 'motion', 'energy', 'electricity', 'magnetism', 'light', 'optics', 'mechanics'],
    'Chemistry': ['chemistry', 'chemical', 'reaction', 'element', 'compound', 'acid', 'base', 'atom', 'molecule'],
    'Biology': ['biology', 'cell', 'organism', 'plant', 'animal', 'human body', 'life', 'living'],
    'History': ['history', 'historical', 'ancient', 'medieval', 'modern', 'war', 'freedom', 'independence'],
    'Geography': ['geography', 'map', 'earth', 'climate', 'weather', 'river', 'mountain', 'continent', 'country'],
    'English': ['english', 'grammar', 'vocabulary', 'literature', 'poem', 'story', 'essay', 'language'],
    'Hindi': ['hindi', 'हिंदी', 'vyakaran', 'kahani', 'kavita'],
    'Computer Science': ['computer', 'programming', 'coding', 'software', 'hardware', 'algorithm', 'data', 'internet'],
    'Social Studies': ['social', 'civics', 'polity', 'government', 'constitution', 'society', 'culture'],
    'Environmental Science': ['environment', 'pollution', 'nature', 'climate', 'global warming', 'ecology', 'green'],
  };

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _selectedTopic = widget.initialTopic ?? 'General Knowledge';
    _loadStudentGrade();
  }

  Future<void> _loadStudentGrade() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null && user.classId != null) {
      _classId = user.classId!;
      // Fetch class details to get standard/grade
      final classService = ClassService();
      final classModel = await classService.getClassByIdFuture(_classId);
      if (classModel != null) {
        setState(() {
          _studentGrade = classModel.standard;
        });
      }
    }
    // Add welcome message after loading
    setState(() {
      _messages.add({
        'role': 'assistant',
        'text': 'Hello! I am your AI Examiner for Grade $_studentGrade. \n\nCurrent Topic: $_selectedTopic\n\nTap the topic button above to change subjects, or start answering questions below!'
      });
    });
    // Ask first question automatically
    _requestNewQuestion();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _requestNewQuestion() async {
    setState(() => _isLoadingReply = true);
    try {
      final response = await http
          .post(
            Uri.parse(Config.endpoint('/ai-viva')),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': 'NEXT_QUESTION',
              'history': _messages.map((m) => {'role': m['role'], 'text': m['text']}).toList(),
              'topic': _selectedTopic,
              'grade': _studentGrade,
              'asked_questions': _askedQuestions,
              'use_tts': false,
              'audio_base64': '',
            }),
          )
          .timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['reply'] ?? 'Let\'s continue with the next question.';
        final question = data['question'];
        final topicChanged = data['topic_changed'] ?? false;
        final newTopic = data['new_topic'];
        
        // Update topic if backend detected a change
        if (topicChanged && newTopic != null && newTopic != _selectedTopic) {
          setState(() {
            _selectedTopic = newTopic;
            _askedQuestions.clear();
          });
        }
        
        if (question != null && question.isNotEmpty) {
          _askedQuestions.add(question);
        }
        setState(() {
          _messages.add({'role': 'assistant', 'text': reply.toString()});
          _isLoadingReply = false;
        });
        if (_ttsEnabled) {
          _speak(reply.toString());
        }
      }
    } catch (_) {
      setState(() => _isLoadingReply = false);
    }
    _scrollToBottom();
  }

  // Detect if user is requesting a topic change via natural language
  String? _detectTopicFromMessage(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Check for explicit topic request patterns
    final topicRequestPatterns = [
      r'ask.*questions?.*(from|on|about).*',
      r'pucho.*(question|sawal).*',
      r'start.*quiz.*on',
      r'change.*topic.*to',
      r'switch.*to.*',
      r'let.*do.*',
      r'begin.*with',
      r'start.*with',
    ];
    
    bool isTopicRequest = topicRequestPatterns.any((pattern) => 
      RegExp(pattern, caseSensitive: false).hasMatch(message)
    );
    
    if (!isTopicRequest && !lowerMessage.contains('question') && 
        !lowerMessage.contains('pucho') && !lowerMessage.contains('quiz')) {
      return null;
    }
    
    // Check for topic keywords
    for (final entry in _topicKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerMessage.contains(keyword.toLowerCase())) {
          return entry.key;
        }
      }
    }
    
    return null;
  }

  Future<void> _sendMessage(String message) async {
    // Check if user is requesting a topic change
    final detectedTopic = _detectTopicFromMessage(message);
    if (detectedTopic != null && detectedTopic != _selectedTopic) {
      setState(() {
        _selectedTopic = detectedTopic;
        _askedQuestions.clear();
      });
      
      // Add system message about topic change
      setState(() {
        _messages.add({
          'role': 'assistant',
          'text': 'OK! I will now ask you Grade $_studentGrade level questions on $detectedTopic. Here is your first question:'
        });
      });
      
      // Request new question on new topic
      _requestNewQuestion();
      return;
    }
    
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
              'topic': _selectedTopic,
              'grade': _studentGrade,
              'asked_questions': _askedQuestions,
              'use_tts': false,
              'audio_base64': '',
            }),
          )
          .timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['reply'] ?? 'I cannot evaluate that.';
        final question = data['question'];
        final topicChanged = data['topic_changed'] ?? false;
        final newTopic = data['new_topic'];
        
        // Update topic if backend detected a change
        if (topicChanged && newTopic != null && newTopic != _selectedTopic) {
          setState(() {
            _selectedTopic = newTopic;
            _askedQuestions.clear();
          });
        }
        
        if (question != null && question.isNotEmpty) {
          _askedQuestions.add(question);
        }
        setState(() {
          _messages.add({'role': 'assistant', 'text': reply.toString()});
          _isLoadingReply = false;
        });
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

  void _showTopicSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Topic for Viva', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _topics.length,
                itemBuilder: (context, index) {
                  final topic = _topics[index];
                  final isSelected = topic == _selectedTopic;
                  return ListTile(
                    title: Text(topic),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.teal) : null,
                    onTap: () {
                      setState(() {
                        _selectedTopic = topic;
                        _askedQuestions.clear();
                        _messages.clear();
                        _messages.add({
                          'role': 'assistant',
                          'text': 'Topic changed to: $topic\n\nI will now ask Grade $_studentGrade level questions on this topic.'
                        });
                      });
                      Navigator.pop(context);
                      _requestNewQuestion();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
          // Topic Selector & Grade Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.teal.shade50,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _showTopicSelector,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.topic, color: Colors.teal, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Topic: $_selectedTopic',
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.teal),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, color: Colors.teal),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.teal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Grade $_studentGrade',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.teal,
                      child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dr. Llama (AI Examiner)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                          Text('Questions are grade-appropriate', style: TextStyle(color: Colors.black54, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (_askedQuestions.isNotEmpty)
                      Chip(
                        label: Text('${_askedQuestions.length} asked'),
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.teal.shade200),
                      ),
                  ],
                ),
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

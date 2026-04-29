import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/homework_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class HomeworkChatScreen extends StatefulWidget {
  const HomeworkChatScreen({super.key});

  @override
  State<HomeworkChatScreen> createState() => _HomeworkChatScreenState();
}

class _HomeworkChatScreenState extends State<HomeworkChatScreen> {
  final _questionCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _selectedSubject = 'Mathematics';
  bool _showHintFirst = false;
  bool _isLoading = false;
  bool _isSpeaking = false;
  int _dailyCount = 0;
  static const int _dailyLimit = 500;

  // Vision & Voice state
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  
  // Voice input
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isSpeechEnabled = true;

  final List<_ChatMessage> _messages = [];

  final List<String> _subjects = [
    'Mathematics', 'Science', 'Physics', 'Chemistry',
    'Biology', 'English', 'Hindi', 'History', 'Geography',
    'Computer Science',
  ];

  @override
  void initState() {
    super.initState();
    _loadUsage();
    _initSpeech();
    _initTts();
  }

  void _initSpeech() async {
    try {
      await _speech.initialize();
      setState(() {});
    } catch (e) {
      debugPrint('Speech init error: $e');
    }
  }

  void _initTts() {
    // TTS disabled in this build — using FlutterTts stub
  }

  Future<void> _loadUsage() async {
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    final count = await HomeworkService.instance.getDailyUsageCount(uid);
    setState(() => _dailyCount = count);
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    setState(() => _selectedImage = image);
  }

  Future<void> _captureImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 70,
    );
    setState(() => _selectedImage = image);
  }

  void _listen() async {
    // Request permission explicitly first
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required for voice input.')),
        );
      }
      return;
    }

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('Speech Status: $val'),
        onError: (val) => debugPrint('Speech Error: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _questionCtrl.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _speak(String text) {
    // TTS stubbed out — no native dependency needed
  }

  void _stopSpeaking() {
    setState(() => _isSpeaking = false);
  }

  Future<void> _askQuestion() async {
    final question = _questionCtrl.text.trim();
    if (question.isEmpty && _selectedImage == null) return;
    if (_dailyCount >= _dailyLimit) {
      _showLimitReached();
      return;
    }

    final uid = context.read<AuthProvider>().user?.uid ?? '';
    String? base64Image;
    String? imagePath = _selectedImage?.path;

    if (_selectedImage != null) {
      final bytes = await File(_selectedImage!.path).readAsBytes();
      base64Image = base64.encode(bytes);
    }

    setState(() {
      _messages.add(_ChatMessage(
        text: question.isEmpty ? "Explain this image:" : question,
        isUser: true,
        subject: _selectedSubject,
        imagePath: imagePath,
      ));
      _isLoading = true;
      _questionCtrl.clear();
      _selectedImage = null;
    });
    _scrollToBottom();

    try {
      final result = await HomeworkService.instance.askHomeworkQuestion(
        studentId: uid,
        question: question.isEmpty ? "Explain this image." : question,
        subject: _selectedSubject,
        studentClass: '9',
        imageData: base64Image,
        showHintFirst: _showHintFirst,
      );

      setState(() {
        _dailyCount = result['daily_count'] ?? _dailyCount + 1;

        if (_showHintFirst && result['hint'] != null) {
          _messages.add(_ChatMessage(text: '💡 Hint: ${result['hint']}', isUser: false, subject: _selectedSubject, isHint: true));
        }

        _messages.add(_ChatMessage(
          text: result['answer'] ?? 'No answer received.',
          isUser: false,
          subject: _selectedSubject,
          steps: List<String>.from(result['steps'] ?? []),
        ));
        _isLoading = false;
      });
      
      _speak(result['answer'] ?? '');
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(text: '❌ Error: ${e.toString().replaceAll('Exception: ', '')}', isUser: false, subject: _selectedSubject, isError: true));
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _showLimitReached() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Daily Limit Reached'),
        content: Text('You have used all $_dailyLimit questions for today. Your academic curiosity is impressive! Come back tomorrow.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      floatingActionButton: _isSpeaking 
        ? FloatingActionButton.extended(
            onPressed: _stopSpeaking,
            icon: const Icon(Icons.stop_rounded),
            label: const Text('Stop AI Reporter'),
            backgroundColor: AppTheme.danger,
          )
        : null,
      body: Column(
        children: [
          // ── Premium Header ──
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 20, left: 20, right: 20),
            decoration: const BoxDecoration(gradient: AppTheme.meshGradient),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Neural Tutor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
                      Text('Always online to assist you', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: Text('$_dailyCount/$_dailyLimit', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(_isSpeechEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded, color: Colors.white, size: 20),
                  onPressed: () => setState(() => _isSpeechEnabled = !_isSpeechEnabled),
                ),
              ],
            ),
          ),

          // ── Subject Selector ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _subjects.map((s) {
                  final isSelected = s == _selectedSubject;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSubject = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : AppTheme.bgLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.borderLight),
                      ),
                      child: Text(s, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Chat Messages ──
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcome()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) return _buildTypingIndicator();
                      return _ChatBubble(message: _messages[index]).animate().fadeIn().slideY(begin: 0.05);
                    },
                  ),
          ),

          // ── Input Area ──
          PremiumCard(
            opacity: 1,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.tips_and_updates_rounded, color: AppTheme.accent, size: 16),
                    const SizedBox(width: 8),
                    const Text('Guided thinking', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                    const Spacer(),
                    Switch.adaptive(
                      value: _showHintFirst,
                      onChanged: (v) => setState(() => _showHintFirst = v),
                      activeColor: AppTheme.primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(_selectedImage!.path), height: 100, width: 100, fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: -10,
                          top: -10,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: AppTheme.danger),
                            onPressed: () => setState(() => _selectedImage = null),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_a_photo_rounded, color: AppTheme.primary),
                      onPressed: _pickImage,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _questionCtrl,
                        maxLines: 4,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: _isListening ? 'Listening...' : 'Transmit your question to AI...',
                          filled: true,
                          fillColor: AppTheme.bgLight,
                          prefixIcon: IconButton(
                            icon: Icon(_isListening ? Icons.mic_rounded : Icons.mic_none_rounded, color: _isListening ? AppTheme.accent : AppTheme.textSecondary),
                            onPressed: _listen,
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _isLoading ? null : _askQuestion,
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(gradient: _isLoading ? null : AppTheme.meshGradient, color: _isLoading ? AppTheme.borderLight : null, borderRadius: BorderRadius.circular(18)),
                        child: Icon(_isLoading ? Icons.hourglass_empty_rounded : Icons.bolt_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: AppTheme.meshGradient, shape: BoxShape.circle),
              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 60),
            ).animate().scale(delay: 200.ms),
            const SizedBox(height: 24),
            const Text('How can I assist your learning?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text('Ask any homework problem. I provide logical steps, hints, and full solutions to master your subjects.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5)),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                'Solve x² + 5x + 6 = 0',
                'What is photosynthesis?',
                'Laws of motion?',
                'Who wrote Hamlet?',
              ].map((q) => _buildSuggestionChip(q)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String q) {
    return GestureDetector(
      onTap: () => _questionCtrl.text = q,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.primary.withOpacity(0.2))),
        child: Text(q, style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.borderLight)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Neural processing...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String subject;
  final bool isHint;
  final bool isError;
  final List<String> steps;
  final String? imagePath;

  _ChatMessage({required this.text, required this.isUser, required this.subject, this.isHint = false, this.isError = false, this.steps = const [], this.imagePath});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(width: 32, height: 32, decoration: BoxDecoration(gradient: AppTheme.meshGradient, shape: BoxShape.circle), child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 16)),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isUser ? AppTheme.primary : (message.isError ? AppTheme.danger.withOpacity(0.1) : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    boxShadow: [BoxShadow(color: (isUser ? AppTheme.primary : Colors.black).withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.imagePath != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(message.imagePath!), height: 150, width: double.infinity, fit: BoxFit.cover),
                          ),
                        ),
                      isUser
                          ? Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500, height: 1.5))
                          : MarkdownBody(
                              data: message.text,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.6, fontWeight: FontWeight.w500),
                                h3: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 18, height: 2.0),
                                listBullet: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900),
                                code: TextStyle(backgroundColor: AppTheme.bgLight, color: Colors.indigo[900], fontFamily: 'Courier'),
                              ),
                            ),
                    ],
                  ),
                ),
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: message.text));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied knowledge to clipboard'), behavior: SnackBarBehavior.floating));
                      },
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.copy_rounded, size: 12, color: AppTheme.textSecondary), const SizedBox(width: 4), Text('STORE TO MEMORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 1))]),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(width: 32, height: 32, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), shape: BoxShape.circle), child: const Icon(Icons.person_outline_rounded, color: AppTheme.primary, size: 18)),
          ],
        ],
      ),
    );
  }
}

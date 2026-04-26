import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import '../../utils/config.dart';
import '../../utils/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import '../../services/ai_service.dart';


class FlashcardGeneratorScreen extends StatefulWidget {
  final String? initialFileUrl;
  const FlashcardGeneratorScreen({super.key, this.initialFileUrl});

  @override
  State<FlashcardGeneratorScreen> createState() => _FlashcardGeneratorScreenState();
}

class _FlashcardGeneratorScreenState extends State<FlashcardGeneratorScreen> {
  final _contentController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _flashcards = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialFileUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateFromUrl(widget.initialFileUrl!);
      });
    }
  }

  Future<void> _generateFromUrl(String url) async {
    _startLoading();
    try {
      final response = await http.post(
        Uri.parse(Config.endpoint('/generate-flashcards')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'file_url': url}),
      ).timeout(const Duration(seconds: 90));
      _handleResponse(response.statusCode, response.body);
    } catch (e) {
      _showError(msg: e is TimeoutException ? 'Server took too long. Try smaller content.' : 'Error generating flashcards.');
    }
  }

  Future<void> _generateFromText() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;
    _startLoading();
    try {
      final flashcards = await AIService().generateFlashcards(content);
      setState(() {
        _flashcards = flashcards;
        _isLoading = false;
      });
      if (_flashcards.isEmpty) _showError(msg: 'No flashcards could be extracted.');
    } catch (e) {
      _showError(msg: 'AI Generation failed: $e');
    }
  }

  Future<void> _pickFileAndGenerate() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
      withData: true,
    );

    if (result == null || result.files.single.bytes == null) return;
    _startLoading();

    try {
      var request = http.MultipartRequest('POST', Uri.parse(Config.endpoint('/generate-flashcards')));
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        result.files.single.bytes!,
        filename: result.files.single.name,
      ));
      
      var response = await request.send().timeout(const Duration(seconds: 60));
      var responseBody = await response.stream.bytesToString();
      _handleResponse(response.statusCode, responseBody);
    } catch (e) {
      _showError(msg: e is TimeoutException ? 'Document too large for fast processing.' : 'Upload failed.');
    }
  }

  void _startLoading() {
    setState(() {
      _isLoading = true;
      _flashcards = [];
      _currentIndex = 0;
    });
  }

  void _handleResponse(int statusCode, String body) {
    if (statusCode == 200) {
      try {
        final decoded = jsonDecode(body);
        setState(() {
          _flashcards = decoded['flashcards'] ?? [];
          _isLoading = false;
        });
        if (_flashcards.isEmpty) _showError(msg: 'No flashcards could be extracted from this context.');
      } catch (e) {
        _showError(msg: 'Neural decoding failed. Malformed response from server.');
      }
    } else {
      _showError();
    }
  }

  void _showError({String msg = 'Error generating flashcards from document'}) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.accent,
        elevation: 0,
        title: const Text('AI Auto Flashcards', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: true,
      ),
      body: _flashcards.isEmpty
          ? _buildInputArea()
          : _buildFlashcardPlayer(),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Paste text or upload notes to auto-generate swipeable Flashcards!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _contentController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Paste a chapter summary, long paragraph, or theory...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickFileAndGenerate,
                  icon: _isLoading ? const SizedBox() : const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Upload PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _generateFromText,
                  icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.flash_on_rounded),
                  label: Text(_isLoading ? 'AI Thinking...' : 'Generate Text'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '⚡ AI Server is waking up (30-40s)...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
              ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
            ),
        ],
      ),
    );
  }

  Widget _buildFlashcardPlayer() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Card ${_currentIndex + 1} of ${_flashcards.length}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
              TextButton.icon(
                onPressed: () => setState(() => _flashcards.clear()),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Make New'),
              )
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Dismissible(
              key: ValueKey(_currentIndex),
              direction: DismissDirection.horizontal,
              background: Container(
                decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.2), borderRadius: BorderRadius.circular(30)),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 40),
                child: const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 50),
              ),
              secondaryBackground: Container(
                decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.2), borderRadius: BorderRadius.circular(30)),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 40),
                child: const Icon(Icons.replay_rounded, color: AppTheme.danger, size: 50),
              ),
              onDismissed: (direction) {
                if (_currentIndex < _flashcards.length - 1) {
                  setState(() => _currentIndex++);
                } else {
                  setState(() => _flashcards.clear()); // Reset after last
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All cards revised! 🎉')));
                }
              },
              child: _TinderCard(data: _flashcards[_currentIndex])
                  .animate(key: ValueKey(_currentIndex))
                  .scale(begin: const Offset(0.8, 0.8), duration: 300.ms, curve: Curves.easeOutBack),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Swipe LEFT to Revise Again  •  Swipe RIGHT if you know it', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 60),
      ],
    );
  }
}

class _TinderCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const _TinderCard({required this.data});

  @override
  State<_TinderCard> createState() => _TinderCardState();
}

class _TinderCardState extends State<_TinderCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFront = !_isFront;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final value = _animation.value;
          final angle = value * pi;
          // Apply a 3D perspective
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);
            
          final isBackVisible = value >= 0.5;

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isBackVisible
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildCardContent(isFront: false),
                  )
                : _buildCardContent(isFront: true),
          );
        },
      ),
    );
  }

  Widget _buildCardContent({required bool isFront}) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: 400,
      decoration: BoxDecoration(
        gradient: isFront 
            ? const LinearGradient(colors: [Colors.white, Color(0xFFF8FAFC)], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: (isFront ? Colors.black : const Color(0xFF6366F1)).withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
        border: Border.all(color: isFront ? Colors.grey.withOpacity(0.1) : Colors.transparent, width: 2),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20, top: -20,
            child: Icon(
              isFront ? Icons.auto_awesome_rounded : Icons.lightbulb_rounded,
              size: 150, color: (isFront ? AppTheme.accent : Colors.white).withOpacity(0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isFront ? Icons.question_answer_rounded : Icons.workspace_premium_rounded,
                  size: 50,
                  color: isFront ? AppTheme.accent : Colors.white70,
                ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 30),
                Text(
                  isFront ? widget.data['q'] ?? 'Question missing' : widget.data['a'] ?? 'Answer missing',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isFront ? 24 : 20,
                    fontWeight: FontWeight.w900,
                    color: isFront ? AppTheme.textPrimary : Colors.white,
                    height: 1.4,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isFront ? AppTheme.accent.withOpacity(0.1) : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 16, color: isFront ? AppTheme.accent : Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Tap to flip',
                        style: TextStyle(color: isFront ? AppTheme.accent : Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

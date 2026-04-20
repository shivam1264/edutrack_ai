import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/config.dart';
import '../../utils/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';

class FlashcardGeneratorScreen extends StatefulWidget {
  const FlashcardGeneratorScreen({super.key});

  @override
  State<FlashcardGeneratorScreen> createState() => _FlashcardGeneratorScreenState();
}

class _FlashcardGeneratorScreenState extends State<FlashcardGeneratorScreen> {
  final _contentController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _flashcards = [];
  int _currentIndex = 0;

  Future<void> _generateCards() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isLoading = true;
      _flashcards = [];
      _currentIndex = 0;
    });

    try {
      final response = await http.post(
        Uri.parse(Config.endpoint('/generate-flashcards')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': content}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _flashcards = jsonDecode(response.body)['flashcards'] ?? [];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error generating flashcards')));
    } finally {
      setState(() => _isLoading = false);
    }
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
          const Text('Paste text or notes to auto-generate swipeable Flashcards!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
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
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _generateCards,
            icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.flash_on_rounded),
            label: Text(_isLoading ? 'Generating Magic...' : 'Generate Flashcards'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
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
              onDismissed: (direction) {
                if (_currentIndex < _flashcards.length - 1) {
                  setState(() => _currentIndex++);
                } else {
                  setState(() => _flashcards.clear()); // Reset after last
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All cards revised! 🎉')));
                }
              },
              child: _TinderCard(data: _flashcards[_currentIndex])
                  .animate()
                  .scale(begin: const Offset(0.8, 0.8), duration: 300.ms, curve: Curves.easeOutBack),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Swipe LEFT to Revise Again  •  Swipe RIGHT if you know it', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 20),
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

class _TinderCardState extends State<_TinderCard> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showAnswer = !_showAnswer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: MediaQuery.of(context).size.width * 0.85,
        height: 400,
        decoration: BoxDecoration(
          color: _showAnswer ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _showAnswer ? Icons.lightbulb_rounded : Icons.help_outline_rounded,
                size: 60,
                color: _showAnswer ? Colors.white.withOpacity(0.5) : AppTheme.accent.withOpacity(0.5),
              ),
              const SizedBox(height: 30),
              Text(
                _showAnswer ? widget.data['a'] ?? 'Answer missing' : widget.data['q'] ?? 'Question missing',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _showAnswer ? 18 : 22,
                  fontWeight: FontWeight.w900,
                  color: _showAnswer ? Colors.white : AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              Text(
                'Tap to flip',
                style: TextStyle(color: _showAnswer ? Colors.white70 : AppTheme.textSecondary, fontWeight: FontWeight.bold),
              )
            ],
          ),
        ),
      ),
    );
  }
}

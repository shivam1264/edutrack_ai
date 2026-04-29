import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/config.dart' as app_config;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../services/cloudinary_service.dart';

class DoubtBoxScreen extends StatefulWidget {
  const DoubtBoxScreen({super.key});

  @override
  State<DoubtBoxScreen> createState() => _DoubtBoxScreenState();
}

class _DoubtBoxScreenState extends State<DoubtBoxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _questionCtrl = TextEditingController();
  String _selectedSubject = 'Mathematics';
  bool _isSubmitting = false;
  XFile? _selectedImage;

  // Speech to Text variables
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  final List<String> _subjects = [
    'Mathematics', 'Science', 'Physics', 'Chemistry',
    'Biology', 'English', 'Hindi', 'History', 'Geography', 'Computer Science',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _questionCtrl.dispose();
    super.dispose();
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _submitDoubt() async {
    if (_questionCtrl.text.trim().isEmpty && _selectedImage == null) return;
    final user = context.read<AuthProvider>().user;
    setState(() => _isSubmitting = true);
    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        final result = await CloudinaryService.instance.uploadBytes(bytes, _selectedImage!.name);
        imageUrl = result?.secureUrl;
      }

      final questionText = _questionCtrl.text.trim();
      final subject = _selectedSubject;
      final grade = user?.classId ?? 'Grade 10';

      final docRef = await FirebaseFirestore.instance.collection('doubts').add({
        'studentId': user?.uid,
        'studentName': user?.name ?? 'Student',
        'schoolId': user?.schoolId ?? '',
        'school_id': user?.schoolId ?? '',
        'classId': user?.classId ?? '',
        'class_id': user?.classId ?? '',
        'subject': subject,
        'question': questionText,
        'imageUrl': imageUrl,
        'status': 'pending',
        'answer': '✨ Generating Best Answer for you...',
        'answeredBy': 'EduTrack AI',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      _questionCtrl.clear();
      setState(() {
        _selectedImage = null;
      });
      
      _generateAIBestAnswer(docRef.id, questionText, subject, grade, imageUrl);

      if (mounted) {
        _tabCtrl.animateTo(1);
      }
    } catch (_) {}
    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _generateAIBestAnswer(String docId, String question, String subject, String grade, String? imageUrl) async {
    try {
      final res = await http.post(
        Uri.parse(app_config.Config.endpoint('/generate-best-answer')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'question': question,
          'subject': subject,
          'grade': grade,
          'imageUrl': imageUrl, // Now passing the image URL to AI
        }),
      ).timeout(const Duration(seconds: 40));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await FirebaseFirestore.instance.collection('doubts').doc(docId).update({
          'answer': data['answer'],
          'status': 'ai_answered',
          'isAI': true,
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text('Doubt Box', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabItem(0, 'Ask'),
                const SizedBox(width: 8),
                _buildTabItem(1, 'My Doubts'),
                const SizedBox(width: 8),
                _buildTabItem(2, 'Answered'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildAskTab(),
                _buildListTab('my'),
                _buildListTab('answered'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    bool isSelected = _tabCtrl.index == index;
    return GestureDetector(
      onTap: () => setState(() => _tabCtrl.animateTo(index)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildAskTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Subject', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSubject,
                  isExpanded: true,
                  items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 14)))).toList(),
                  onChanged: (v) => setState(() => _selectedSubject = v!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                TextField(
                  controller: _questionCtrl,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'I need help with linear equations...',
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FloatingActionButton.small(
                    onPressed: _listen,
                    backgroundColor: _isListening ? Colors.red : const Color(0xFF6366F1),
                    child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                ),
                child: Column(
                  children: [
                    Icon(_selectedImage != null ? Icons.image : Icons.add_photo_alternate, color: const Color(0xFF6366F1), size: 32),
                    const SizedBox(height: 8),
                    Text(
                      _selectedImage != null ? 'Image Selected' : 'Attach Photo (Optional)',
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 16),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(_selectedImage!.path, height: 120, width: double.infinity, fit: BoxFit.cover)
                        : Image.file(File(_selectedImage!.path), height: 120, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitDoubt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('+ Ask a Doubt', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTab(String type) {
    final uid = context.read<AuthProvider>().user?.uid ?? '';
    var query = FirebaseFirestore.instance.collection('doubts').where('studentId', isEqualTo: uid);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        
        var docs = snap.data!.docs;
        
        // Filter in memory to avoid Firestore composite index requirement
        if (type == 'answered') {
          docs = docs.where((d) => (d.data() as Map<String, dynamic>)['status'] != 'pending').toList();
        } else {
          docs = docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'pending').toList();
        }
        
        // Sort by createdAt descending
        docs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'];
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'];
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) return const Center(child: Text('No doubts here'));

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final isPending = data['status'] == 'pending';
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${data['subject']} — ${data['isAI'] == true ? 'AI' : 'Teacher'}', 
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF6366F1))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPending ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPending ? 'Pending' : 'Answered',
                          style: TextStyle(color: isPending ? Colors.orange : Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(data['question'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(data['imageUrl'], height: 150, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ],
                  if (data['answer'] != null && data['answer'].toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(data['answer'] ?? '', style: const TextStyle(color: Color(0xFF64748B), height: 1.5, fontSize: 13)),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

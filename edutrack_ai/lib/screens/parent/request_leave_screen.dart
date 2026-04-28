import 'dart:convert';
import '../../utils/config.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/leave_service.dart';
import '../../utils/app_theme.dart';
import 'package:http/http.dart' as http;
import '../../utils/config.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RequestLeaveScreen extends StatefulWidget {
  final String? studentId;
  final String? classId;
  const RequestLeaveScreen({super.key, this.studentId, this.classId});

  @override
  State<RequestLeaveScreen> createState() => _RequestLeaveScreenState();
}

class _RequestLeaveScreenState extends State<RequestLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  String _leaveType = 'medical';
  File? _selectedFile;
  bool _isProcessingAI = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _selectedFile = File(image.path);
      _isProcessingAI = true;
    });

    try {
      final bytes = await _selectedFile!.readAsBytes();
      final base64Image = base64.encode(bytes);

      final response = await http.post(
        Uri.parse(Config.endpoint('/analyze-leave-doc')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_data': base64Image}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _reasonCtrl.text = result['reason'] ?? '';
          _leaveType = result['type'] ?? 'medical';
          if (result['start_date'] != null) {
            _startDate = DateTime.parse(result['start_date']);
          }
          if (result['end_date'] != null) {
            _endDate = DateTime.parse(result['end_date']);
          }
        });
        _showSnack('AI analyzed the document and pre-filled the form! ✨');
      }
    } catch (e) {
      _showSnack('AI Analysis skipped. Manual entry enabled.', isError: true);
    }

    setState(() => _isProcessingAI = false);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.danger : AppTheme.secondary,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    try {
      final user = context.read<AuthProvider>().user;
      final studentId = widget.studentId ?? user?.parentOf?.first ?? '';
      
      // Fetch student's classId if not provided
      String? actualClassId = widget.classId;
      if (actualClassId == null && studentId.isNotEmpty) {
        final studentDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(studentId)
            .get();
        if (studentDoc.exists) {
          actualClassId = studentDoc.data()?['class_id'] as String?;
        }
      }
      
      if (actualClassId == null) {
        throw Exception('Unable to determine student class. Please contact support.');
      }
      
      await LeaveService().submitLeaveRequest(
        studentId: studentId,
        parentId: user?.uid ?? '',
        classId: actualClassId,
        startDate: _startDate,
        endDate: _endDate,
        reason: _reasonCtrl.text.trim(),
        type: _leaveType,
        documentFile: _selectedFile,
      );

      if (mounted) {
        Navigator.pop(context);
        _showSnack('Leave request sent to teacher! 📬');
      }
    } catch (e) {
      _showSnack('Submission failed: $e', isError: true);
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('New Leave Application'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isSubmitting 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAIScanButton(),
                  const SizedBox(height: 24),
                  const Text('Application Details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 16),
                  
                  // Leave Type
                  DropdownButtonFormField<String>(
                    value: _leaveType,
                    decoration: const InputDecoration(labelText: 'Leave Type', prefixIcon: Icon(Icons.category_rounded)),
                    items: ['medical', 'personal', 'emergency', 'other']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
                    onChanged: (v) => setState(() => _leaveType = v!),
                  ),
                  const SizedBox(height: 16),

                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: _DatePicker(
                          label: 'From',
                          value: _startDate,
                          onChanged: (d) => setState(() => _startDate = d),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DatePicker(
                          label: 'To',
                          value: _endDate,
                          onChanged: (d) => setState(() => _endDate = d),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Reason
                  TextFormField(
                    controller: _reasonCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Reason for leave',
                      alignLabelWithHint: true,
                      prefixIcon: Icon(Icons.description_rounded),
                    ),
                    validator: (v) => v?.isEmpty == true ? 'Reason is required' : null,
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Submit Application', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildAIScanButton() {
    return GestureDetector(
      onTap: _isProcessingAI ? null : _pickDocument,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 2),
          boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 15)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: _isProcessingAI 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.document_scanner_rounded, color: AppTheme.primary),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_isProcessingAI ? 'AI Analyzing...' : 'One-Tap AI Scan', 
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primary)),
                  const SizedBox(height: 4),
                  const Text('Upload Medical Slips or Notes to auto-fill this form', 
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  const _DatePicker({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (d != null) onChanged(d);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            Text(DateFormat('dd MMM').format(value), 
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

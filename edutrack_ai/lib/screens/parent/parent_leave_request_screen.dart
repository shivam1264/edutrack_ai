import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/leave_service.dart';
import 'package:provider/provider.dart';
import '../../widgets/premium_card.dart';
import 'package:intl/intl.dart';

class ParentLeaveRequestScreen extends StatefulWidget {
  const ParentLeaveRequestScreen({super.key});

  @override
  State<ParentLeaveRequestScreen> createState() => _ParentLeaveRequestScreenState();
}

class _ParentLeaveRequestScreenState extends State<ParentLeaveRequestScreen> {
  String? _selectedType;
  DateTime? _fromDate;
  DateTime? _toDate;
  final _reasonCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Leave Request', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Leave Type'),
            DropdownButtonFormField<String>(
              decoration: _inputDecoration('Select Type'),
              items: ['Sick Leave', 'Casual Leave', 'Family Event', 'Other'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _selectedType = v),
            ),
            const SizedBox(height: 20),
            _buildLabel('From Date'),
            _datePickerField(true),
            const SizedBox(height: 20),
            _buildLabel('To Date'),
            _datePickerField(false),
            const SizedBox(height: 20),
            _buildLabel('Reason'),
            TextField(
              controller: _reasonCtrl,
              maxLines: 4,
              decoration: _inputDecoration('Enter reason'),
            ),
            const SizedBox(height: 24),
            _buildLabel('Upload Document (Optional)'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
              child: Row(
                children: [
                  const Icon(Icons.cloud_upload_outlined, color: Colors.grey),
                  const SizedBox(width: 12),
                  const Text('Choose File', style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), 
                  foregroundColor: Colors.white, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedType == null || _fromDate == null || _toDate == null || _reasonCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = context.read<AuthProvider>().user;
      final childId = (user?.parentOf != null && user!.parentOf!.isNotEmpty) ? user.parentOf!.first : '';

      if (childId.isEmpty) {
        throw 'No student linked to this parent account';
      }

      // Fetch child's classId
      final studentSnap = await FirebaseFirestore.instance.collection('users').doc(childId).get();
      final classId = (studentSnap.data() as Map<String, dynamic>?)?['class_id'] ?? '';

      if (classId.isEmpty) {
        throw 'Student is not assigned to any class';
      }
      
      await LeaveService().submitLeaveRequest(
        studentId: childId,
        parentId: user?.uid ?? '',
        classId: classId,
        startDate: _fromDate!,
        endDate: _toDate!,
        reason: _reasonCtrl.text.trim(),
        type: _selectedType!,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave request submitted successfully'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF64748B))),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
    );
  }

  Widget _datePickerField(bool isFrom) {
    final date = isFrom ? _fromDate : _toDate;
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
        if (d != null) setState(() => isFrom ? _fromDate = d : _toDate = d);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(date == null ? 'Select Date' : DateFormat('dd MMM, yyyy').format(date), style: TextStyle(color: date == null ? Colors.grey : Colors.black, fontSize: 14)),
            const Icon(Icons.calendar_today_rounded, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}

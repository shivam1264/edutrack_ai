import 'package:flutter/material.dart';
import '../../services/leave_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

class LeaveApprovalScreen extends StatefulWidget {
  final String classId;
  const LeaveApprovalScreen({super.key, required this.classId});

  @override
  State<LeaveApprovalScreen> createState() => _LeaveApprovalScreenState();
}

class _LeaveApprovalScreenState extends State<LeaveApprovalScreen> {
  final LeaveService _service = LeaveService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Leave Management'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: StreamBuilder<List<LeaveRequestModel>>(
        stream: _service.streamPendingLeaves(widget.classId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) return _buildEmpty();

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final leave = items[index];
              return _LeaveRequestCard(leave: leave).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 60, color: AppTheme.borderLight),
          const SizedBox(height: 16),
          Text('All clear! No pending leave requests.', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _LeaveRequestCard extends StatelessWidget {
  final LeaveRequestModel leave;
  const _LeaveRequestCard({required this.leave});

  @override
  Widget build(BuildContext context) {
    final range = '${DateFormat('dd MMM').format(leave.startDate)} - ${DateFormat('dd MMM').format(leave.endDate)}';

    return PremiumCard(
      opacity: 1,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (leave.type == 'medical' ? Colors.red : Colors.blue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(leave.type.toUpperCase(), 
                  style: TextStyle(color: leave.type == 'medical' ? Colors.red : Colors.blue, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
              const Spacer(),
              Text(DateFormat('dd MMM, hh:mm a').format(leave.createdAt), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder(
            future: AuthService().getUserModel(leave.studentId),
            builder: (context, snapshot) {
              final name = snapshot.data?.name ?? 'Loading...';
              return Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16));
            },
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_month_rounded, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(range, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(leave.reason, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.4)),
          
          if (leave.docUrl != null) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _viewDoc(context, leave.docUrl!),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderLight)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.attachment_rounded, size: 16, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text('View Proof Document', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _update(context, 'rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _update(context, 'approved'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _update(BuildContext context, String status) async {
    await LeaveService().updateLeaveStatus(leave.id, status);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request $status!')));
  }

  void _viewDoc(BuildContext context, String url) async {
    final isPdf = url.toLowerCase().contains('.pdf');
    if (isPdf) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open PDF viewer.')));
        }
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(url, fit: BoxFit.contain),
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
        ),
      );
    }
  }
}

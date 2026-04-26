import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminParentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> parentData;
  final String parentId;

  const AdminParentDetailScreen({super.key, required this.parentData, required this.parentId});

  @override
  State<AdminParentDetailScreen> createState() => _AdminParentDetailScreenState();
}

class _AdminParentDetailScreenState extends State<AdminParentDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.parentId).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? widget.parentData;
        final childrenIds = List<String>.from(data['parent_of'] ?? []);

        return Scaffold(
          backgroundColor: AppTheme.bgLight,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, data),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const Text('Linked Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const SizedBox(height: 16),
                    _buildChildrenList(childrenIds),
                    const SizedBox(height: 32),
                    const Text('Communication & Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    const SizedBox(height: 16),
                    _buildInfoTile('Email Address', data['email'] ?? 'N/A', Icons.email_outlined),
                    _buildInfoTile('Emergency Contact', data['phone'] ?? 'Not Provided', Icons.phone_android_rounded),
                    _buildInfoTile('Relationship', data['relationship'] ?? 'Guardian', Icons.people_outline_rounded),
                    _buildInfoTile('Address', data['address'] ?? 'No Address on File', Icons.location_on_outlined),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _editParentProfileDialog(data),
            backgroundColor: const Color(0xFF0F172A),
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
            label: const Text('Edit Guardian Info', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      }
    );
  }

  Widget _buildAppBar(BuildContext context, Map<String, dynamic> data) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: const Color(0xFF0F172A),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(data['name']?[0].toUpperCase() ?? 'P', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? 'Parent/Guardian', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        Text('Verified Guardian • ${data['status']?.toUpperCase() ?? "ACTIVE"}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenList(List<String> childrenIds) {
    if (childrenIds.isEmpty) {
      return const PremiumCard(
        padding: EdgeInsets.all(20),
        child: Text('No students linked to this account.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
      );
    }

    return Column(
      children: childrenIds.map((id) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(id).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) return const SizedBox();

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PremiumCard(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                leading: const Icon(Icons.face_rounded, color: Colors.blueAccent),
                title: Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('ID: ${id.substring(0, 8)} | Class: ${data['class_id'] ?? 'N/A'}'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ),
            ),
          );
        },
      )).toList(),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editParentProfileDialog(Map<String, dynamic> data) {
    final phoneCtrl = TextEditingController(text: data['phone']);
    final relCtrl = TextEditingController(text: data['relationship']);
    final addrCtrl = TextEditingController(text: data['address']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Update Guardian Record', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Emergency Contact', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 12),
            TextField(controller: relCtrl, decoration: const InputDecoration(labelText: 'Relationship', prefixIcon: Icon(Icons.people))),
            const SizedBox(height: 12),
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Residential Address', prefixIcon: Icon(Icons.location_on))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(widget.parentId).update({
                'phone': phoneCtrl.text.trim(),
                'relationship': relCtrl.text.trim(),
                'address': addrCtrl.text.trim(),
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save Guardian Info'),
          ),
        ],
      ),
    );
  }
}

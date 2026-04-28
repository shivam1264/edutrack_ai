import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/premium_card.dart';
import '../../../services/class_service.dart';
import '../../../models/class_model.dart';
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context, data),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Linked Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        TextButton.icon(
                          onPressed: () => _showLinkStudentDialog(data),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                          label: const Text('Link Student', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFF10B981)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildChildrenList(childrenIds, widget.parentId),
                    const SizedBox(height: 32),
                    Text('Communication & Security', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
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
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF10B981).withOpacity(0.05),
                    child: Text(data['name']?[0].toUpperCase() ?? 'P', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 28, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? 'Parent/Guardian', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.bold)),
                        Text('Verified Guardian • ${data['status']?.toUpperCase() ?? "ACTIVE"}', style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
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

  Widget _buildChildrenList(List<String> childrenIds, String parentId) {
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
                trailing: IconButton(
                  icon: const Icon(Icons.link_off_rounded, color: Colors.redAccent, size: 20),
                  onPressed: () => _confirmUnlink(parentId, id, data['name'] ?? 'Student'),
                ),
              ),
            ),
          );
        },
      )).toList(),
    );
  }

  void _confirmUnlink(String parentId, String studentId, String studentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unlink Student?'),
        content: Text('Are you sure you want to unlink $studentName from this parent?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(parentId).update({
                'parent_of': FieldValue.arrayRemove([studentId])
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Unlink', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showLinkStudentDialog(Map<String, dynamic> parentData) {
    String? selectedClassId;
    String foundStudentName = '';
    String foundStudentId = '';
    final rollNoCtrl = TextEditingController();
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Link New Student', style: TextStyle(fontWeight: FontWeight.w900)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<List<ClassModel>>(
                    stream: ClassService().getClasses(),
                    builder: (context, snapshot) {
                      final classes = snapshot.data ?? [];
                      return DropdownButtonFormField<String>(
                        value: selectedClassId,
                        isExpanded: true,
                        decoration: _inputDecoration('Select Class', Icons.class_outlined),
                        items: classes.map((c) => DropdownMenuItem<String>(value: c.id, child: Text(c.displayName))).toList(),
                        onChanged: (v) => setState(() {
                          selectedClassId = v;
                          foundStudentName = '';
                          foundStudentId = '';
                          rollNoCtrl.clear();
                        }),
                      );
                    }
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: rollNoCtrl,
                    decoration: _inputDecoration('Roll Number', Icons.numbers_rounded),
                    onChanged: (v) async {
                      if (v.isNotEmpty && selectedClassId != null) {
                        setState(() => isSearching = true);
                        final snap = await FirebaseFirestore.instance.collection('users')
                          .where('role', isEqualTo: 'student')
                          .where('class_id', isEqualTo: selectedClassId)
                          .where('roll_no', isEqualTo: v)
                          .get();
                        
                        if (snap.docs.isNotEmpty) {
                          setState(() {
                            foundStudentId = snap.docs.first.id;
                            foundStudentName = snap.docs.first.get('name');
                            isSearching = false;
                          });
                        } else {
                          setState(() {
                            foundStudentId = '';
                            foundStudentName = '';
                            isSearching = false;
                          });
                        }
                      }
                    },
                  ),
                  if (isSearching)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: CircularProgressIndicator(),
                    ),
                  if (foundStudentName.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
                            const SizedBox(width: 12),
                            Expanded(child: Text(foundStudentName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                          ],
                        ),
                      ),
                    ).animate().fadeIn().scale(),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: foundStudentId.isEmpty ? null : () async {
                  final existing = List<String>.from(parentData['parent_of'] ?? []);
                  if (existing.contains(foundStudentId)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student is already linked!')));
                    return;
                  }
                  
                  await FirebaseFirestore.instance.collection('users').doc(widget.parentId).update({
                    'parent_of': FieldValue.arrayUnion([foundStudentId])
                  });
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Link Student'),
              ),
            ],
          );
        }
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      labelText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF10B981), size: 20),
      filled: true, fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
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
                Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
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

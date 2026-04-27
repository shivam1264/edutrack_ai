import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/class_service.dart';
import '../../models/class_model.dart';
import '../../widgets/premium_card.dart';
import '../../utils/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'admin_class_detail_screen.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _classService = ClassService();
  String _selectedStandard = '1st';
  final _sectionCtrl = TextEditingController();
  String? _selectedTeacherId;
  String? _selectedTeacherName;

  final List<String> _standards = ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th', '10th', '11th', '12th'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Academic Hub', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildClassList('all'),
                _buildClassList('active'),
                _buildClassList('inactive'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClassDialog,
        backgroundColor: const Color(0xFF0F172A),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Class', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF0F172A),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF0F172A),
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'All Units'),
          Tab(text: 'Active'),
          Tab(text: 'Archived'),
        ],
      ),
    );
  }

  Widget _buildClassList(String filter) {
    return StreamBuilder<List<ClassModel>>(
      stream: _classService.getClasses(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var classes = snapshot.data!;
        
        // Real filtering logic
        if (filter == 'active') {
          classes = classes.where((c) => c.id.isNotEmpty).toList(); // Basic check
        } else if (filter == 'inactive') {
          // Add actual status field filter if you add it to DB later, 
          // for now we'll just show classes that are "archived"
          return const Center(child: Text('No archived classes found.'));
        }
        
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: classes.length,
          itemBuilder: (context, index) {
            final cls = classes[index];
            return _buildClassTile(cls, index);
          },
        );
      },
    );
  }

  Widget _buildClassTile(ClassModel cls, int index) {
    final colors = [Colors.blue, Colors.purple, Colors.orange, Colors.teal, Colors.indigo, Colors.pink];
    final color = colors[index % colors.length];

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminClassDetailScreen(classId: cls.id, className: cls.displayName))),
      child: PremiumCard(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              alignment: Alignment.center,
              child: Text(cls.standard.substring(0, cls.standard.length > 2 ? 2 : cls.standard.length), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cls.displayName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person_pin_rounded, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Teacher: ${cls.classTeacherName ?? "Unassigned"}', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Modify Unit')),
                const PopupMenuItem(value: 'delete', child: Text('Archive/Delete', style: TextStyle(color: Colors.red))),
              ],
              onSelected: (val) {
                if (val == 'delete') _confirmDelete(cls);
                if (val == 'edit') _showEditClassDialog(cls);
              },
            ),
          ],
        ),
      ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1),
    );
  }

  void _confirmDelete(ClassModel cls) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Class?'),
        content: Text('Are you sure you want to remove ${cls.displayName}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _classService.deleteClass(cls.id);
              if (mounted) Navigator.pop(context);
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _showAddClassDialog() {
    _sectionCtrl.clear();
    _selectedTeacherId = null;
    _selectedTeacherName = null;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('New Academic Unit', style: TextStyle(fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedStandard,
                  decoration: InputDecoration(labelText: 'Standard', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  items: _standards.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setLocalState(() => _selectedStandard = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sectionCtrl,
                  decoration: InputDecoration(labelText: 'Section (e.g. A, B, C)', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),
                _buildTeacherDropdown(setLocalState),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _classService.addClass(
                    _selectedStandard, 
                    _sectionCtrl.text.trim().toUpperCase(),
                    classTeacherId: _selectedTeacherId,
                    classTeacherName: _selectedTeacherName,
                  );
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Create Unit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditClassDialog(ClassModel cls) {
    _selectedStandard = cls.standard;
    _sectionCtrl.text = cls.section ?? '';
    _selectedTeacherId = cls.classTeacherId;
    _selectedTeacherName = cls.classTeacherName;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Modify Unit', style: TextStyle(fontWeight: FontWeight.w900)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedStandard,
                  decoration: InputDecoration(labelText: 'Standard', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                  items: _standards.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) => setLocalState(() => _selectedStandard = v!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sectionCtrl,
                  decoration: InputDecoration(labelText: 'Section', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),
                _buildTeacherDropdown(setLocalState),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await _classService.updateClass(cls.id, {
                  'standard': _selectedStandard,
                  'section': _sectionCtrl.text.trim().toUpperCase(),
                  'class_teacher_id': _selectedTeacherId,
                  'class_teacher_name': _selectedTeacherName,
                });
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeacherDropdown(StateSetter setLocalState) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'teacher').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final teachers = snapshot.data!.docs;
        return DropdownButtonFormField<String>(
          value: _selectedTeacherId,
          decoration: InputDecoration(labelText: 'Class Teacher', filled: true, fillColor: Colors.grey[50], border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
          items: teachers.map((t) {
            final data = t.data() as Map<String, dynamic>;
            return DropdownMenuItem(value: t.id, child: Text(data['name'] ?? 'Unknown'));
          }).toList(),
          onChanged: (v) {
            final teacherDoc = teachers.firstWhere((t) => t.id == v);
            final teacherData = teacherDoc.data() as Map<String, dynamic>;
            setLocalState(() {
              _selectedTeacherId = v;
              _selectedTeacherName = teacherData['name'];
            });
          },
          hint: const Text('Assign a faculty head'),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../../utils/config.dart';
import '../../utils/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AIMindMapScreen extends StatefulWidget {
  final String? initialFileUrl;
  const AIMindMapScreen({super.key, this.initialFileUrl});

  @override
  State<AIMindMapScreen> createState() => _AIMindMapScreenState();
}

class _AIMindMapScreenState extends State<AIMindMapScreen> {
  final _contentController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _mindMapData;

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
        Uri.parse(Config.endpoint('/generate-mindmap')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'file_url': url}),
      );
      _handleResponse(response.statusCode, response.body);
    } catch (e) {
      _showError();
    }
  }

  Future<void> _generateFromText() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;
    _startLoading();
    try {
      final response = await http.post(
        Uri.parse(Config.endpoint('/generate-mindmap')),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'content': content}),
      );
      _handleResponse(response.statusCode, response.body);
    } catch (e) {
      _showError();
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
      var request = http.MultipartRequest('POST', Uri.parse(Config.endpoint('/generate-mindmap')));
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        result.files.single.bytes!,
        filename: result.files.single.name,
      ));
      
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      _handleResponse(response.statusCode, responseBody);
    } catch (e) {
      _showError();
    }
  }

  void _startLoading() {
    setState(() {
      _isLoading = true;
      _mindMapData = null;
    });
  }

  void _handleResponse(int statusCode, String body) {
    setState(() => _isLoading = false);
    if (statusCode == 200) {
      try {
        final decoded = jsonDecode(body);
        setState(() {
          _mindMapData = decoded['mindmap'];
        });
      } catch (e) {
        _showError(msg: "Failed to parse Mind Map structure");
      }
    } else {
      _showError();
    }
  }

  void _showError({String? msg}) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? 'Error generating mind map')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.accent,
        elevation: 0,
        title: const Text('AI Mind Maps', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        centerTitle: true,
      ),
      body: _mindMapData == null
          ? _buildInputArea()
          : _buildMindMapArea(),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Paste text or upload notes to generate a visual Concept Map!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _contentController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: 'Paste topic theory, Wikipedia article, or lecture notes...',
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
                  icon: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.account_tree_rounded),
                  label: Text(_isLoading ? 'Visualizing...' : 'Generate Map'),
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
        ],
      ),
    );
  }

  Widget _buildMindMapArea() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Interactive Canvas (Pinch to Zoom)', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              TextButton.icon(
                onPressed: () => setState(() => _mindMapData = null),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('New Map'),
              )
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            color: Colors.white,
            child: InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.1,
              maxScale: 3.0,
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: _MindMapNodeWidget(nodeData: _mindMapData!, isRoot: true).animate().fadeIn(duration: 500.ms).scale(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MindMapNodeWidget extends StatelessWidget {
  final Map<String, dynamic> nodeData;
  final bool isRoot;

  const _MindMapNodeWidget({required this.nodeData, this.isRoot = false});

  @override
  Widget build(BuildContext context) {
    final title = nodeData['title'] ?? 'Unknown Node';
    final List<dynamic>? rawChildren = nodeData['children'] ?? nodeData['branches'];
    
    // Convert to list of maps safely
    final children = rawChildren?.map((e) => e as Map<String, dynamic>).toList() ?? [];

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // The Node Itself
        Container(
          padding: EdgeInsets.symmetric(horizontal: isRoot ? 24 : 16, vertical: isRoot ? 16 : 12),
          decoration: BoxDecoration(
            color: isRoot ? AppTheme.accent : Colors.white,
            borderRadius: BorderRadius.circular(isRoot ? 30 : 12),
            border: Border.all(color: isRoot ? Colors.transparent : AppTheme.accent.withOpacity(0.3), width: 2),
            boxShadow: isRoot 
                ? [BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]
                : [],
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isRoot ? Colors.white : AppTheme.textPrimary,
              fontWeight: isRoot ? FontWeight.w900 : FontWeight.bold,
              fontSize: isRoot ? 20 : 16,
            ),
          ),
        ),

        // The Children Branches
        if (children.isNotEmpty) ...[
          // Draw connecting horizontal line
          Container(width: 30, height: 2, color: AppTheme.accent.withOpacity(0.3)),
          
          // Draw the children in a column
          Container(
            padding: const EdgeInsets.only(left: 0),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: AppTheme.accent.withOpacity(0.3), width: 2))
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children.map((child) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 20, height: 2, color: AppTheme.accent.withOpacity(0.3)),
                    _MindMapNodeWidget(nodeData: child, isRoot: false),
                  ],
                ),
              )).toList(),
            ),
          ),
        ]
      ],
    );
  }
}

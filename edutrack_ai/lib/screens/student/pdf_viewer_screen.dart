import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    // For network loading, we don't need manual download anymore on SfPdfViewer
    if (mounted) {
      setState(() {
        _isLoading = false;
        _localPath = null; // We'll use network directly
      });
    }
  }

  String _getUserFriendlyError(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('401')) {
      return 'Access denied. The PDF link may have expired or requires authentication.';
    } else if (errorStr.contains('403')) {
      return 'Permission denied. Please check if you have access to this file.';
    } else if (errorStr.contains('404')) {
      return 'PDF not found. The file may have been moved or deleted.';
    } else if (errorStr.contains('timeout') || errorStr.contains('connection')) {
      return 'Connection timeout. Please check your internet connection and try again.';
    } else if (errorStr.contains('certificate') || errorStr.contains('ssl')) {
      return 'Security certificate error. Unable to establish secure connection.';
    }
    return 'Unable to load PDF. Please try opening in browser instead.';
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open browser')),
        );
      }
    }
  }

  Future<void> _openInSystemApp() async {
    if (_localPath == null) {
      // If file not downloaded yet, try to download first
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      await _loadPdf();
    }

    if (_localPath != null) {
      final result = await OpenFile.open(_localPath!);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open PDF: ${result.message}')),
          );
        }
      }
    } else {
      // If still no local file, fallback to browser
      await _openInBrowser();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF2563EB)),
            SizedBox(height: 16),
            Text(
              'Loading PDF...',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFFEF4444),
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading PDF',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPdf,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              // Primary option: Open in System PDF App
              ElevatedButton.icon(
                onPressed: _openInSystemApp,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Open in PDF App'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Opens in Adobe Reader, Google PDF Viewer, etc.',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  _openInBrowser();
                  Navigator.pop(context, false); // Return false to trigger fallback
                },
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open in Browser'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Use Syncfusion PDF Viewer for mobile/web directly from network
    return SfPdfViewer.network(
      widget.pdfUrl,
      canShowScrollHead: true,
      canShowScrollStatus: true,
      pageSpacing: 4,
      onDocumentLoadFailed: (details) {
        debugPrint('PDF Network Load Failed: ${details.description}');
        if (mounted) {
          setState(() {
            _errorMessage = 'Unable to load PDF directly from network. Please use the browser instead.';
          });
        }
      },
    );

    return const Center(
      child: Text('Unable to load PDF'),
    );
  }
}

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

/// Cloudinary free-tier file upload service.
/// Cloud: dwbpbi6zu | Preset: edutrack_uploads (unsigned)
/// Free Plan: 25 GB storage, 25 GB bandwidth/month
class CloudinaryService {
  static final CloudinaryService instance = CloudinaryService._internal();
  factory CloudinaryService() => instance;
  CloudinaryService._internal();

  static const String _cloudName = 'dwbpbi6zu';
  static const String _uploadPreset = 'edutrack_uploads';
  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName';

  /// Upload any file (image, video, pdf, doc) to Cloudinary.
  /// Returns the secure URL of the uploaded file.
  Future<CloudinaryUploadResult?> uploadFile(
    File file, {
    String folder = 'edutrack_ai',
  }) async {
    try {
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final resourceType = _getResourceType(mimeType);

      final uri = Uri.parse('$_uploadUrl/$resourceType/upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder;

      final fileStream = http.ByteStream(file.openRead());
      final length = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        length,
        filename: file.uri.pathSegments.last,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CloudinaryUploadResult(
          secureUrl: data['secure_url'] as String,
          publicId: data['public_id'] as String,
          resourceType: resourceType,
          format: data['format'] as String? ?? '',
          bytes: data['bytes'] as int? ?? 0,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Upload from bytes (e.g. from image_picker web bytes)
  Future<CloudinaryUploadResult?> uploadBytes(
    List<int> bytes,
    String filename, {
    String folder = 'edutrack_ai',
  }) async {
    try {
      final mimeType = lookupMimeType(filename) ?? 'application/octet-stream';
      final resourceType = _getResourceType(mimeType);

      final uri = Uri.parse('$_uploadUrl/$resourceType/upload');
      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = _uploadPreset;
      request.fields['folder'] = folder;
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CloudinaryUploadResult(
          secureUrl: data['secure_url'] as String,
          publicId: data['public_id'] as String,
          resourceType: resourceType,
          format: data['format'] as String? ?? '',
          bytes: data['bytes'] as int? ?? 0,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _getResourceType(String mimeType) {
    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType.startsWith('video/')) return 'video';
    return 'raw'; // pdf, doc, etc.
  }
}

class CloudinaryUploadResult {
  final String secureUrl;
  final String publicId;
  final String resourceType;
  final String format;
  final int bytes;

  CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.resourceType,
    required this.format,
    required this.bytes,
  });

  bool get isImage => resourceType == 'image';
  bool get isVideo => resourceType == 'video';
  bool get isDocument => resourceType == 'raw';

  String get readableSize {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

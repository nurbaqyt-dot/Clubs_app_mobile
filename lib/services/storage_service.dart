import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  final service = StorageService();
  ref.onDispose(service.close);
  return service;
});

class StorageService {
  StorageService({http.Client? client}) : _client = client ?? http.Client();

  static const _cloudName = 'dlntemj8x';
  static const _uploadPreset = 'jihc_uploads';

  final http.Client _client;

  Future<String> uploadImage(XFile file, String path) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('Selected image is empty.');
    }

    final request =
        http.MultipartRequest(
            'POST',
            Uri.https('api.cloudinary.com', '/v1_1/$_cloudName/image/upload'),
          )
          ..fields['upload_preset'] = _uploadPreset
          ..fields['public_id'] = _publicIdFromPath(path)
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: _fileNameFromPath(path, file),
            ),
          );

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body['error'] is Map<String, dynamic>
          ? body['error']['message']
          : null;
      throw Exception(message ?? 'Cloudinary upload failed.');
    }

    final secureUrl = body['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary did not return an image URL.');
    }

    return secureUrl;
  }

  String _publicIdFromPath(String path) {
    final withoutExtension = path.replaceFirst(RegExp(r'\.[^./\\]+$'), '');
    final safePath = withoutExtension.replaceAll(
      RegExp(r'[^a-zA-Z0-9_/-]'),
      '_',
    );
    return '${safePath}_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _fileNameFromPath(String path, XFile file) {
    final pathName = path.split('/').last;
    if (pathName.isNotEmpty) return pathName;
    if (file.name.isNotEmpty) return file.name;
    return 'upload.jpg';
  }

  void close() {
    _client.close();
  }
}

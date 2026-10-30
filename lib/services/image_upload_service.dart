import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

class ImageUploadService {
  ImageUploadService._();

  static const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
  static const maxSizeMb = 5;

  static Future<String?> _token() async {
    try {
      final raw = await _storage.read(key: 'auth');
      if (raw == null) return null;
      return (jsonDecode(raw) as Map<String, dynamic>)['token'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Devuelve un mensaje de error o null si el archivo sirve.
  static String? validate(File file) {
    final name = file.path.toLowerCase();
    final dot = name.lastIndexOf('.');
    final ext = dot >= 0 ? name.substring(dot + 1) : '';
    if (!allowedExtensions.contains(ext)) {
      return 'Solo se permiten imágenes JPG, PNG, WebP o GIF.';
    }
    if (file.lengthSync() > maxSizeMb * 1024 * 1024) {
      return 'La imagen no puede superar $maxSizeMb MB.';
    }
    return null;
  }

  static Future<String> upload(
    File file,
    String folder, {
    String field = 'file',
  }) async {
    final token = await _token();
    if (token == null) throw Exception('Sesión expirada');

    final uri = Uri.parse(
      '$kApiBase/api/v1/images/upload',
    ).replace(queryParameters: {'folder': folder});
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath(field, file.path));

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      String msg = 'Error al subir imagen (${streamed.statusCode})';
      try {
        msg = (jsonDecode(body) as Map)['message'] as String? ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
    final data = jsonDecode(body) as Map<String, dynamic>;
    final url = data['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('El servidor no devolvió la URL de la imagen.');
    }
    return url;
  }

  static Future<void> delete(String url) async {
    try {
      final token = await _token();
      if (token == null) return;
      final uri = Uri.parse(
        '$kApiBase/api/v1/images',
      ).replace(queryParameters: {'url': url});
      await http
          .delete(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Rollback best-effort: no debe impedir que el menú siga utilizable.
    }
  }
}

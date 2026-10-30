import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class InviteStore {
  InviteStore._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _key = 'inv_ref';

  static Future<void> save(String code) async {
    final clean = code.trim().toUpperCase();
    if (clean.isEmpty) return;
    await _storage.write(key: _key, value: clean);
  }

  static Future<String?> read() async {
    final value = await _storage.read(key: _key);
    return value == null || value.isEmpty ? null : value;
  }

  static Future<void> clear() => _storage.delete(key: _key);
}

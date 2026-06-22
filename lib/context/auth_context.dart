import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Equivalente a src/context/AuthContext.jsx en React
// Provee: user, isLoggedIn, token, login(), logout()

class AuthContext extends ChangeNotifier {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Map<String, dynamic>? _user;
  String? _token;
  bool _loading = true;

  Map<String, dynamic>? get user     => _user;
  String?              get token     => _token;
  bool                 get isLoggedIn => _token != null && _user != null;
  bool                 get loading    => _loading;

  // Inicializa desde almacenamiento seguro (equivalente a useEffect en AuthContext.jsx)
  Future<void> init() async {
    try {
      final raw = await _storage.read(key: 'auth');
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _token = data['token'] as String?;
        _user  = data['user'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  // Persiste sesión tras login exitoso
  Future<void> login(Map<String, dynamic> data) async {
    _token = data['token'] as String?;
    _user  = data['user'] as Map<String, dynamic>? ?? data;
    await _storage.write(key: 'auth', value: jsonEncode({'token': _token, 'user': _user}));
    notifyListeners();
  }

  // Actualiza datos del usuario (sin cambiar token)
  Future<void> updateUser(Map<String, dynamic> userData) async {
    _user = userData;
    if (_token != null) {
      await _storage.write(key: 'auth', value: jsonEncode({'token': _token, 'user': _user}));
    }
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user  = null;
    await _storage.delete(key: 'auth');
    notifyListeners();
  }

  // Helper: nombre de display (igual que Sidebar.jsx)
  String get displayName {
    if (_user == null) return '';
    final nombre   = _user!['nombre']   as String? ?? '';
    final apellido = _user!['apellido'] as String? ?? '';
    final full     = '$nombre $apellido'.trim();
    return full.isNotEmpty ? full : (_user!['email'] as String? ?? '').split('@').first;
  }

  String get initial {
    final n = _user?['nombre'] as String? ?? _user?['email'] as String? ?? '?';
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  String? get avatarUrl => _user?['avatar'] as String?;
  String? get email     => _user?['email']  as String?;
}

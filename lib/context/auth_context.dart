import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/api_client.dart';
import '../services/app_cache.dart';
import '../services/auth_service.dart';
import '../services/invite_store.dart';

// Equivalente a src/context/AuthContext.jsx en React
// Provee: user, isLoggedIn, token, refreshToken, login(), logout(), updateUser()

class AuthContext extends ChangeNotifier {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Map<String, dynamic>? _user;
  Map<String, dynamic>? _authData;
  String? _token;
  String? _refreshToken;
  bool _loading = true;
  Future<bool>? _refreshing;

  AuthContext() {
    ApiClient.instance.tokenProvider = () => _token;
    ApiClient.instance.refreshHandler = refreshSession;
    ApiClient.instance.onAuthExpired = forceLogout;
  }

  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty && _user != null;
  bool get loading => _loading;
  bool get requiereUbicacion =>
      _user?['requiereUbicacion'] == true ||
      _authData?['requiereUbicacion'] == true;

  Future<void> init() async {
    try {
      final raw = await _storage.read(key: 'auth');
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _authData = data;
        _token = data['token'] as String?;
        _refreshToken = data['refreshToken'] as String?;
        _user = (data['user'] as Map?)?.cast<String, dynamic>() ?? data;
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> login(Map<String, dynamic> data) async {
    final authData = Map<String, dynamic>.from(data);
    _token = authData['token'] as String?;
    _refreshToken = authData['refreshToken'] as String?;
    _user = (authData['user'] as Map?)?.cast<String, dynamic>() ?? authData;
    _authData = authData;
    await _persist();
    notifyListeners();
  }

  Future<void> updateUser(Map<String, dynamic> userData) async {
    final merged = <String, dynamic>{...?_user, ...userData};
    _user = merged;
    _authData = <String, dynamic>{...?_authData, ...userData, 'user': merged};
    await _persist();
    notifyListeners();
  }

  Future<bool> refreshSession() {
    final current = _refreshing;
    if (current != null) return current;

    final future = _refreshSession();
    _refreshing = future;
    future.whenComplete(() {
      if (identical(_refreshing, future)) _refreshing = null;
    });
    return future;
  }

  Future<bool> _refreshSession() async {
    final refresh = _refreshToken;
    if (refresh == null || refresh.isEmpty) return false;

    try {
      final data = await AuthService.refreshToken(refresh);
      await login(data);
      return true;
    } catch (_) {
      await forceLogout();
      return false;
    }
  }

  Future<void> forceLogout() async {
    _token = null;
    _refreshToken = null;
    _user = null;
    _authData = null;
    try {
      await _storage.delete(key: 'auth');
    } catch (_) {}
    AppCache.clearUserData();
    // Igual que el logout de React (localStorage.clear() salvo '_vt').
    await InviteStore.clear().catchError((_) {});
    notifyListeners();
  }

  Future<void> logout() => forceLogout();

  Future<void> _persist() async {
    if (_token == null || _user == null) return;
    final stored = <String, dynamic>{
      ...?_authData,
      'token': _token,
      'user': _user,
      if (_refreshToken != null) 'refreshToken': _refreshToken,
    };
    await _storage.write(key: 'auth', value: jsonEncode(stored));
  }

  String get displayName {
    final nombre = _user?['nombre'] as String? ?? '';
    final apellido = _user?['apellido'] as String? ?? '';
    final full = '$nombre $apellido'.trim();
    if (full.isNotEmpty) return full;
    return (_user?['email'] as String? ?? '').split('@').first;
  }

  String get initial {
    final n = _user?['nombre'] as String? ?? _user?['email'] as String? ?? '?';
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  String? get avatarUrl =>
      _user?['avatar'] as String? ?? _authData?['avatar'] as String?;
  String? get email =>
      _user?['email'] as String? ?? _authData?['email'] as String?;
  String? get userCode =>
      _user?['userCodigo'] as String? ??
      _user?['codigo'] as String? ??
      _authData?['userCodigo'] as String? ??
      _authData?['codigo'] as String?;

  int? get userId {
    final value = _user?['userId'] ?? _user?['id'];
    return (value as num?)?.toInt();
  }
}

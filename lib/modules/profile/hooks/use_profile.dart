import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../context/auth_context.dart';
import '../../../services/profile_service.dart';

// Equivalente a src/modules/profile/hooks/useProfile.js en React

class UseProfile extends ChangeNotifier {
  UseProfile({required this.auth}) {
    _nombre   = auth.user?['nombre']   as String? ?? '';
    _apellido = auth.user?['apellido'] as String? ?? '';
    _loadProvider();
  }

  final AuthContext auth;

  // ── Datos del perfil ──────────────────────────────────────────────────────
  String  _nombre      = '';
  String  _apellido    = '';
  File?   _fotoFile;
  String? _preview;     // ruta local del archivo elegido
  bool    _saving      = false;
  bool    _saved       = false;
  String  _errorPerfil = '';
  Timer?  _savedTimer;

  // ── Contraseña ─────────────────────────────────────────────────────────────
  String  _currentPwd  = '';
  String  _newPwd      = '';
  bool    _showCurrent = false;
  bool    _showNew     = false;
  bool    _savingPwd   = false;
  bool    _savedPwd    = false;
  String  _errorPwd    = '';
  Timer?  _savedPwdTimer;

  // ── Provider (LOCAL vs GOOGLE) ─────────────────────────────────────────────
  String? _provider;

  // ── Getters ───────────────────────────────────────────────────────────────
  String  get nombre       => _nombre;
  String  get apellido     => _apellido;
  File?   get fotoFile     => _fotoFile;
  String? get preview      => _preview;
  bool    get saving       => _saving;
  bool    get saved        => _saved;
  String  get errorPerfil  => _errorPerfil;

  String  get currentPwd   => _currentPwd;
  String  get newPwd       => _newPwd;
  bool    get showCurrent  => _showCurrent;
  bool    get showNew      => _showNew;
  bool    get savingPwd    => _savingPwd;
  bool    get savedPwd     => _savedPwd;
  String  get errorPwd     => _errorPwd;

  String? get provider => _provider;
  bool    get isLocal  => _provider == 'LOCAL';

  // avatarSrc: primero la preview local, luego el avatar del servidor
  String? get avatarSrc => _preview ?? (auth.user?['avatar'] as String?);
  String  get initial   => auth.initial;

  // ── Load provider ─────────────────────────────────────────────────────────
  Future<void> _loadProvider() async {
    final p = await ProfileService.getProvider();
    _provider = p;
    notifyListeners();
  }

  // ── Setters simples ───────────────────────────────────────────────────────
  void setNombre(String v)      { _nombre     = v; notifyListeners(); }
  void setApellido(String v)    { _apellido   = v; notifyListeners(); }
  void setCurrentPwd(String v)  { _currentPwd = v; notifyListeners(); }
  void setNewPwd(String v)      { _newPwd     = v; notifyListeners(); }
  void toggleShowCurrent()      { _showCurrent = !_showCurrent; notifyListeners(); }
  void toggleShowNew()          { _showNew    = !_showNew; notifyListeners(); }

  // ── Elegir foto desde galería ─────────────────────────────────────────────
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source:    ImageSource.gallery,
      imageQuality: 85,
      maxWidth:  800,
    );
    if (picked == null) return;
    final file = File(picked.path);
    if (await file.length() > 5 * 1024 * 1024) {
      _errorPerfil = 'La imagen no puede superar 5 MB.';
      notifyListeners();
      return;
    }
    _errorPerfil = '';
    _fotoFile = file;
    _preview  = picked.path;
    notifyListeners();
  }

  // ── Guardar perfil ─────────────────────────────────────────────────────────
  Future<void> handleSavePerfil() async {
    if (_nombre.trim().isEmpty) {
      _errorPerfil = 'El nombre es obligatorio';
      notifyListeners();
      return;
    }
    _saving      = true;
    _errorPerfil = '';
    notifyListeners();
    try {
      final updated = await ProfileService.updateProfile(
        nombre:   _nombre.trim(),
        apellido: _apellido.trim(),
        fotoFile: _fotoFile,
      );
      // Merge campos actualizados en AuthContext
      final mergedUser = {
        ...?auth.user,
        'nombre':   updated['nombre'],
        'apellido': updated['apellido'],
        if (updated['avatar'] != null) 'avatar': updated['avatar'],
      };
      await auth.updateUser(mergedUser);
      _saved = true;
      _savedTimer?.cancel();
      _savedTimer = Timer(const Duration(seconds: 2), () {
        _saved = false;
        notifyListeners();
      });
    } catch (e) {
      _errorPerfil = e.toString().replaceFirst('Exception: ', '');
    }
    _saving = false;
    notifyListeners();
  }

  // ── Cambiar contraseña ────────────────────────────────────────────────────
  Future<void> handleSavePwd() async {
    if (_currentPwd.isEmpty || _newPwd.isEmpty) {
      _errorPwd = 'Completa ambos campos';
      notifyListeners();
      return;
    }
    if (_newPwd.length < 6) {
      _errorPwd = 'La nueva contraseña debe tener al menos 6 caracteres';
      notifyListeners();
      return;
    }
    _savingPwd = true;
    _errorPwd  = '';
    notifyListeners();
    try {
      await ProfileService.changePassword(
        currentPassword: _currentPwd,
        newPassword:     _newPwd,
      );
      _currentPwd = '';
      _newPwd     = '';
      _savedPwd   = true;
      _savedPwdTimer?.cancel();
      _savedPwdTimer = Timer(const Duration(seconds: 2), () {
        _savedPwd = false;
        notifyListeners();
      });
    } catch (e) {
      _errorPwd = e.toString().replaceFirst('Exception: ', '');
    }
    _savingPwd = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _savedTimer?.cancel();
    _savedPwdTimer?.cancel();
    super.dispose();
  }
}

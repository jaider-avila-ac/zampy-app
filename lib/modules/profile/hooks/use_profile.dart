import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../context/auth_context.dart';
import '../../../services/app_cache.dart';
import '../../../services/profile_service.dart';
import '../../../shared/location_cascade_input.dart';

// Equivalente a src/modules/profile/hooks/useProfile.js en React

String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

class UseProfile extends ChangeNotifier {
  UseProfile({required this.auth}) {
    _nombre   = auth.user?['nombre']   as String? ?? '';
    _apellido = auth.user?['apellido'] as String? ?? '';
    _telefono            = auth.user?['telefono']            as String? ?? '';
    _direccion           = auth.user?['direccion']           as String? ?? '';
    _direccionReferencia = auth.user?['direccionReferencia'] as String? ?? '';
    _loadMe();
  }

  final AuthContext auth;
  bool _disposed = false;

  static const _tiposImagen = ['jpg', 'jpeg', 'png', 'webp', 'gif'];

  // ── Datos del perfil ──────────────────────────────────────────────────────
  String  _nombre      = '';
  String  _apellido    = '';
  File?   _fotoFile;
  String? _preview;     // ruta local del archivo elegido
  bool    _saving      = false;
  bool    _saved       = false;
  String  _errorPerfil = '';
  Timer?  _savedTimer;

  // ── Ubicación (municipio del catálogo) ─────────────────────────────────────
  LocationCascadeValue _ubicacion = const LocationCascadeValue();
  int     _ubicacionVersion = 0; // fuerza a reconstruir el selector al llegar /me
  bool    _savingUbicacion  = false;
  bool    _savedUbicacion   = false;
  String  _errorUbicacion   = '';
  Timer?  _savedUbicacionTimer;

  // ── Contacto para pedidos ──────────────────────────────────────────────────
  String  _telefono            = '';
  String  _direccion           = '';
  String  _direccionReferencia = '';
  int     _contactoVersion     = 0;
  bool    _savingContact = false;
  bool    _savedContact  = false;
  String  _errorContact  = '';
  Timer?  _savedContactTimer;

  // ── Contraseña ─────────────────────────────────────────────────────────────
  String  _currentPwd  = '';
  String  _newPwd      = '';
  bool    _showCurrent = false;
  bool    _showNew     = false;
  bool    _savingPwd   = false;
  bool    _savedPwd    = false;
  String  _errorPwd    = '';
  int     _pwdVersion  = 0; // limpia los campos tras guardar
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

  LocationCascadeValue get ubicacion => _ubicacion;
  int     get ubicacionVersion => _ubicacionVersion;
  bool    get savingUbicacion  => _savingUbicacion;
  bool    get savedUbicacion   => _savedUbicacion;
  String  get errorUbicacion   => _errorUbicacion;

  String  get telefono            => _telefono;
  String  get direccion           => _direccion;
  String  get direccionReferencia => _direccionReferencia;
  int     get contactoVersion     => _contactoVersion;
  bool    get savingContact => _savingContact;
  bool    get savedContact  => _savedContact;
  String  get errorContact  => _errorContact;

  String  get currentPwd   => _currentPwd;
  String  get newPwd       => _newPwd;
  bool    get showCurrent  => _showCurrent;
  bool    get showNew      => _showNew;
  bool    get savingPwd    => _savingPwd;
  bool    get savedPwd     => _savedPwd;
  String  get errorPwd     => _errorPwd;
  int     get pwdVersion   => _pwdVersion;

  String? get provider => _provider;
  bool    get isLocal  => _provider == 'LOCAL';

  // avatarSrc: primero la preview local, luego el avatar del servidor
  String? get avatarSrc => _preview ?? (auth.user?['avatar'] as String?);
  String  get initial   => auth.initial;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Timer _flash(Timer? previo, void Function() apagar) {
    previo?.cancel();
    return Timer(const Duration(seconds: 2), () {
      apagar();
      _notify();
    });
  }

  // ── /me: provider, ubicación y contacto guardados ─────────────────────────
  Future<void> _loadMe() async {
    final me = await ProfileService.getMe();
    if (me == null) return;
    AppCache.set('perfil', me);
    _provider = me['provider'] as String?;
    final u = me['ubicacion'];
    if (u is Map) {
      _ubicacion = LocationCascadeValue.fromUbicacion(
        Map<String, dynamic>.from(u),
      );
      _ubicacionVersion++;
    }
    // Solo se completa lo que el usuario aún no editó en el formulario.
    if (_telefono.isEmpty && _direccion.isEmpty && _direccionReferencia.isEmpty) {
      _telefono            = me['telefono']            as String? ?? '';
      _direccion           = me['direccion']           as String? ?? '';
      _direccionReferencia = me['direccionReferencia'] as String? ?? '';
      _contactoVersion++;
    }
    _notify();
  }

  // ── Setters simples ───────────────────────────────────────────────────────
  void setNombre(String v)      { _nombre     = v; _notify(); }
  void setApellido(String v)    { _apellido   = v; _notify(); }
  void setCurrentPwd(String v)  { _currentPwd = v; _notify(); }
  void setNewPwd(String v)      { _newPwd     = v; _notify(); }
  void toggleShowCurrent()      { _showCurrent = !_showCurrent; _notify(); }
  void toggleShowNew()          { _showNew    = !_showNew; _notify(); }
  void setUbicacion(LocationCascadeValue v) {
    _ubicacion = v;
    _errorUbicacion = '';
    _notify();
  }
  void setTelefono(String v)            { _telefono = v; _notify(); }
  void setDireccion(String v)           { _direccion = v; _notify(); }
  void setDireccionReferencia(String v) { _direccionReferencia = v; _notify(); }

  // ── Elegir foto desde galería ─────────────────────────────────────────────
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source:    ImageSource.gallery,
      imageQuality: 85,
      maxWidth:  800,
    );
    if (picked == null) return;
    final name = picked.path.toLowerCase();
    final ext = name.contains('.') ? name.substring(name.lastIndexOf('.') + 1) : '';
    if (!_tiposImagen.contains(ext)) {
      _errorPerfil = 'Solo se permiten imágenes JPG, PNG, WebP o GIF.';
      _notify();
      return;
    }
    final file = File(picked.path);
    if (await file.length() > 5 * 1024 * 1024) {
      _errorPerfil = 'La imagen no puede superar 5 MB.';
      _notify();
      return;
    }
    _errorPerfil = '';
    _fotoFile = file;
    _preview  = picked.path;
    _notify();
  }

  // ── Guardar perfil ─────────────────────────────────────────────────────────
  Future<void> handleSavePerfil() async {
    if (_nombre.trim().isEmpty) {
      _errorPerfil = 'El nombre es obligatorio';
      _notify();
      return;
    }
    _saving      = true;
    _errorPerfil = '';
    _notify();
    try {
      final updated = await ProfileService.updateProfile(
        nombre:   _nombre.trim(),
        apellido: _apellido.trim(),
        fotoFile: _fotoFile,
      );
      await auth.updateUser({
        'nombre':   updated['nombre'],
        'apellido': updated['apellido'],
        if (updated['avatar'] != null) 'avatar': updated['avatar'],
      });
      _fotoFile = null;
      _saved = true;
      _savedTimer = _flash(_savedTimer, () => _saved = false);
    } catch (e) {
      _errorPerfil = _msg(e);
    }
    _saving = false;
    _notify();
  }

  // ── Guardar ubicación ──────────────────────────────────────────────────────
  Future<void> handleSaveUbicacion() async {
    final codigo = _ubicacion.municipioCodigo;
    if (codigo == null || codigo.isEmpty) {
      _errorUbicacion = 'Elige el municipio de la lista.';
      _notify();
      return;
    }
    _savingUbicacion = true;
    _errorUbicacion  = '';
    _notify();
    try {
      final u = await ProfileService.saveLocation(codigo);
      if (u != null) {
        _ubicacion = LocationCascadeValue.fromUbicacion(u);
        _ubicacionVersion++;
      }
      await auth.updateUser({'requiereUbicacion': false});
      AppCache.invalidate('perfil');
      _savedUbicacion = true;
      _savedUbicacionTimer =
          _flash(_savedUbicacionTimer, () => _savedUbicacion = false);
    } catch (e) {
      _errorUbicacion = _msg(e);
    }
    _savingUbicacion = false;
    _notify();
  }

  // ── Guardar contacto para pedidos ──────────────────────────────────────────
  Future<void> handleSaveContacto() async {
    _savingContact = true;
    _errorContact  = '';
    _notify();
    try {
      final data = await ProfileService.saveContacto(
        telefono:            _telefono.trim(),
        direccion:           _direccion.trim(),
        direccionReferencia: _direccionReferencia.trim(),
      );
      // El backend devuelve el teléfono en E.164; se sincroniza la sesión
      // para que el carrito tome los valores.
      _telefono = data['telefono'] as String? ?? '';
      _direccion = _direccion.trim();
      _direccionReferencia = _direccionReferencia.trim();
      _contactoVersion++;
      await auth.updateUser({
        'telefono':            _telefono,
        'direccion':           _direccion,
        'direccionReferencia': _direccionReferencia,
      });
      _savedContact = true;
      _savedContactTimer =
          _flash(_savedContactTimer, () => _savedContact = false);
    } catch (e) {
      _errorContact = _msg(e);
    }
    _savingContact = false;
    _notify();
  }

  // ── Cambiar contraseña ────────────────────────────────────────────────────
  Future<void> handleSavePwd() async {
    if (_currentPwd.isEmpty || _newPwd.isEmpty) {
      _errorPwd = 'Completa ambos campos';
      _notify();
      return;
    }
    if (_newPwd.length < 6) {
      _errorPwd = 'La nueva contraseña debe tener al menos 6 caracteres';
      _notify();
      return;
    }
    _savingPwd = true;
    _errorPwd  = '';
    _notify();
    try {
      await ProfileService.changePassword(
        currentPassword: _currentPwd,
        newPassword:     _newPwd,
      );
      _currentPwd = '';
      _newPwd     = '';
      _pwdVersion++;
      _savedPwd   = true;
      _savedPwdTimer = _flash(_savedPwdTimer, () => _savedPwd = false);
    } catch (e) {
      _errorPwd = _msg(e);
    }
    _savingPwd = false;
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _savedTimer?.cancel();
    _savedPwdTimer?.cancel();
    _savedUbicacionTimer?.cancel();
    _savedContactTimer?.cancel();
    super.dispose();
  }
}

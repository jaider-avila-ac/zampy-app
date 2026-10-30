import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../context/auth_context.dart';
import '../../../services/dispositivo_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/app_cache.dart';

// Equivalente a src/modules/profile/hooks/useSettings.js en React

String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

class UseSettings extends ChangeNotifier {
  UseSettings({required this.auth});

  final AuthContext auth;
  bool _disposed = false;

  List<Map<String, dynamic>> _dispositivos = [];
  bool          _loading       = true;
  bool          _loadError     = false;
  String?       _codigoInv;
  String?       _revoking;
  bool          _copied        = false;
  Timer?        _copyTimer;

  // ── Eliminar cuenta ───────────────────────────────────────────────────────
  String  _deleteConfirmWord = '';
  String  _deleteTypedWord   = '';
  bool    _deletingAccount   = false;
  bool    _loadingDeleteCode = false;

  List<Map<String, dynamic>> get dispositivos => _dispositivos;
  bool          get loading      => _loading;
  bool          get loadError    => _loadError;
  String?       get codigoInv   => _codigoInv;
  String?       get revoking    => _revoking;
  bool          get copied      => _copied;

  String get deleteConfirmWord => _deleteConfirmWord;
  String get deleteTypedWord   => _deleteTypedWord;
  bool   get deletingAccount   => _deletingAccount;
  bool   get loadingDeleteCode => _loadingDeleteCode;
  bool   get puedeEliminar =>
      !_loadingDeleteCode &&
      _deleteConfirmWord.isNotEmpty &&
      _deleteTypedWord == _deleteConfirmWord;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    _loading   = true;
    _loadError = false;

    // Stale-while-revalidate para dispositivos
    final cached = AppCache.get('dispositivos');
    if (cached is List) {
      _dispositivos = cached.cast<Map<String, dynamic>>();
      _loading      = false;
    }
    _notify();

    await Future.wait([_loadDispositivos(), _loadMe()]);

    _loading = false;
    _notify();
  }

  Future<void> _loadDispositivos() async {
    try {
      final data = await DispositivoService.getDispositivos();
      AppCache.set('dispositivos', data);
      _dispositivos = data;
      _loadError = false;
    } catch (_) {
      AppCache.markStale('dispositivos');
      if (_dispositivos.isEmpty) _loadError = true;
    }
  }

  Future<void> _loadMe() async {
    final cached = AppCache.get('perfil');
    if (cached is Map) _codigoInv = cached['codigoInv'] as String?;
    final me = await ProfileService.getMe();
    if (me != null) {
      AppCache.set('perfil', me);
      _codigoInv = me['codigoInv'] as String?;
    }
  }

  Future<void> recargarDisp() async {
    _loading   = true;
    _loadError = false;
    _notify();
    await _loadDispositivos();
    _loading = false;
    _notify();
  }

  Future<void> revocar(String codigo) async {
    _revoking = codigo;
    _notify();
    try {
      await DispositivoService.revocar(codigo);
      _dispositivos =
          _dispositivos.where((d) => d['codigo']?.toString() != codigo).toList();
      AppCache.set('dispositivos', _dispositivos);
    } finally {
      _revoking = null;
      _notify();
    }
  }

  Future<void> copiarCodigo() async {
    if (_codigoInv == null) return;
    await Clipboard.setData(ClipboardData(text: _codigoInv!));
    _copied = true;
    _notify();
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(seconds: 2), () {
      _copied = false;
      _notify();
    });
  }

  // ── Eliminar cuenta ───────────────────────────────────────────────────────

  // Pide al backend el código de 5 caracteres (vence en 5 min). Lanza si falla.
  Future<void> prepararEliminacion() async {
    _deleteConfirmWord = '';
    _deleteTypedWord   = '';
    _loadingDeleteCode = true;
    _notify();
    try {
      _deleteConfirmWord = await ProfileService.getAccountDeleteCode();
    } finally {
      _loadingDeleteCode = false;
      _notify();
    }
  }

  void setDeleteTypedWord(String v) {
    _deleteTypedWord = v;
    _notify();
  }

  // Tras eliminar la cuenta; el router redirige a /login.
  Future<void> cerrarSesion() => auth.logout();

  void cancelarEliminacion() {
    _deleteConfirmWord = '';
    _deleteTypedWord   = '';
    _notify();
  }

  // Devuelve null si se eliminó; si no, el mensaje de error. La sesión se cierra
  // con cerrarSesion() después de cerrar el diálogo.
  Future<String?> confirmarEliminacion() async {
    if (!puedeEliminar) return null;
    _deletingAccount = true;
    _notify();
    try {
      await ProfileService.deleteAccount(_deleteConfirmWord);
      return null;
    } catch (e) {
      final m = _msg(e);
      return m.isEmpty ? 'No se pudo eliminar la cuenta.' : m;
    } finally {
      _deletingAccount = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _copyTimer?.cancel();
    super.dispose();
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/dispositivo_service.dart';
import '../../../services/app_cache.dart';

// Equivalente a src/modules/profile/hooks/useSettings.js en React
// + lógica extra de notificaciones push (nueva funcionalidad móvil)

class UseSettings extends ChangeNotifier {
  List<dynamic> _dispositivos  = [];
  bool          _loading       = true;
  bool          _loadError     = false;
  String?       _codigoInv;
  String?       _revoking;
  bool          _copied        = false;
  bool          _notifEnabled  = false;
  Timer?        _copyTimer;

  List<dynamic> get dispositivos => _dispositivos;
  bool          get loading      => _loading;
  bool          get loadError    => _loadError;
  String?       get codigoInv   => _codigoInv;
  String?       get revoking    => _revoking;
  bool          get copied      => _copied;
  bool          get notifEnabled => _notifEnabled;

  Future<void> load() async {
    _loading   = true;
    _loadError = false;

    // Stale-while-revalidate para dispositivos
    final cached = AppCache.get('dispositivos');
    if (cached != null) {
      _dispositivos = cached as List;
      _loading      = false;
      notifyListeners();
    } else {
      notifyListeners();
    }

    // Cargar en paralelo: dispositivos + perfil (codigoInv) + estado de notificaciones
    await Future.wait([
      _loadDispositivos(),
      _loadMe(),
      _loadNotifStatus(),
    ]);

    _loading = false;
    notifyListeners();
  }

  Future<void> _loadDispositivos() async {
    try {
      final data  = await DispositivoService.getDispositivos();
      AppCache.set('dispositivos', data);
      _dispositivos = data;
    } catch (_) {
      AppCache.markStale('dispositivos');
      if (_dispositivos.isEmpty) _loadError = true;
    }
  }

  Future<void> _loadMe() async {
    try {
      // Stale-while-revalidate para perfil
      final cached = AppCache.get('perfil');
      if (cached != null) {
        _codigoInv = (cached as Map<String, dynamic>)['codigoInv'] as String?;
      }
      final me = await DispositivoService.getMe();
      if (me != null) {
        AppCache.set('perfil', me);
        _codigoInv = me['codigoInv'] as String?;
      }
    } catch (_) {}
  }

  Future<void> _loadNotifStatus() async {
    final status = await Permission.notification.status;
    _notifEnabled = status.isGranted;
  }

  Future<void> recargarDisp() async {
    _loading   = true;
    _loadError = false;
    notifyListeners();
    await _loadDispositivos();
    _loading = false;
    notifyListeners();
  }

  Future<void> revocar(String id) async {
    _revoking = id;
    notifyListeners();
    try {
      await DispositivoService.revocar(id);
      _dispositivos = _dispositivos.where((d) => d['id'].toString() != id).toList();
      AppCache.set('dispositivos', _dispositivos);
    } catch (e) {
      rethrow;
    } finally {
      _revoking = null;
      notifyListeners();
    }
  }

  Future<void> copiarCodigo() async {
    if (_codigoInv == null) return;
    await Clipboard.setData(ClipboardData(text: _codigoInv!));
    _copied = true;
    notifyListeners();
    _copyTimer?.cancel();
    _copyTimer = Timer(const Duration(seconds: 2), () {
      _copied = false;
      notifyListeners();
    });
  }

  // Toggle de notificaciones push
  // Si no tiene permiso: solicita. Si ya tiene: abre ajustes del sistema para revocar.
  Future<bool> toggleNotificaciones(BuildContext context) async {
    if (_notifEnabled) {
      // Ya tiene permiso — solo el sistema puede revocarlo
      await openAppSettings();
      // Refrescar estado tras volver de ajustes
      await _loadNotifStatus();
      notifyListeners();
      return _notifEnabled;
    }

    final status = await Permission.notification.request();
    _notifEnabled = status.isGranted;
    notifyListeners();
    return _notifEnabled;
  }

  @override
  void dispose() {
    _copyTimer?.cancel();
    super.dispose();
  }
}

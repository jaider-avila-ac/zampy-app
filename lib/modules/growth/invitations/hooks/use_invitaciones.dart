import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../services/app_cache.dart';
import '../../../../services/invitacion_service.dart';

// Equivalente a src/modules/growth/invitations/hooks/useInvitaciones.js

const _appBase  = 'https://app.zammpy.com';
const _cacheKey = 'invitaciones';

class UseInvitaciones extends ChangeNotifier {
  Map<String, dynamic>? _estado;
  bool    _loading  = true;
  bool    _toggling = false;
  bool    _copied   = false;
  String  _error    = '';

  Map<String, dynamic>? get estado   => _estado;
  bool                  get loading  => _loading;
  bool                  get toggling => _toggling;
  bool                  get copied   => _copied;
  String                get error    => _error;

  String get enlace {
    final codigo = _estado?['codigoInv'] as String?;
    return codigo != null ? '$_appBase/invite/$codigo' : '';
  }

  Future<void> load() async {
    _error = '';

    // Stale-while-revalidate: mostrar caché inmediatamente
    final cached = AppCache.get(_cacheKey);
    if (cached != null) {
      _estado  = cached as Map<String, dynamic>;
      _loading = false;
      notifyListeners();
    } else {
      _loading = true;
      notifyListeners();
    }

    try {
      final data = await InvitacionService.getEstado();
      AppCache.set(_cacheKey, data);
      _estado = data;
    } catch (e) {
      AppCache.markStale(_cacheKey);
      if (_estado == null) _error = e.toString().replaceFirst('Exception: ', '');
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> copyEnlace() async {
    if (enlace.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: enlace));
    _copied = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    _copied = false;
    notifyListeners();
  }

  Future<void> toggle() async {
    _toggling = true;
    _error    = '';
    notifyListeners();
    try {
      final r = await InvitacionService.toggleActivo();
      _estado = {
        ...(_estado ?? {}),
        'invActivo': r['invActivo'],
      };
      // Actualizar caché con el nuevo estado
      if (_estado != null) AppCache.set(_cacheKey, _estado!);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    }
    _toggling = false;
    notifyListeners();
  }
}

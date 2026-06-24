import 'package:flutter/material.dart';
import '../../../../services/app_cache.dart';
import '../../../../services/logro_service.dart';
import '../models/logro_model.dart';

// Equivalente a src/modules/growth/achievements/hooks/useLogros.js

const _cacheKey = 'logros';

class UseLogros extends ChangeNotifier {
  List<LogroModel> _logros  = [];
  bool             _loading = true;

  List<LogroModel> get logros        => _logros;
  bool             get loading       => _loading;
  List<LogroModel> get desbloqueados => _logros.where((l) =>  l.desbloqueado).toList();
  List<LogroModel> get pendientes    => _logros.where((l) => !l.desbloqueado).toList();

  Future<void> load() async {
    // Stale-while-revalidate: mostrar caché inmediatamente
    final cached = AppCache.get(_cacheKey);
    if (cached != null) {
      _logros  = (cached as List).map((e) => LogroModel.fromJson(e as Map<String, dynamic>)).toList();
      _loading = false;
      notifyListeners();
    } else {
      _loading = true;
      notifyListeners();
    }

    try {
      final raw = await LogroService.miProgreso();
      AppCache.set(_cacheKey, raw);
      _logros = raw.map((e) => LogroModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      AppCache.markStale(_cacheKey);
      _logros = _logros.isEmpty ? [] : _logros; // mantener datos cacheados si los hay
    }
    _loading = false;
    notifyListeners();
  }
}

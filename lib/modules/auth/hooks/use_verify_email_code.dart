import 'dart:async';

import 'package:flutter/material.dart';

import '../../../context/auth_context.dart';
import '../../../services/auth_service.dart';

// Equivalente a src/modules/auth/hooks/useVerifyEmailCode.js en React

class UseVerifyEmailCode extends ChangeNotifier {
  UseVerifyEmailCode(this.email, {bool fresh = false}) {
    for (var i = 0; i < 6; i++) {
      controllers.add(TextEditingController());
      focusNodes.add(FocusNode());
    }
    if (fresh) {
      _cooldown = 300;
      _startTimer();
    }
  }

  final String email;

  final List<TextEditingController> controllers = [];
  final List<FocusNode> focusNodes = [];

  bool _loading = false;
  bool _verified = false;
  String _error = '';
  int _cooldown = 0;
  Timer? _timer;

  bool get loading => _loading;
  bool get verified => _verified;
  String get error => _error;
  int get cooldown => _cooldown;

  String get _code => controllers.map((c) => c.text).join();

  Future<bool> submit(AuthContext auth) async {
    if (_loading) return false;
    final code = _code.trim();
    if (code.length < 6) {
      _error = 'Ingresa los 6 dígitos del código.';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final data = await AuthService.verifyAndRegister(email, code);
      await auth.login(data);
      _verified = true;
      return true;
    } on AuthServiceException catch (e) {
      _error = _mapVerificationError(e.message);
      _clearDigits();
      return false;
    } catch (_) {
      _error = 'Error de conexión. Inténtalo de nuevo.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> resend() async {
    if (_cooldown > 0 || _loading) return;

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      await AuthService.resendVerification(email);
      _cooldown = 300;
      _clearDigits();
      _startTimer();
    } on AuthServiceException catch (e) {
      if (e.message.startsWith('CODE_STILL_VALID:')) {
        final seconds = int.tryParse(e.message.split(':').last) ?? 300;
        _cooldown = seconds;
        _startTimer();
        _error = 'Tu código aún está vigente. Revisa tu correo o spam.';
      } else if (e.message == 'PENDING_NOT_FOUND') {
        _error = 'El registro expiró. Vuelve a registrarte.';
      } else {
        _error = e.message.isEmpty
            ? 'No se pudo reenviar el código.'
            : e.message;
      }
    } catch (_) {
      _error = 'No se pudo reenviar el código.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _mapVerificationError(String message) {
    if (message.contains('CODE_EXPIRED')) {
      return 'El código expiró. Reenvía uno nuevo.';
    }
    if (message.contains('CODE_INVALID')) {
      return 'Código incorrecto. Revisa tu correo.';
    }
    if (message.contains('PENDING_NOT_FOUND')) {
      return 'El registro expiró. Vuelve a registrarte.';
    }
    return message.isEmpty ? 'Error al verificar. Intenta de nuevo.' : message;
  }

  void _clearDigits() {
    for (final c in controllers) {
      c.clear();
    }
    if (focusNodes.isNotEmpty) focusNodes.first.requestFocus();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown <= 0) {
        timer.cancel();
      } else {
        _cooldown--;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in controllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.dispose();
  }
}

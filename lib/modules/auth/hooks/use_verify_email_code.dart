import 'dart:async';
import 'package:flutter/material.dart';
import '../../../context/auth_context.dart';
import '../../../services/auth_service.dart';

// Equivalente a src/modules/auth/hooks/useVerifyEmailCode.js en React

class UseVerifyEmailCode extends ChangeNotifier {
  UseVerifyEmailCode(this.email) {
    for (var i = 0; i < 6; i++) {
      controllers.add(TextEditingController());
      focusNodes.add(FocusNode());
    }
  }

  final String email;

  final List<TextEditingController> controllers = [];
  final List<FocusNode>             focusNodes  = [];

  bool   _loading   = false;
  bool   _verified  = false;
  String _error     = '';
  int    _cooldown  = 0;
  Timer? _timer;

  bool   get loading  => _loading;
  bool   get verified => _verified;
  String get error    => _error;
  int    get cooldown => _cooldown;

  String get _code => controllers.map((c) => c.text).join();

  Future<bool> submit(AuthContext auth) async {
    final code = _code.trim();
    if (code.length < 6) {
      _error = 'Ingresa el código de 6 dígitos.';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error   = '';
    notifyListeners();

    try {
      final data = await AuthService.verifyAndRegister(email, code);
      await auth.login(data);
      _verified = true;
      return true;
    } on AuthServiceException catch (e) {
      _error = e.message;
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
    if (_cooldown > 0) return;

    _loading = true;
    _error   = '';
    notifyListeners();

    try {
      await AuthService.resendVerification(email);
      _startCooldown(60);
    } on AuthServiceException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'No se pudo reenviar el código.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _startCooldown(int seconds) {
    _cooldown = seconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown <= 0) {
        t.cancel();
      } else {
        _cooldown--;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in controllers) { c.dispose(); }
    for (final f in focusNodes)  { f.dispose(); }
    super.dispose();
  }
}

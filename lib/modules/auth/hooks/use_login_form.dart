import 'package:flutter/material.dart';
import '../../../context/auth_context.dart';
import '../../../services/auth_service.dart';

// Equivalente a src/modules/auth/hooks/useLoginForm.js en React

class UseLoginForm extends ChangeNotifier {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  bool _loading = false;
  String _error = '';
  bool _showPass = false;

  bool get loading => _loading;
  String get error => _error;
  bool get showPass => _showPass;

  void toggleShowPass() {
    _showPass = !_showPass;
    notifyListeners();
  }

  Future<bool> submit(AuthContext auth) async {
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _error = 'Por favor completa todos los campos.';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      final data = await AuthService.loginUser(email, password);
      await auth.login(data);
      return true;
    } on AuthServiceException catch (e) {
      if (e.status == 429) {
        _error = e.message.isEmpty
            ? 'Demasiados intentos fallidos. Espera unos minutos e intenta de nuevo.'
            : e.message;
      } else if (e.status != null) {
        _error = e.message.isEmpty
            ? 'Correo o contraseña incorrectos.'
            : e.message;
      } else {
        _error = 'Error de conexión. Intenta de nuevo.';
      }
      return false;
    } catch (_) {
      _error = 'Error de conexión. Intenta de nuevo.';
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }
}

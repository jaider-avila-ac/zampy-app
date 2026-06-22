import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

// Equivalente a src/modules/auth/hooks/useForgotPassword.js en React

enum ForgotPasswordState { form, sent, googleAccount }

class UseForgotPassword extends ChangeNotifier {
  final emailCtrl = TextEditingController();

  bool                 _loading = false;
  String               _error   = '';
  ForgotPasswordState  _state   = ForgotPasswordState.form;

  bool                get loading => _loading;
  String              get error   => _error;
  ForgotPasswordState get state   => _state;

  Future<void> submit() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty) {
      _error = 'Ingresa tu correo electrónico.';
      notifyListeners();
      return;
    }

    _loading = true;
    _error   = '';
    notifyListeners();

    try {
      await AuthService.forgotPassword(email);
      _state = ForgotPasswordState.sent;
    } on AuthServiceException catch (e) {
      // Si el backend indica cuenta de Google, mostramos estado especial
      if (e.message.toLowerCase().contains('google') ||
          (e.code != null && e.code!.toLowerCase().contains('google'))) {
        _state = ForgotPasswordState.googleAccount;
      } else {
        _error = e.message;
      }
    } catch (_) {
      _error = 'Error de conexión. Inténtalo de nuevo.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void goToReset() {
    _state = ForgotPasswordState.form;
    notifyListeners();
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }
}

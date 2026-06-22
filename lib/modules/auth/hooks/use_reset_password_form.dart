import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

// Equivalente a src/modules/auth/hooks/useResetPasswordForm.js en React

class UseResetPasswordForm extends ChangeNotifier {
  final List<TextEditingController> codeControllers = [];
  final List<FocusNode>             codeFocusNodes  = [];
  final passwordCtrl  = TextEditingController();
  final confirmCtrl   = TextEditingController();

  bool   _loading      = false;
  bool   _done         = false;
  String _error        = '';
  bool   _showPass     = false;
  bool   _showConfirm  = false;

  bool   get loading     => _loading;
  bool   get done        => _done;
  String get error       => _error;
  bool   get showPass    => _showPass;
  bool   get showConfirm => _showConfirm;

  UseResetPasswordForm() {
    for (var i = 0; i < 6; i++) {
      codeControllers.add(TextEditingController());
      codeFocusNodes.add(FocusNode());
    }
  }

  void toggleShowPass() {
    _showPass = !_showPass;
    notifyListeners();
  }

  void toggleShowConfirm() {
    _showConfirm = !_showConfirm;
    notifyListeners();
  }

  String get _code => codeControllers.map((c) => c.text).join();

  Future<bool> submit() async {
    final code     = _code.trim();
    final password = passwordCtrl.text;
    final confirm  = confirmCtrl.text;

    if (code.length < 6) {
      _error = 'Ingresa el código de 6 dígitos.';
      notifyListeners();
      return false;
    }
    if (password.length < 8) {
      _error = 'La contraseña debe tener al menos 8 caracteres.';
      notifyListeners();
      return false;
    }
    if (password != confirm) {
      _error = 'Las contraseñas no coinciden.';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error   = '';
    notifyListeners();

    try {
      await AuthService.resetPassword(code, password);
      _done = true;
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

  @override
  void dispose() {
    for (final c in codeControllers) { c.dispose(); }
    for (final f in codeFocusNodes)  { f.dispose(); }
    passwordCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }
}

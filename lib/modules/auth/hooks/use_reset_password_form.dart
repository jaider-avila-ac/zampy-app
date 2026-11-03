import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

// Equivalente a src/modules/auth/hooks/useResetPasswordForm.js en React

class UseResetPasswordForm extends ChangeNotifier {
  final List<TextEditingController> codeControllers = [];
  final List<FocusNode> codeFocusNodes = [];
  final passwordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _done = false;
  String _error = '';
  bool _showPass = false;
  bool _showConfirm = false;
  // 0 = ingresar código · 1 = nueva contraseña. No se puede pasar a la contraseña
  // sin haber ingresado antes el código completo.
  int _step = 0;

  bool get loading => _loading;
  bool get done => _done;
  String get error => _error;
  bool get showPass => _showPass;
  bool get showConfirm => _showConfirm;
  int get step => _step;

  /// Paso 1 → 2: el backend verifica el código; solo si es válido se pide la nueva contraseña.
  Future<void> continuarAContrasena() async {
    final code = _code.trim();
    if (code.length < 6) {
      _error = 'Ingresa el código de 6 dígitos.';
      notifyListeners();
      return;
    }
    _loading = true;
    _error = '';
    notifyListeners();
    try {
      await AuthService.verifyResetCode(code);
      _step = 1;
    } on AuthServiceException catch (e) {
      final msg = e.message;
      if (msg.contains('CODE_EXPIRED') || msg.contains('EXPIRED')) {
        _error = 'El código expiró. Vuelve a solicitar uno nuevo.';
      } else if (msg.contains('CODE_INVALID') || msg.contains('INVALID')) {
        _error = 'Código incorrecto. Revisa tu correo.';
      } else {
        _error = msg.isEmpty ? 'No se pudo verificar el código.' : msg;
      }
    } catch (_) {
      _error = 'Error de conexión. Inténtalo de nuevo.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void volverACodigo() {
    _error = '';
    _step = 0;
    notifyListeners();
  }

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
    final code = _code.trim();
    final password = passwordCtrl.text;
    final confirm = confirmCtrl.text;

    if (code.length < 6) {
      _error = 'Ingresa el código de 6 dígitos.';
      notifyListeners();
      return false;
    }
    if (password.length < 6) {
      _error = 'La contraseña debe tener al menos 6 caracteres.';
      notifyListeners();
      return false;
    }
    if (password != confirm) {
      _error = 'Las contraseñas no coinciden.';
      notifyListeners();
      return false;
    }

    _loading = true;
    _error = '';
    notifyListeners();

    try {
      await AuthService.resetPassword(code, password);
      _done = true;
      return true;
    } on AuthServiceException catch (e) {
      final msg = e.message;
      if (msg.contains('CODE_EXPIRED') || msg.contains('EXPIRED')) {
        _error = 'El código expiró. Vuelve a solicitar uno nuevo.';
      } else if (msg.contains('CODE_INVALID') || msg.contains('INVALID')) {
        _error = 'Código incorrecto. Revisa tu correo.';
      } else {
        _error = msg.isEmpty ? 'No se pudo cambiar la contraseña.' : msg;
      }
      // el código resultó inválido: se vuelve al paso del código
      for (final c in codeControllers) {
        c.clear();
      }
      _step = 0;
      if (codeFocusNodes.isNotEmpty) codeFocusNodes.first.requestFocus();
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
    for (final c in codeControllers) {
      c.dispose();
    }
    for (final f in codeFocusNodes) {
      f.dispose();
    }
    passwordCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }
}

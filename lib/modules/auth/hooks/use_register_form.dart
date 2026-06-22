import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

// Equivalente a src/modules/auth/hooks/useRegisterForm.js en React

class UseRegisterForm extends ChangeNotifier {
  final nombreCtrl   = TextEditingController();
  final apellidoCtrl = TextEditingController();
  final emailCtrl    = TextEditingController();
  final passwordCtrl = TextEditingController();

  bool   _loading  = false;
  String _error    = '';
  bool   _showPass = false;

  bool   get loading  => _loading;
  String get error    => _error;
  bool   get showPass => _showPass;

  void toggleShowPass() {
    _showPass = !_showPass;
    notifyListeners();
  }

  // Retorna el email registrado si fue exitoso (para navegar a verify)
  Future<String?> submit({String? invRef}) async {
    final nombre   = nombreCtrl.text.trim();
    final apellido = apellidoCtrl.text.trim();
    final email    = emailCtrl.text.trim();
    final password = passwordCtrl.text;

    if (nombre.isEmpty || apellido.isEmpty || email.isEmpty || password.isEmpty) {
      _error = 'Por favor completa todos los campos.';
      notifyListeners();
      return null;
    }
    if (password.length < 8) {
      _error = 'La contraseña debe tener al menos 8 caracteres.';
      notifyListeners();
      return null;
    }

    _loading = true;
    _error   = '';
    notifyListeners();

    try {
      await AuthService.preRegister(
        nombre: nombre, apellido: apellido,
        email: email, password: password,
        invRef: invRef,
      );
      return email;
    } on AuthServiceException catch (e) {
      _error = e.message;
      return null;
    } catch (_) {
      _error = 'Error de conexión. Inténtalo de nuevo.';
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    apellidoCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }
}

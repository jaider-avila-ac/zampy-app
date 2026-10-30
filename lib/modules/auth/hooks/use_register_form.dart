import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../../services/invite_store.dart';
import '../../../shared/location_cascade_input.dart';

// Equivalente a src/modules/auth/hooks/useRegisterForm.js en React

class UseRegisterForm extends ChangeNotifier {
  final nombreCtrl = TextEditingController();
  final apellidoCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  LocationCascadeValue _ubicacion = const LocationCascadeValue(
    paisCodigo: 'CO',
  );
  String _telefono = '';
  bool _loading = false;
  bool _codePending = false;
  String _error = '';
  bool _showPass = false;

  bool get loading => _loading;
  bool get codePending => _codePending;
  String get error => _error;
  bool get showPass => _showPass;
  LocationCascadeValue get ubicacion => _ubicacion;
  String get telefono => _telefono;

  void toggleShowPass() {
    _showPass = !_showPass;
    notifyListeners();
  }

  void setUbicacion(LocationCascadeValue value) {
    _ubicacion = value;
    notifyListeners();
  }

  void setTelefono(String value) {
    _telefono = value;
    notifyListeners();
  }

  Future<String?> submit() async {
    final nombre = nombreCtrl.text.trim();
    final apellido = apellidoCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text;

    if (nombre.isEmpty || email.isEmpty || password.isEmpty) {
      _error = 'Por favor completa todos los campos.';
      notifyListeners();
      return null;
    }
    if (password.length < 6) {
      _error = 'La contraseña debe tener al menos 6 caracteres.';
      notifyListeners();
      return null;
    }
    if (!_ubicacion.hasMunicipio) {
      _error = 'Elige tu municipio de la lista.';
      notifyListeners();
      return null;
    }

    _loading = true;
    _codePending = false;
    _error = '';
    notifyListeners();

    try {
      final invRef = await InviteStore.read();
      await AuthService.preRegister(
        nombre: nombre,
        apellido: apellido,
        email: email,
        password: password,
        municipioCodigo: _ubicacion.municipioCodigo!,
        telefono: _telefono,
        invRef: invRef,
      );
      await InviteStore.clear();
      return email;
    } on AuthServiceException catch (e) {
      if (e.message == 'CODE_PENDING') {
        _codePending = true;
        return email;
      }
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

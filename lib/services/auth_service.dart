import 'api_client.dart';

class AuthServiceException implements Exception {
  final String message;
  final int? status;
  final String? code;

  const AuthServiceException(this.message, {this.status, this.code});

  @override
  String toString() => message;
}

class AuthService {
  AuthService._();

  // POST /api/v1/auth/login
  static Future<Map<String, dynamic>> loginUser(
    String email,
    String password,
  ) async {
    final data = await _call(
      () => ApiClient.instance.post(
        '/api/v1/auth/login',
        body: {'email': email.trim(), 'password': password},
        auth: false,
      ),
      fallback: 'Correo o contraseña incorrectos.',
    );
    return _asMap(data);
  }

  // POST /api/v1/auth/pre-register
  static Future<void> preRegister({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    required String municipioCodigo,
    String? telefono,
    String? invRef,
  }) async {
    final body = <String, dynamic>{
      'nombre': nombre,
      'apellido': apellido,
      'email': email.trim(),
      'password': password,
      'municipioCodigo': municipioCodigo,
    };
    if (telefono != null && telefono.trim().isNotEmpty) {
      body['telefono'] = telefono.trim();
    }
    if (invRef != null && invRef.trim().isNotEmpty) {
      body['invRef'] = invRef.trim();
    }

    await _call(
      () => ApiClient.instance.post(
        '/api/v1/auth/pre-register',
        body: body,
        auth: false,
      ),
      fallback: 'No se pudo completar el registro.',
    );
  }

  // POST /api/v1/auth/register — verifica código y activa cuenta
  static Future<Map<String, dynamic>> verifyAndRegister(
    String email,
    String code,
  ) async {
    final data = await _call(
      () => ApiClient.instance.post(
        '/api/v1/auth/register',
        body: {'email': email.trim(), 'code': code.trim()},
        auth: false,
      ),
      fallback: 'Código incorrecto.',
    );
    return _asMap(data);
  }

  // POST /api/v1/auth/forgot-password
  static Future<void> forgotPassword(String email) async {
    await _call(
      () => ApiClient.instance.post(
        '/api/v1/auth/forgot-password',
        body: {'email': email.trim()},
        auth: false,
      ),
      fallback: 'Error de conexión.',
    );
  }

  // POST /api/v1/auth/resend-verification
  static Future<void> resendVerification(String email) async {
    await _call(
      () => ApiClient.instance.post(
        '/api/v1/auth/resend-verification',
        body: {'email': email.trim()},
        auth: false,
      ),
      fallback: 'No se pudo reenviar el código.',
    );
  }

  // POST /api/v1/auth/reset-password
  static Future<void> resetPassword(String token, String password) async {
    await _call(
      () => ApiClient.instance.post(
        '/api/v1/auth/reset-password',
        body: {'token': token, 'password': password},
        auth: false,
      ),
      fallback: 'No se pudo cambiar la contraseña.',
    );
  }

  // POST /api/v1/auth/refresh — rota el refreshToken en cada uso
  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final data = await _call(
      () => ApiClient.instance.post(
        '/api/v1/auth/refresh',
        body: {'refreshToken': refreshToken},
        auth: false,
      ),
      fallback: 'TOKEN_EXPIRED',
    );
    return _asMap(data);
  }

  // POST /api/v1/auth/google/token — login móvil con idToken de Google
  static Future<Map<String, dynamic>> loginWithGoogleToken(
    String idToken,
  ) async {
    final data = await _call(
      () => ApiClient.instance.post(
        '/api/v1/auth/google/token',
        body: {'idToken': idToken},
        auth: false,
      ),
      fallback: 'Error con Google.',
    );
    return _asMap(data);
  }

  static Future<dynamic> _call(
    Future<dynamic> Function() request, {
    required String fallback,
  }) async {
    try {
      return await request();
    } on ApiException catch (e) {
      throw AuthServiceException(
        e.message.isEmpty ? fallback : e.message,
        status: e.status,
        code: e.code,
      );
    } catch (_) {
      throw AuthServiceException(fallback);
    }
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }
}

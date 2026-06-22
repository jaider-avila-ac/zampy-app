import 'package:google_sign_in/google_sign_in.dart';
import '../context/auth_context.dart';
import 'auth_service.dart';

// Selector nativo de cuentas Google → idToken → backend /api/v1/auth/google/token

// El serverClientId es el mismo GOOGLE_CLIENT_ID que usa el backend Spring Boot
const _kServerClientId =
    '354623240504-8vulj2rf7j1pa4q8tu2f021nctsuovi8.apps.googleusercontent.com';

final _googleSignIn = GoogleSignIn(serverClientId: _kServerClientId);

class GoogleAuthService {
  GoogleAuthService._();

  /// Abre el selector nativo de cuentas Android y hace login en el backend.
  /// Retorna `true` si el login fue exitoso.
  static Future<bool> signIn(AuthContext auth) async {
    // Forzar selector de cuenta (no auto-seleccionar la última usada)
    await _googleSignIn.signOut();

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return false; // usuario canceló

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw AuthServiceException(
          'No se pudo obtener el token de Google. Intenta de nuevo.');
    }

    final data = await AuthService.loginWithGoogleToken(idToken);
    await auth.login(data);
    return true;
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}

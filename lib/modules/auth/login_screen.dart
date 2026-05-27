import 'package:flutter/material.dart';
import '_auth_widgets.dart';
import 'auth_service.dart';
import 'google_auth_webview.dart';
import 'register_screen.dart';
import '../explore/explore_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.registered = false});
  final bool registered;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl   = TextEditingController();
  bool    _showPwd = false;
  bool    _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pwd   = _pwdCtrl.text;
    if (email.isEmpty || pwd.isEmpty) return;

    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.login(email, pwd);
      if (!mounted) return;
      _goHome();
    } on String catch (msg) {
      setState(() => _error = msg);
    } catch (e) {
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginGoogle() async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => const GoogleAuthWebView(authUrl: kGoogleAuthUrl),
      ),
    );
    if (!mounted) return;
    if (result != null) {
      await AuthService.saveOAuthSession(result);
      _goHome();
    } else {
      setState(() => _error = 'No se pudo iniciar sesión con Google.');
    }
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ExploreScreen()),
    );
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('connection refused') ||
        msg.contains('failed host lookup') ||
        msg.contains('network')) {
      return 'No se pudo conectar al servidor. Verifica que el backend esté corriendo.';
    }
    if (msg.contains('timeout')) {
      return 'La conexión tardó demasiado. Intenta de nuevo.';
    }
    return 'Error: $e';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
            child: AuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ZampyAuthLogo(),
                  const SizedBox(height: 24),

                  const Text('Bienvenido',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('Inicia sesión en tu cuenta.',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.60),
                          fontSize: 13)),
                  const SizedBox(height: 22),

                  if (widget.registered) ...[
                    const MessageBanner(
                        message: 'Cuenta creada. Ya puedes iniciar sesión.',
                        isError: false),
                    const SizedBox(height: 14),
                  ],
                  if (_error != null) ...[
                    MessageBanner(message: _error!, isError: true),
                    const SizedBox(height: 14),
                  ],

                  AuthField(
                    controller: _emailCtrl,
                    hint: 'Correo electrónico',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 10),
                  AuthField(
                    controller: _pwdCtrl,
                    hint: 'Contraseña',
                    obscure: !_showPwd,
                    textInputAction: TextInputAction.done,
                    onSubmitted: _login,
                    suffix: IconButton(
                      icon: Icon(
                        _showPwd ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _showPwd = !_showPwd),
                    ),
                  ),
                  const SizedBox(height: 18),

                  PrimaryAuthButton(
                      label: 'Iniciar sesión',
                      loading: _loading,
                      onPressed: _login),
                  const SizedBox(height: 16),

                  const OrDivider(),
                  const SizedBox(height: 16),

                  GoogleAuthButton(
                      label: 'Continuar con Google',
                      onPressed: _loginGoogle),
                  const SizedBox(height: 10),

                  OutlineAuthButton(
                    label: 'Registrarse manualmente',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()),
                    ),
                  ),
                  const SizedBox(height: 18),

                  Center(
                    child: Text(
                      'Tu perfil se crea automáticamente al usar Google.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

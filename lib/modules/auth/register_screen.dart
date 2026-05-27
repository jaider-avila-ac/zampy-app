import 'package:flutter/material.dart';
import '_auth_widgets.dart';
import 'auth_service.dart';
import 'google_auth_webview.dart';
import 'login_screen.dart';
import '../explore/explore_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreCtrl   = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _pwdCtrl      = TextEditingController();
  bool    _showPwd = false;
  bool    _loading = false;
  String? _error;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final nombre   = _nombreCtrl.text.trim();
    final apellido = _apellidoCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final pwd      = _pwdCtrl.text;

    if (nombre.isEmpty || email.isEmpty || pwd.isEmpty) return;
    if (pwd.length < 6) {
      setState(() => _error = 'La contraseña debe tener al menos 6 caracteres.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.register(
          nombre: nombre, apellido: apellido, email: email, password: pwd);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen(registered: true)),
      );
    } on String catch (msg) {
      setState(() => _error = msg);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('connection refused') || msg.contains('failed host lookup')) {
        setState(() => _error = 'No se pudo conectar al servidor.');
      } else if (msg.contains('timeout')) {
        setState(() => _error = 'La conexión tardó demasiado. Intenta de nuevo.');
      } else {
        setState(() => _error = 'Error: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _registerGoogle() async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
          builder: (_) => const GoogleAuthWebView(authUrl: kGoogleAuthUrl)),
    );
    if (!mounted) return;
    if (result != null) {
      await AuthService.saveOAuthSession(result);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ExploreScreen()),
      );
    } else {
      setState(() => _error = 'No se pudo registrar con Google.');
    }
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

                  const Text('Crea tu cuenta',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text('Llena tus datos para comenzar.',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.60),
                          fontSize: 13)),
                  const SizedBox(height: 16),

                  // Banner modo prueba
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF78350F),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFFBBF24).withValues(alpha: 0.40)),
                    ),
                    child: const Text(
                      'Modo prueba — no se requiere verificación de correo.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Color(0xFFFDE68A), fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_error != null) ...[
                    MessageBanner(message: _error!, isError: true),
                    const SizedBox(height: 14),
                  ],

                  // Nombre + Apellido
                  Row(
                    children: [
                      Expanded(
                        child: AuthField(
                          controller: _nombreCtrl,
                          hint: 'Nombre',
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AuthField(
                          controller: _apellidoCtrl,
                          hint: 'Apellido',
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  AuthField(
                    controller: _emailCtrl,
                    hint: 'Correo electrónico',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 10),

                  AuthField(
                    controller: _pwdCtrl,
                    hint: 'Contraseña (mín. 6 caracteres)',
                    obscure: !_showPwd,
                    textInputAction: TextInputAction.done,
                    onSubmitted: _register,
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
                      label: 'Crear cuenta',
                      loading: _loading,
                      onPressed: _register),
                  const SizedBox(height: 16),

                  const OrDivider(),
                  const SizedBox(height: 16),

                  GoogleAuthButton(
                      label: 'Registrarse con Google',
                      onPressed: _registerGoogle),
                  const SizedBox(height: 20),

                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 13),
                          children: const [
                            TextSpan(text: '¿Ya tienes cuenta? '),
                            TextSpan(
                              text: 'Iniciar sesión',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
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

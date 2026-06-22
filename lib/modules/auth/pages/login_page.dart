import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../context/auth_context.dart';
import '../../../services/google_auth_service.dart';
import '../../../shared/app_colors.dart';
import '../components/google_icon.dart';
import '../hooks/use_login_form.dart';

// Equivalente al panel derecho (mobile) de AuthLayout + LoginPage.jsx en React
// Fondo totalmente blanco — sin panel azul izquierdo (ese es solo desktop en React)

class LoginPage extends StatefulWidget {
  // query params opcionales para alertas (mismo que React: ?registered=true, ?verified=true, etc.)
  final bool registered;
  final bool verified;
  final String? oauthError;

  const LoginPage({
    super.key,
    this.registered = false,
    this.verified   = false,
    this.oauthError,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final UseLoginForm _form;

  @override
  void initState() {
    super.initState();
    _form = UseLoginForm();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _form,
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    final form = context.watch<UseLoginForm>();
    final auth = context.watch<AuthContext>();
    final page = context.findAncestorWidgetOfExactType<LoginPage>();
    final registered = page?.registered ?? false;
    final verified   = page?.verified   ?? false;
    final oauthError = page?.oauthError;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo — mismo que la versión mobile de React (imagotipo indigo)
              Center(
                child: SvgPicture.asset(
                  'assets/logos/imagotipo-indigo-zammpy.svg',
                  height: 36,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF4A37F2), BlendMode.srcIn),
                ),
              ),
              const SizedBox(height: 36),

              // Título
              const Text(
                'Bienvenido',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.kTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Inicia sesión en tu cuenta',
                style: TextStyle(fontSize: 14, color: AppColors.kTextSecondary),
              ),
              const SizedBox(height: 20),

              // Alertas
              if (registered)
                _Alert(
                  color: const Color(0xFFDCFCE7),
                  textColor: const Color(0xFF166534),
                  text: '¡Cuenta creada! Revisa tu correo para verificarla.',
                ),
              if (verified)
                _Alert(
                  color: const Color(0xFFDCFCE7),
                  textColor: const Color(0xFF166534),
                  text: '¡Correo verificado! Ya puedes iniciar sesión.',
                ),
              if (oauthError != null)
                _Alert(
                  color: const Color(0xFFFEE2E2),
                  textColor: const Color(0xFF991B1B),
                  text: oauthError,
                ),
              if (form.error.isNotEmpty)
                _Alert(
                  color: const Color(0xFFFEE2E2),
                  textColor: const Color(0xFF991B1B),
                  text: form.error,
                ),

              // Email
              _UnderlineField(
                controller: form.emailCtrl,
                label: 'Correo electrónico',
                hint: 'tu@correo.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),

              // Contraseña
              _UnderlineField(
                controller: form.passwordCtrl,
                label: 'Contraseña',
                hint: '••••••••',
                obscure: !form.showPass,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(context, form, auth),
                suffix: GestureDetector(
                  onTap: form.toggleShowPass,
                  child: Icon(
                    form.showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 18,
                    color: AppColors.kTextMuted,
                  ),
                ),
              ),

              // Olvidé mi contraseña
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/auth/forgot-password'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.kBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Botón iniciar sesión
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.kBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: form.loading ? null : () => _submit(context, form, auth),
                  child: form.loading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Iniciar sesión',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),

              // Divisor "o"
              const _Divider(),
              const SizedBox(height: 20),

              // Botón Google
              _GoogleButton(loading: form.loading),
              const SizedBox(height: 28),

              // Crear cuenta
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('¿No tienes una cuenta?',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.kTextSecondary)),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.only(left: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('Crear una cuenta',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.kBlue,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(
      BuildContext context, UseLoginForm form, AuthContext auth) async {
    final ok = await form.submit(auth);
    if (ok && context.mounted) {
      context.go('/');
    }
  }
}

// ── Campo con sólo borde inferior (estilo React) ──────────────────────────────
class _UnderlineField extends StatelessWidget {
  const _UnderlineField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscure          = false,
    this.keyboardType     = TextInputType.text,
    this.textInputAction  = TextInputAction.next,
    this.onSubmitted,
    this.suffix,
  });

  final TextEditingController controller;
  final String                label;
  final String                hint;
  final bool                  obscure;
  final TextInputType          keyboardType;
  final TextInputAction        textInputAction;
  final ValueChanged<String>?  onSubmitted;
  final Widget?               suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.kTextSecondary,
                letterSpacing: 0.3)),
        const SizedBox(height: 6),
        TextField(
          controller:       controller,
          obscureText:      obscure,
          keyboardType:     keyboardType,
          textInputAction:  textInputAction,
          onSubmitted:      onSubmitted,
          style: const TextStyle(fontSize: 15, color: AppColors.kTextPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.kTextMuted, fontSize: 14),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: suffix)
                : null,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 32, minHeight: 32),
            border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFCBD5E1))),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.kBlue, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

// ── Alerta de color ───────────────────────────────────────────────────────────
class _Alert extends StatelessWidget {
  const _Alert({
    required this.color,
    required this.textColor,
    required this.text,
  });
  final Color  color;
  final Color  textColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 13, color: textColor)),
    );
  }
}

// ── Divisor "o" ───────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('o',
            style: TextStyle(fontSize: 13, color: AppColors.kTextMuted)),
      ),
      const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
    ]);
  }
}

// ── Botón de Google ───────────────────────────────────────────────────────────
class _GoogleButton extends StatefulWidget {
  const _GoogleButton({required this.loading});
  final bool loading;

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.loading || _busy;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.kTextPrimary,
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
        onPressed: isDisabled ? null : _signIn,
        child: _busy
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GoogleIcon(size: 18),
                  SizedBox(width: 10),
                  Text('Continuar con Google',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() => _busy = true);
    try {
      final auth = context.read<AuthContext>();
      final ok = await GoogleAuthService.signIn(auth);
      if (ok && mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

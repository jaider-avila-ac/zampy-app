import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/app_colors.dart';
import '../hooks/use_forgot_password.dart';

// Equivalente a src/modules/auth/pages/ForgotPasswordPage.jsx en React
// Fondo indigo, tarjeta blanca al centro

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  late final UseForgotPassword _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = UseForgotPassword();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _ctrl,
      child: const _ForgotView(),
    );
  }
}

class _ForgotView extends StatelessWidget {
  const _ForgotView();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<UseForgotPassword>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // Logo blanco
                SvgPicture.asset(
                  'assets/logos/imagotipo-blanco-zammpy.svg',
                  height: 32,
                  colorFilter: const ColorFilter.mode(
                      Colors.white, BlendMode.srcIn),
                ),
                const SizedBox(height: 32),

                // Tarjeta blanca
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _buildContent(context, ctrl),
                ),

                const SizedBox(height: 20),
                // Volver al login
                TextButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.arrow_back, size: 15,
                      color: Colors.white),
                  label: const Text('Volver al inicio de sesión',
                      style: TextStyle(fontSize: 14, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, UseForgotPassword ctrl) {
    switch (ctrl.state) {
      case ForgotPasswordState.sent:
        return _SentState(
            email: ctrl.emailCtrl.text,
            onGoReset: () {
              ctrl.goToReset();
              context.go('/auth/reset-password');
            });

      case ForgotPasswordState.googleAccount:
        return _GoogleAccountState();

      case ForgotPasswordState.form:
        return _FormState(ctrl: ctrl);
    }
  }
}

class _FormState extends StatelessWidget {
  const _FormState({required this.ctrl});
  final UseForgotPassword ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recuperar contraseña',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.kTextPrimary)),
        const SizedBox(height: 8),
        Text(
          'Ingresa tu correo y te enviaremos un código para restablecer tu contraseña.',
          style: TextStyle(fontSize: 14, color: AppColors.kTextSecondary),
        ),
        const SizedBox(height: 24),

        if (ctrl.error.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(ctrl.error,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF991B1B))),
          ),

        // Label
        const Text('Correo electrónico',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.kTextSecondary,
                letterSpacing: 0.3)),
        const SizedBox(height: 6),
        TextField(
          controller:      ctrl.emailCtrl,
          keyboardType:    TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted:     (_) => ctrl.submit(),
          style: const TextStyle(
              fontSize: 15, color: AppColors.kTextPrimary),
          decoration: InputDecoration(
            hintText: 'tu@correo.com',
            hintStyle:
                TextStyle(color: AppColors.kTextMuted, fontSize: 14),
            border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFCBD5E1))),
            focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppColors.kBlue, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            isDense: true,
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.kBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: ctrl.loading ? null : () => ctrl.submit(),
            child: ctrl.loading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Enviar código',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _SentState extends StatelessWidget {
  const _SentState({required this.email, required this.onGoReset});
  final String        email;
  final VoidCallback  onGoReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.mark_email_read_outlined,
            size: 56, color: Color(0xFF4F46E5)),
        const SizedBox(height: 16),
        const Text('¡Código enviado!',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.kTextPrimary)),
        const SizedBox(height: 8),
        Text(
          'Revisa tu bandeja de entrada en\n$email',
          textAlign: TextAlign.center,
          style:
              TextStyle(fontSize: 14, color: AppColors.kTextSecondary),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.kBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: onGoReset,
            child: const Text('Ingresar código',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _GoogleAccountState extends StatelessWidget {
  const _GoogleAccountState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.g_mobiledata, size: 56, color: Color(0xFF4285F4)),
        const SizedBox(height: 16),
        const Text('Cuenta de Google',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.kTextPrimary)),
        const SizedBox(height: 8),
        Text(
          'Esta cuenta fue creada con Google. Usa el botón "Continuar con Google" para iniciar sesión.',
          textAlign: TextAlign.center,
          style:
              TextStyle(fontSize: 14, color: AppColors.kTextSecondary),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.kBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => context.go('/login'),
            child: const Text('Volver al inicio',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

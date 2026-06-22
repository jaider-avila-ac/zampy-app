import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../context/auth_context.dart';
import '../../../shared/app_colors.dart';
import '../hooks/use_verify_email_code.dart';

// Equivalente a src/modules/auth/pages/VerifyEmailCodePage.jsx en React
// Fondo indigo, tarjeta translúcida, 6 cajas de dígito

class VerifyEmailCodePage extends StatefulWidget {
  final String email;
  const VerifyEmailCodePage({super.key, required this.email});

  @override
  State<VerifyEmailCodePage> createState() => _VerifyEmailCodePageState();
}

class _VerifyEmailCodePageState extends State<VerifyEmailCodePage> {
  late final UseVerifyEmailCode _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = UseVerifyEmailCode(widget.email);
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
      child: _VerifyView(email: widget.email),
    );
  }
}

class _VerifyView extends StatelessWidget {
  const _VerifyView({required this.email});
  final String email;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<UseVerifyEmailCode>();
    final auth = context.watch<AuthContext>();

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

                // Tarjeta
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3), width: 1),
                  ),
                  child: ctrl.verified
                      ? _SuccessState(onContinue: () => context.go('/'))
                      : _FormState(ctrl: ctrl, email: email, auth: auth),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormState extends StatelessWidget {
  const _FormState({
    required this.ctrl,
    required this.email,
    required this.auth,
  });
  final UseVerifyEmailCode ctrl;
  final String              email;
  final AuthContext          auth;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.mark_email_read_outlined,
            size: 48, color: Colors.white),
        const SizedBox(height: 16),
        const Text('Verifica tu correo',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 8),
        Text(
          'Enviamos un código de 6 dígitos a\n$email',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14, color: Colors.white.withValues(alpha: 0.85)),
        ),
        const SizedBox(height: 28),

        if (ctrl.error.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(ctrl.error,
                style: const TextStyle(fontSize: 13, color: Colors.white)),
          ),

        // 6 cajas de dígito
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _DigitBox(
            controller: ctrl.controllers[i],
            focusNode:  ctrl.focusNodes[i],
            nextFocus:  i < 5 ? ctrl.focusNodes[i + 1] : null,
            prevFocus:  i > 0 ? ctrl.focusNodes[i - 1] : null,
            onFilled: () {
              if (i == 5) _submit(context, ctrl, auth);
            },
          )),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.kBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed:
                ctrl.loading ? null : () => _submit(context, ctrl, auth),
            child: ctrl.loading
                ? SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: AppColors.kBlue, strokeWidth: 2))
                : const Text('Verificar',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 16),

        // Reenviar
        TextButton(
          onPressed: ctrl.cooldown > 0 || ctrl.loading
              ? null
              : () => ctrl.resend(),
          child: Text(
            ctrl.cooldown > 0
                ? 'Reenviar en ${ctrl.cooldown}s'
                : 'Reenviar código',
            style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(
                    alpha: ctrl.cooldown > 0 ? 0.5 : 1.0),
                fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context, UseVerifyEmailCode ctrl,
      AuthContext auth) async {
    await ctrl.submit(auth);
    // La navegación la maneja _VerifyView al detectar ctrl.verified
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.check_circle_outline, size: 56, color: Colors.white),
        const SizedBox(height: 16),
        const Text('¡Cuenta verificada!',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 8),
        Text(
          'Tu correo fue verificado correctamente.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14, color: Colors.white.withValues(alpha: 0.85)),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.kBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: onContinue,
            child: const Text('Continuar',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

// ── Caja individual para un dígito ───────────────────────────────────────────
class _DigitBox extends StatelessWidget {
  const _DigitBox({
    required this.controller,
    required this.focusNode,
    this.nextFocus,
    this.prevFocus,
    this.onFilled,
  });

  final TextEditingController controller;
  final FocusNode             focusNode;
  final FocusNode?            nextFocus;
  final FocusNode?            prevFocus;
  final VoidCallback?         onFilled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 56,
      child: TextField(
        controller:    controller,
        focusNode:     focusNode,
        textAlign:     TextAlign.center,
        maxLength:     1,
        keyboardType:  TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.4), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.4), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Colors.white, width: 2),
          ),
          fillColor: Colors.white.withValues(alpha: 0.15),
          filled: true,
        ),
        onChanged: (v) {
          if (v.isNotEmpty) {
            if (nextFocus != null) {
              FocusScope.of(context).requestFocus(nextFocus);
            } else {
              FocusScope.of(context).unfocus();
              onFilled?.call();
            }
          } else if (prevFocus != null) {
            FocusScope.of(context).requestFocus(prevFocus);
          }
        },
      ),
    );
  }
}

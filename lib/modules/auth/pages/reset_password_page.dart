import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/app_colors.dart';
import '../hooks/use_reset_password_form.dart';

// Equivalente a src/modules/auth/pages/ResetPasswordPage.jsx en React
// Fondo indigo, tarjeta translúcida

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  late final UseResetPasswordForm _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = UseResetPasswordForm();
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
      child: const _ResetView(),
    );
  }
}

class _ResetView extends StatelessWidget {
  const _ResetView();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<UseResetPasswordForm>();

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
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/logos/imagotipo-blanco-zammpy.svg',
                  height: 32,
                  colorFilter: const ColorFilter.mode(
                      Colors.white, BlendMode.srcIn),
                ),
                const SizedBox(height: 32),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1),
                  ),
                  child: ctrl.done
                      ? _DoneState()
                      : _FormState(ctrl: ctrl),
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
  const _FormState({required this.ctrl});
  final UseResetPasswordForm ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nueva contraseña',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 8),
        Text(
          'Ingresa el código que recibiste y tu nueva contraseña.',
          style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.85)),
        ),
        const SizedBox(height: 24),

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
                style: const TextStyle(
                    fontSize: 13, color: Colors.white)),
          ),

        // Código 6 dígitos
        Text('Código de verificación',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
                letterSpacing: 0.3)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _DigitBox(
            controller: ctrl.codeControllers[i],
            focusNode:  ctrl.codeFocusNodes[i],
            nextFocus:  i < 5 ? ctrl.codeFocusNodes[i + 1] : null,
            prevFocus:  i > 0 ? ctrl.codeFocusNodes[i - 1] : null,
          )),
        ),
        const SizedBox(height: 20),

        // Nueva contraseña
        _WhiteField(
          controller:  ctrl.passwordCtrl,
          label:       'Nueva contraseña',
          hint:        '••••••••',
          obscure:     !ctrl.showPass,
          onToggle:    ctrl.toggleShowPass,
          showingPass: ctrl.showPass,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 16),

        // Confirmar contraseña
        _WhiteField(
          controller:  ctrl.confirmCtrl,
          label:       'Confirmar contraseña',
          hint:        '••••••••',
          obscure:     !ctrl.showConfirm,
          onToggle:    ctrl.toggleShowConfirm,
          showingPass: ctrl.showConfirm,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(context, ctrl),
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
            onPressed:
                ctrl.loading ? null : () => _submit(context, ctrl),
            child: ctrl.loading
                ? SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: AppColors.kBlue, strokeWidth: 2))
                : const Text('Cambiar contraseña',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 16),

        Center(
          child: TextButton(
            onPressed: () => context.go('/login'),
            child: Text('Volver al inicio de sesión',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.85))),
          ),
        ),
      ],
    );
  }

  Future<void> _submit(
      BuildContext context, UseResetPasswordForm ctrl) async {
    await ctrl.submit();
    // La vista reacciona a ctrl.done
  }
}

class _DoneState extends StatelessWidget {
  const _DoneState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.lock_open_outlined, size: 56, color: Colors.white),
        const SizedBox(height: 16),
        const Text('¡Contraseña cambiada!',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 8),
        Text(
          'Tu contraseña fue actualizada exitosamente.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.85)),
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
            onPressed: () => context.go('/login?verified=true'),
            child: const Text('Iniciar sesión',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

// ── Campo con texto blanco para fondos oscuros ────────────────────────────────
class _WhiteField extends StatelessWidget {
  const _WhiteField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    required this.showingPass,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String                label;
  final String                hint;
  final bool                  obscure;
  final VoidCallback          onToggle;
  final bool                  showingPass;
  final TextInputAction        textInputAction;
  final ValueChanged<String>?  onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.85),
                letterSpacing: 0.3)),
        const SizedBox(height: 6),
        TextField(
          controller:      controller,
          obscureText:     obscure,
          textInputAction: textInputAction,
          onSubmitted:     onSubmitted,
          style: const TextStyle(fontSize: 15, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 14),
            suffixIcon: GestureDetector(
              onTap: onToggle,
              child: Icon(
                showingPass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            border: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.4))),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.4))),
            focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

// ── Caja de dígito (blanca, para fondo indigo) ────────────────────────────────
class _DigitBox extends StatelessWidget {
  const _DigitBox({
    required this.controller,
    required this.focusNode,
    this.nextFocus,
    this.prevFocus,
  });

  final TextEditingController controller;
  final FocusNode             focusNode;
  final FocusNode?            nextFocus;
  final FocusNode?            prevFocus;

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
            }
          } else if (prevFocus != null) {
            FocusScope.of(context).requestFocus(prevFocus);
          }
        },
      ),
    );
  }
}

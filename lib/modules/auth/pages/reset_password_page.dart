import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/app_colors.dart';
import '../components/auth_layout.dart';
import '../hooks/use_reset_password_form.dart';

// Equivalente a src/modules/auth/pages/ResetPasswordPage.jsx en React.
// Mismo diseño que el resto de auth: fondo blanco + logo (AuthLayout), sin tarjeta translúcida
// ni fondo azul. Además, en dos pasos: primero el código, y solo tras confirmarlo la contraseña.

class ResetPasswordPage extends StatefulWidget {
  final String? email;

  const ResetPasswordPage({super.key, this.email});

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
      child: _ResetView(email: widget.email),
    );
  }
}

class _ResetView extends StatelessWidget {
  const _ResetView({this.email});

  final String? email;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<UseResetPasswordForm>();
    return AuthLayout(
      child: ctrl.done
          ? const _DoneState()
          : _FormState(ctrl: ctrl, email: email),
    );
  }
}

class _FormState extends StatelessWidget {
  const _FormState({required this.ctrl, this.email});
  final UseResetPasswordForm ctrl;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final enCodigo = ctrl.step == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nueva contraseña',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.kTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          enCodigo
              ? (email != null && email!.isNotEmpty
                    ? 'Ingresa el código que enviamos a $email.'
                    : 'Ingresa el código de 6 dígitos de tu correo.')
              : 'Elige tu nueva contraseña.',
          style: const TextStyle(fontSize: 14, color: AppColors.kTextSecondary),
        ),
        const SizedBox(height: 20),

        if (ctrl.error.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Text(
              ctrl.error,
              style: const TextStyle(fontSize: 13, color: Color(0xFF991B1B)),
            ),
          ),

        if (enCodigo) ..._pasoCodigo(context) else ..._pasoContrasena(context),

        const SizedBox(height: 20),
        Center(
          child: TextButton(
            onPressed: () => context.go('/auth/forgot-password'),
            child: const Text(
              'Solicitar un código nuevo',
              style: TextStyle(fontSize: 13, color: AppColors.kTextSecondary),
            ),
          ),
        ),
      ],
    );
  }

  // ── Paso 1: código ──────────────────────────────────────────────────────────
  List<Widget> _pasoCodigo(BuildContext context) => [
    const Text(
      'Código de verificación',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.kTextSecondary,
        letterSpacing: 0.3,
      ),
    ),
    const SizedBox(height: 10),
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        6,
        (i) => _DigitBox(
          controller: ctrl.codeControllers[i],
          focusNode: ctrl.codeFocusNodes[i],
          nextFocus: i < 5 ? ctrl.codeFocusNodes[i + 1] : null,
          prevFocus: i > 0 ? ctrl.codeFocusNodes[i - 1] : null,
          onCompleto: () => ctrl.continuarAContrasena(),
        ),
      ),
    ),
    const SizedBox(height: 24),
    _PrimaryButton(
      label: 'Continuar',
      loading: ctrl.loading,
      onPressed: () => ctrl.continuarAContrasena(),
    ),
  ];

  // ── Paso 2: nueva contraseña (solo tras confirmar el código) ──────────────────
  List<Widget> _pasoContrasena(BuildContext context) => [
    _Field(
      controller: ctrl.passwordCtrl,
      label: 'Nueva contraseña',
      hint: 'Mínimo 6 caracteres',
      obscure: !ctrl.showPass,
      onToggle: ctrl.toggleShowPass,
      showing: ctrl.showPass,
      textInputAction: TextInputAction.next,
    ),
    const SizedBox(height: 16),
    _Field(
      controller: ctrl.confirmCtrl,
      label: 'Confirmar contraseña',
      hint: 'Repite la contraseña',
      obscure: !ctrl.showConfirm,
      onToggle: ctrl.toggleShowConfirm,
      showing: ctrl.showConfirm,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => ctrl.submit(),
    ),
    const SizedBox(height: 24),
    _PrimaryButton(
      label: 'Cambiar contraseña',
      loading: ctrl.loading,
      onPressed: () => ctrl.submit(),
    ),
    const SizedBox(height: 8),
    Center(
      child: TextButton.icon(
        onPressed: ctrl.loading ? null : ctrl.volverACodigo,
        icon: const Icon(Icons.arrow_back, size: 15, color: AppColors.kTextSecondary),
        label: const Text(
          'Volver al código',
          style: TextStyle(fontSize: 13, color: AppColors.kTextSecondary),
        ),
      ),
    ),
  ];
}

class _DoneState extends StatelessWidget {
  const _DoneState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.lock_open_outlined, size: 56, color: AppColors.kBlue),
        const SizedBox(height: 16),
        const Text(
          '¡Contraseña cambiada!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.kTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tu contraseña fue actualizada exitosamente.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.kTextSecondary),
        ),
        const SizedBox(height: 28),
        _PrimaryButton(
          label: 'Iniciar sesión',
          loading: false,
          onPressed: () => context.go('/login?resetSuccess=true'),
        ),
      ],
    );
  }
}

// ── Botón primario índigo ─────────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.kBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── Campo oscuro sobre blanco ─────────────────────────────────────────────────
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    required this.showing,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final bool showing;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.kTextSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: const TextStyle(fontSize: 15, color: AppColors.kTextPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.kTextMuted, fontSize: 14),
            suffixIcon: GestureDetector(
              onTap: onToggle,
              child: Icon(
                showing ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: AppColors.kTextMuted,
              ),
            ),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.kBlue, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

// ── Caja de dígito (oscura sobre blanco) ──────────────────────────────────────
class _DigitBox extends StatelessWidget {
  const _DigitBox({
    required this.controller,
    required this.focusNode,
    this.nextFocus,
    this.prevFocus,
    this.onCompleto,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocus;
  final FocusNode? prevFocus;
  final VoidCallback? onCompleto;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.kTextPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.kBlue, width: 2),
          ),
        ),
        onChanged: (v) {
          if (v.isNotEmpty) {
            if (nextFocus != null) {
              FocusScope.of(context).requestFocus(nextFocus);
            } else {
              FocusScope.of(context).unfocus();
              onCompleto?.call();
            }
          } else if (prevFocus != null) {
            FocusScope.of(context).requestFocus(prevFocus);
          }
        },
      ),
    );
  }
}

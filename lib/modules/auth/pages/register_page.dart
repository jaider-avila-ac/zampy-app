import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../context/auth_context.dart';
import '../../../services/google_auth_service.dart';
import '../../../shared/app_colors.dart';
import '../components/google_icon.dart';
import '../hooks/use_register_form.dart';

// Equivalente a src/modules/auth/pages/RegisterPage.jsx en React

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late final UseRegisterForm _form;

  @override
  void initState() {
    super.initState();
    _form = UseRegisterForm();
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
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatelessWidget {
  const _RegisterView();

  @override
  Widget build(BuildContext context) {
    final form = context.watch<UseRegisterForm>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Center(
                child: SvgPicture.asset(
                  'assets/logos/imagotipo-indigo-zammpy.svg',
                  height: 36,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF4A37F2), BlendMode.srcIn),
                ),
              ),
              const SizedBox(height: 36),

              const Text(
                'Crea tu cuenta',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.kTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Empieza gratis, sin tarjeta',
                style: TextStyle(fontSize: 14, color: AppColors.kTextSecondary),
              ),
              const SizedBox(height: 20),

              if (form.error.isNotEmpty)
                _Alert(text: form.error),

              // Nombre + Apellido en fila (grid-2 de React)
              Row(
                children: [
                  Expanded(
                    child: _UnderlineField(
                      controller: form.nombreCtrl,
                      label: 'Nombre',
                      hint: 'Juan',
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _UnderlineField(
                      controller: form.apellidoCtrl,
                      label: 'Apellido',
                      hint: 'García',
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _UnderlineField(
                controller: form.emailCtrl,
                label: 'Correo electrónico',
                hint: 'tu@correo.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),

              _UnderlineField(
                controller: form.passwordCtrl,
                label: 'Contraseña',
                hint: '••••••••',
                obscure: !form.showPass,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(context, form),
                suffix: GestureDetector(
                  onTap: form.toggleShowPass,
                  child: Icon(
                    form.showPass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: AppColors.kTextMuted,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Mínimo 8 caracteres',
                style: TextStyle(fontSize: 11, color: AppColors.kTextMuted),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.kBlue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: form.loading ? null : () => _submit(context, form),
                  child: form.loading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Crear cuenta',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 24),

              const _Divider(),
              const SizedBox(height: 20),

              _GoogleButton(loading: form.loading),
              const SizedBox(height: 28),

              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('¿Ya tienes una cuenta?',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.kTextSecondary)),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.only(left: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('Iniciar sesión',
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

  Future<void> _submit(BuildContext context, UseRegisterForm form) async {
    final email = await form.submit();
    if (email != null && context.mounted) {
      context.go('/auth/verify-code', extra: email);
    }
  }
}

class _UnderlineField extends StatelessWidget {
  const _UnderlineField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscure         = false,
    this.keyboardType    = TextInputType.text,
    this.textInputAction = TextInputAction.next,
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
          controller:      controller,
          obscureText:     obscure,
          keyboardType:    keyboardType,
          textInputAction: textInputAction,
          onSubmitted:     onSubmitted,
          style: const TextStyle(fontSize: 15, color: AppColors.kTextPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: AppColors.kTextMuted, fontSize: 14),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 4), child: suffix)
                : null,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 32, minHeight: 32),
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
      ],
    );
  }
}

class _Alert extends StatelessWidget {
  const _Alert({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: const TextStyle(fontSize: 13, color: Color(0xFF991B1B))),
    );
  }
}

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

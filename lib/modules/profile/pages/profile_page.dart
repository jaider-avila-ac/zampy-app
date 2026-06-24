import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../context/auth_context.dart';
import '../../../shared/app_colors.dart';
import '../../../shared/app_header.dart';
import '../hooks/use_profile.dart';

// Equivalente a src/modules/profile/pages/ProfilePage.jsx en React

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthContext>();
    return ChangeNotifierProvider(
      create: (_) => UseProfile(auth: auth),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<UseProfile>();

    return Scaffold(
      backgroundColor: AppColors.kBgPage,
      appBar: const AppHeader(title: 'Mi perfil'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [

          // ── Datos personales ─────────────────────────────────────────────
          _PersonalDataCard(ctrl: ctrl),

          // ── Cambiar contraseña (solo LOCAL) ──────────────────────────────
          if (ctrl.isLocal) ...[
            const SizedBox(height: 20),
            _PasswordCard(ctrl: ctrl),
          ],
        ],
      ),
    );
  }
}

// ── Tarjeta de datos personales ───────────────────────────────────────────────

class _PersonalDataCard extends StatelessWidget {
  const _PersonalDataCard({required this.ctrl});
  final UseProfile ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: AppColors.kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Avatar ─────────────────────────────────────────────────────
          _AvatarSection(ctrl: ctrl),
          const SizedBox(height: 20),

          // ── Nombre ─────────────────────────────────────────────────────
          _LabeledField(
            label:    'Nombre',
            value:    ctrl.nombre,
            onChanged: ctrl.setNombre,
          ),
          const SizedBox(height: 12),

          // ── Apellido ───────────────────────────────────────────────────
          _LabeledField(
            label:    'Apellido',
            value:    ctrl.apellido,
            onChanged: ctrl.setApellido,
          ),
          const SizedBox(height: 12),

          // ── Email (read-only) ──────────────────────────────────────────
          _EmailField(
            email:    context.read<AuthContext>().email ?? '',
            provider: ctrl.provider,
          ),

          // ── Error ──────────────────────────────────────────────────────
          if (ctrl.errorPerfil.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ErrorBox(message: ctrl.errorPerfil),
          ],
          const SizedBox(height: 16),

          // ── Botón guardar ──────────────────────────────────────────────
          _SaveButton(
            saving:  ctrl.saving,
            saved:   ctrl.saved,
            label:   ctrl.saved ? 'Guardado' : ctrl.saving ? 'Guardando...' : 'Guardar cambios',
            onTap:   ctrl.handleSavePerfil,
            color:   AppColors.kBlue,
          ),
        ],
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.ctrl});
  final UseProfile ctrl;

  @override
  Widget build(BuildContext context) {
    final avatarSrc = ctrl.avatarSrc;
    final isLocal   = ctrl.preview != null;

    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Círculo con imagen o inicial
            SizedBox(
              width: 80, height: 80,
              child: ClipOval(
                child: avatarSrc != null
                    ? (isLocal
                        ? Image.file(File(avatarSrc), fit: BoxFit.cover)
                        : Image.network(avatarSrc, fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => _InitialCircle(
                              initial: ctrl.initial)))
                    : _InitialCircle(initial: ctrl.initial),
              ),
            ),
            // Botón cámara
            Positioned(
              bottom: 0, right: 0,
              child: GestureDetector(
                onTap: ctrl.pickImage,
                child: Container(
                  width: 28, height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:        AppColors.kBlue,
                    shape:        BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color:     Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4, offset: const Offset(0, 2),
                    )],
                  ),
                  child: const Icon(Icons.photo_camera, size: 13, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.read<AuthContext>().displayName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.kTextPrimary),
              ),
              Text(
                context.read<AuthContext>().email ?? '',
                style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted),
              ),
              const SizedBox(height: 4),
              const Text(
                'Toca el ícono de cámara para cambiar tu foto',
                style: TextStyle(fontSize: 10, color: AppColors.kTextMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InitialCircle extends StatelessWidget {
  const _InitialCircle({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80, height: 80,
      color: AppColors.kBlue,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
            color: Colors.white),
      ),
    );
  }
}

// ── Tarjeta de contraseña ─────────────────────────────────────────────────────

class _PasswordCard extends StatelessWidget {
  const _PasswordCard({required this.ctrl});
  final UseProfile ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: AppColors.kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Row(
            children: [
              Icon(Icons.key_outlined, size: 15, color: AppColors.kBlue),
              SizedBox(width: 6),
              Text('Cambiar contraseña',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.kTextPrimary)),
            ],
          ),
          const SizedBox(height: 2),
          const Text('Elige una contraseña segura de al menos 6 caracteres',
              style: TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
          const SizedBox(height: 16),

          // Contraseña actual
          _PasswordField(
            label:       'Contraseña actual',
            value:       ctrl.currentPwd,
            show:        ctrl.showCurrent,
            onChanged:   ctrl.setCurrentPwd,
            onToggle:    ctrl.toggleShowCurrent,
          ),
          const SizedBox(height: 12),

          // Nueva contraseña
          _PasswordField(
            label:     'Nueva contraseña',
            value:     ctrl.newPwd,
            show:      ctrl.showNew,
            onChanged: ctrl.setNewPwd,
            onToggle:  ctrl.toggleShowNew,
          ),

          // Error
          if (ctrl.errorPwd.isNotEmpty) ...[
            const SizedBox(height: 12),
            _ErrorBox(message: ctrl.errorPwd),
          ],
          const SizedBox(height: 16),

          // Botón
          _SaveButton(
            saving:  ctrl.savingPwd,
            saved:   ctrl.savedPwd,
            label:   ctrl.savedPwd
                ? 'Contraseña actualizada'
                : ctrl.savingPwd ? 'Guardando...' : 'Actualizar contraseña',
            onTap:   ctrl.handleSavePwd,
            color:   const Color(0xFF1E293B),
          ),
        ],
      ),
    );
  }
}

// ── Widgets reutilizables ─────────────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String          label;
  final String          value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColors.kTextMuted)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          onChanged:    onChanged,
          style: const TextStyle(fontSize: 14, color: AppColors.kTextPrimary),
          decoration: InputDecoration(
            isDense:      true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled:       true,
            fillColor:    Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.kCardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.kCardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.kBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.email, required this.provider});
  final String  email;
  final String? provider;

  @override
  Widget build(BuildContext context) {
    final hint = provider == 'GOOGLE'
        ? 'Gestionado por Google — no editable'
        : 'El correo no se puede cambiar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Correo electrónico',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColors.kTextMuted)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: email,
          enabled:      false,
          style: const TextStyle(fontSize: 14, color: AppColors.kTextMuted),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled:     true,
            fillColor:  const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.kCardBorder),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.kCardBorder),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(hint,
              style: const TextStyle(fontSize: 10, color: AppColors.kTextMuted)),
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.label,
    required this.value,
    required this.show,
    required this.onChanged,
    required this.onToggle,
  });
  final String          label;
  final String          value;
  final bool            show;
  final ValueChanged<String> onChanged;
  final VoidCallback    onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColors.kTextMuted)),
        const SizedBox(height: 4),
        TextFormField(
          obscureText: !show,
          initialValue: value,
          onChanged:   onChanged,
          style: const TextStyle(fontSize: 14, color: AppColors.kTextPrimary),
          decoration: InputDecoration(
            isDense: true,
            hintText: '••••••••',
            hintStyle: const TextStyle(color: AppColors.kTextMuted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled:     true,
            fillColor:  Colors.white,
            suffixIcon: GestureDetector(
              onTap: onToggle,
              child: Icon(
                show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18, color: AppColors.kTextMuted,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.kCardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.kCardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.kBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.saving,
    required this.saved,
    required this.label,
    required this.onTap,
    required this.color,
  });
  final bool         saving;
  final bool         saved;
  final String       label;
  final VoidCallback onTap;
  final Color        color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (saving || saved) ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: (saving || saved) ? 0.6 : 1.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:        color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (saved)
                const Icon(Icons.check, size: 15, color: Colors.white)
              else if (saving)
                const SizedBox(
                  width: 15, height: 15,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              if (saving || saved) const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(message,
          style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
    );
  }
}

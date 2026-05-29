import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../auth/auth_service.dart';

/// Equivalente a ProfilePage.jsx — edición de nombre, apellido, avatar
/// y cambio de contraseña (solo usuarios LOCAL).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ── Datos de perfil ────────────────────────────────────────────────────────
  final _nombreCtrl   = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  String? _email;
  String? _avatarUrl;
  String? _provider; // 'LOCAL' | 'GOOGLE' | null

  XFile?  _fotoFile;
  String? _previewPath;
  bool    _saving      = false;
  bool    _saved       = false;
  String  _errorPerfil = '';

  // ── Contraseña ─────────────────────────────────────────────────────────────
  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl     = TextEditingController();
  bool   _showCurrent   = false;
  bool   _showNew       = false;
  bool   _savingPwd     = false;
  bool   _savedPwd      = false;
  String _errorPwd      = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Datos locales (rápido)
    final local = await AuthService.getAuthData();
    if (!mounted) return;
    setState(() {
      _nombreCtrl.text   = local?['nombre']   as String? ?? '';
      _apellidoCtrl.text = local?['apellido'] as String? ?? '';
      _email    = local?['email']   as String?;
      _avatarUrl = local?['avatar'] as String?;
    });

    // Provider desde el backend (equivalente a colaboracionService.getMe)
    final me = await AuthService.getMe();
    if (!mounted) return;
    setState(() => _provider = me?['provider'] as String?);
  }

  // ── Foto ───────────────────────────────────────────────────────────────────
  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() {
      _fotoFile    = file;
      _previewPath = file.path;
    });
  }

  // ── Guardar perfil ─────────────────────────────────────────────────────────
  Future<void> _savePerfil() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      setState(() => _errorPerfil = 'El nombre es obligatorio');
      return;
    }
    setState(() { _saving = true; _errorPerfil = ''; });
    try {
      await AuthService.updateProfile(
        nombre:   nombre,
        apellido: _apellidoCtrl.text.trim(),
        foto:     _fotoFile,
      );
      if (!mounted) return;
      setState(() { _saved = true; _fotoFile = null; });
      Future.delayed(const Duration(seconds: 2),
          () { if (mounted) setState(() => _saved = false); });
    } catch (e) {
      if (mounted) setState(() => _errorPerfil = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Cambiar contraseña ─────────────────────────────────────────────────────
  Future<void> _savePassword() async {
    final current = _currentPwdCtrl.text;
    final next    = _newPwdCtrl.text;
    if (current.isEmpty || next.isEmpty) {
      setState(() => _errorPwd = 'Completa ambos campos');
      return;
    }
    if (next.length < 6) {
      setState(() => _errorPwd = 'La nueva contraseña debe tener al menos 6 caracteres');
      return;
    }
    setState(() { _savingPwd = true; _errorPwd = ''; });
    try {
      await AuthService.changePassword(
          currentPassword: current, newPassword: next);
      if (!mounted) return;
      setState(() {
        _savedPwd = true;
        _currentPwdCtrl.clear();
        _newPwdCtrl.clear();
      });
      Future.delayed(const Duration(seconds: 2),
          () { if (mounted) setState(() => _savedPwd = false); });
    } catch (e) {
      if (mounted) setState(() => _errorPwd = e.toString());
    } finally {
      if (mounted) setState(() => _savingPwd = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isLocal = _provider == 'LOCAL';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text('Mi perfil',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE2E8F0)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPerfilCard(),
          const SizedBox(height: 16),
          if (isLocal) _buildPasswordCard(),
        ],
      ),
    );
  }

  // ── Tarjeta de datos personales ────────────────────────────────────────────
  Widget _buildPerfilCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Row(
            children: [
              Stack(
                children: [
                  _buildAvatar(),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickPhoto,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4)
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 13),
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
                      '${_nombreCtrl.text} ${_apellidoCtrl.text}'.trim(),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B)),
                    ),
                    if (_email != null)
                      Text(_email!,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 4),
                    const Text(
                      'Toca el icono de cámara para cambiar tu foto',
                      style:
                          TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Nombre
          _buildField(
            label: 'Nombre',
            controller: _nombreCtrl,
          ),
          const SizedBox(height: 12),

          // Apellido
          _buildField(
            label: 'Apellido',
            controller: _apellidoCtrl,
          ),
          const SizedBox(height: 12),

          // Email (readonly)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Correo electrónico',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569))),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  _email ?? '',
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _provider == 'GOOGLE'
                    ? 'Gestionado por Google — no editable'
                    : 'El correo no se puede cambiar',
                style:
                    const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ],
          ),

          // Error perfil
          if (_errorPerfil.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildError(_errorPerfil),
          ],

          const SizedBox(height: 16),

          // Botón guardar
          _buildActionButton(
            label: _saved ? 'Guardado' : _saving ? 'Guardando...' : 'Guardar cambios',
            loading: _saving,
            success: _saved,
            color: const Color(0xFF4F46E5),
            onTap: _savePerfil,
          ),
        ],
      ),
    );
  }

  // ── Tarjeta de contraseña ──────────────────────────────────────────────────
  Widget _buildPasswordCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.key_rounded, size: 15, color: Color(0xFF4F46E5)),
              SizedBox(width: 6),
              Text('Cambiar contraseña',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155))),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Elige una contraseña segura de al menos 6 caracteres',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),

          // Contraseña actual
          _buildPasswordField(
            label: 'Contraseña actual',
            controller: _currentPwdCtrl,
            show: _showCurrent,
            onToggle: () => setState(() => _showCurrent = !_showCurrent),
          ),
          const SizedBox(height: 12),

          // Nueva contraseña
          _buildPasswordField(
            label: 'Nueva contraseña',
            controller: _newPwdCtrl,
            show: _showNew,
            onToggle: () => setState(() => _showNew = !_showNew),
          ),

          // Error contraseña
          if (_errorPwd.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildError(_errorPwd),
          ],

          const SizedBox(height: 16),

          _buildActionButton(
            label: _savedPwd
                ? 'Contraseña actualizada'
                : _savingPwd
                    ? 'Guardando...'
                    : 'Actualizar contraseña',
            loading: _savingPwd,
            success: _savedPwd,
            color: const Color(0xFF1E293B),
            onTap: _savePassword,
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _buildAvatar() {
    final initial =
        (_nombreCtrl.text.isNotEmpty ? _nombreCtrl.text : _email ?? '?')
            [0]
            .toUpperCase();

    Widget image;
    if (_previewPath != null) {
      image = Image.asset(_previewPath!, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _avatarInitial(initial));
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      image = Image.network(_avatarUrl!, fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _avatarInitial(initial));
    } else {
      image = _avatarInitial(initial);
    }

    return ClipOval(
      child: SizedBox(width: 72, height: 72, child: image),
    );
  }

  Widget _avatarInitial(String initial) => Container(
        color: const Color(0xFF4F46E5),
        alignment: Alignment.center,
        child: Text(initial,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900)),
      );

  Widget _buildField({
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool show,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          obscureText: !show,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool loading,
    required bool success,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (loading || success) ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (success)
              const Icon(Icons.check_rounded, size: 16)
            else if (loading)
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            if (success || loading) const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String msg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Text(msg,
            style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
      );
}

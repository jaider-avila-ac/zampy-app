import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/push_service.dart';
import '../../modules/auth/auth_service.dart';
import '../../modules/auth/login_screen.dart';
import '../../modules/logros/logro_service.dart';
import '../../modules/logros/logros_screen.dart';
import '../../modules/notifications/notifications_screen.dart';
import '../app_colors.dart';

/// Equivalente al Sidebar.jsx adaptado a móvil como Drawer.
/// Abre al presionar el botón hamburger en el AppBar de ExploreScreen.
///
/// • Muestra los mismos ítems que NAV_PRIVATE
/// • Logros solo aparece si el usuario tiene al menos un menú
/// • Sin botón "Crear menú" en el Drawer (ya está en BottomNav)
class AppDrawer extends StatefulWidget {
  const AppDrawer({
    super.key,
    this.unreadCount = 0,
  });

  final int unreadCount;

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _nombre    = '';
  String _email     = '';
  String? _avatar;
  bool _tieneMenu   = false;
  bool _loadingMeta = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar datos cada vez que el Drawer vuelve a ser visible
    // (garantiza que tras un cambio de usuario los datos sean actuales)
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Datos del usuario desde secure storage (siempre frescos)
    final data = await AuthService.getAuthData();
    // ¿Tiene al menos un menú? (para mostrar Logros)
    final hasMen = await LogroService.tieneMenus();

    if (!mounted) return;
    setState(() {
      if (data != null) {
        final nombre   = (data['nombre']   as String? ?? '').trim();
        final apellido = (data['apellido'] as String? ?? '').trim();
        _nombre  = apellido.isEmpty ? nombre : '$nombre $apellido';
        _email   = (data['email']  as String? ?? '').trim();
        _avatar  = data['avatar'] as String?;
      }
      _tieneMenu   = hasMen;
      _loadingMeta = false;
    });
  }

  String get _initial =>
      _nombre.isNotEmpty ? _nombre[0].toUpperCase()
                         : _email.isNotEmpty ? _email[0].toUpperCase() : 'U';

  Future<void> _doLogout() async {
    Navigator.pop(context); // cerrar Drawer
    PushService.disconnect();
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _navigate(Widget screen) {
    Navigator.pop(context); // cerrar Drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _comingSoon(String label) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — próximamente'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.kTextSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      width: 260,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLogo(),
            const Divider(height: 1, color: AppColors.kCardBorder),
            const SizedBox(height: 8),
            Expanded(child: _buildNav()),
            const Divider(height: 1, color: AppColors.kCardBorder),
            _buildProfile(),
          ],
        ),
      ),
    );
  }

  // ── Logo ───────────────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/zampy-logo.svg',
            width: 32,
            height: 32,
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ZamPy',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.kTextPrimary,
                  letterSpacing: -0.3,
                  height: 1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'MENÚ DIGITAL',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kTextMuted,
                  letterSpacing: 1.4,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Navegación ─────────────────────────────────────────────────────────────
  Widget _buildNav() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            label: 'Inicio',
            onTap: () => Navigator.pop(context),
          ),
          _NavItem(
            icon: Icons.restaurant_menu_outlined,
            label: 'Mis Menús',
            onTap: () => _comingSoon('Mis Menús'),
          ),
          _NavItem(
            icon: Icons.notifications_outlined,
            label: 'Notificaciones',
            badge: widget.unreadCount,
            onTap: () => _navigate(const NotificationsScreen()),
          ),
          // Logros — solo si tiene menús (misma lógica que React)
          if (_loadingMeta)
            const SizedBox.shrink()
          else if (_tieneMenu)
            _NavItem(
              icon: Icons.emoji_events_outlined,
              label: 'Logros',
              onTap: () => _navigate(const LogrosScreen()),
            ),
          _NavItem(
            icon: Icons.people_outline,
            label: 'Invitaciones',
            onTap: () => _comingSoon('Invitaciones'),
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Ajustes',
            onTap: () => _comingSoon('Ajustes'),
          ),
          _NavItem(
            icon: Icons.credit_card_outlined,
            label: 'Suscripciones',
            onTap: () => _comingSoon('Suscripciones'),
          ),
        ],
      ),
    );
  }

  // ── Perfil + Cerrar sesión ─────────────────────────────────────────────────
  Widget _buildProfile() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      child: Row(
        children: [
          // Avatar — foto si existe, inicial si no
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.kBlue,
              shape: BoxShape.circle,
              image: _avatar != null && _avatar!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(_avatar!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _avatar == null || _avatar!.isEmpty
                ? Center(
                    child: Text(
                      _initial,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          // Nombre y email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_nombre.isNotEmpty)
                  Text(
                    _nombre,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (_email.isNotEmpty)
                  Text(
                    _email,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.kTextMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Logout
          IconButton(
            icon: const Icon(Icons.logout_rounded,
                size: 18, color: AppColors.kTextMuted),
            tooltip: 'Cerrar sesión',
            onPressed: _doLogout,
          ),
        ],
      ),
    );
  }
}

// ── NavItem ────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 20, color: AppColors.kTextSecondary),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.kBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.kTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

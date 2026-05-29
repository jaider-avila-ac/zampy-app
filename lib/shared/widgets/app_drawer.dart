import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/app_cache.dart';
import '../../core/push_service.dart';
import '../../modules/auth/auth_service.dart';
import '../../modules/auth/login_screen.dart';
import '../../modules/logros/logro_service.dart';
import '../../modules/logros/logros_screen.dart';
import '../../modules/ajustes/ajustes_screen.dart';
import '../../modules/ajustes/profile_screen.dart';
import '../../modules/invitaciones/invitaciones_screen.dart';
import '../../modules/notifications/notifications_screen.dart';
import '../../modules/suscripciones/suscripciones_screen.dart';
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
  String _nombre = '';
  String _email  = '';
  String? _avatar;

  // Caché estático — sobrevive reinicios del widget durante la sesión.
  // Se limpia en logout para que el próximo usuario empiece desde cero.
  static bool? _cachedTieneMenu;
  static Map<String, dynamic>? _cachedUserData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Aplica caché de inmediato para que el nombre aparezca sin parpadeo
    if (_cachedUserData != null) _applyUserData(_cachedUserData!);

    final data = await AuthService.getAuthData();
    _cachedTieneMenu ??= await LogroService.tieneMenus();

    if (!mounted) return;
    if (data != null) {
      _cachedUserData = data;
      _applyUserData(data);
    }
  }

  void _applyUserData(Map<String, dynamic> data) {
    if (!mounted) return;
    setState(() {
      final nombre   = (data['nombre']   as String? ?? '').trim();
      final apellido = (data['apellido'] as String? ?? '').trim();
      _nombre = apellido.isEmpty ? nombre : '$nombre $apellido';
      _email  = (data['email']  as String? ?? '').trim();
      _avatar = data['avatar'] as String?;
    });
  }

  String get _initial =>
      _nombre.isNotEmpty ? _nombre[0].toUpperCase()
                         : _email.isNotEmpty ? _email[0].toUpperCase() : 'U';

  Future<void> _doLogout() async {
    Navigator.pop(context);
    _cachedTieneMenu = null;
    _cachedUserData  = null;
    AppCache.clear();
    PushService.disconnect();
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _goToLogros() {
    if (_cachedTieneMenu == true) {
      _navigate(const LogrosScreen());
    } else {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aún no tienes menús creados'),
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.kTextSecondary,
        ),
      );
    }
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
          _NavItem(
            icon: Icons.emoji_events_outlined,
            label: 'Logros',
            onTap: _goToLogros,
          ),
          _NavItem(
            icon: Icons.people_outline,
            label: 'Invitaciones',
            onTap: () => _navigate(const InvitacionesScreen()),
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Ajustes',
            onTap: () => _navigate(const AjustesScreen()),
          ),
          _NavItem(
            icon: Icons.credit_card_outlined,
            label: 'Suscripciones',
            onTap: () => _navigate(const SuscripcionesScreen()),
          ),
        ],
      ),
    );
  }

  // ── Perfil + Cerrar sesión ─────────────────────────────────────────────────
  Widget _buildProfile() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Row(
        children: [
          // Avatar + nombre + email — tappable → ProfileScreen
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                Navigator.pop(context); // cerrar Drawer
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                // Invalidar caché al volver para reflejar cambios del perfil
                _cachedUserData = null;
                _loadUserData();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    // Avatar
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
                  ],
                ),
              ),
            ),
          ),
          // Logout (separado del tappable area)
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

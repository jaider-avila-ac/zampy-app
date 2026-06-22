import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../context/auth_context.dart';
import '../../context/notificacion_context.dart';
import '../../shared/app_colors.dart';

// Equivalente a src/components/layout/Sidebar.jsx en React
// En móvil se usa como Drawer (desliza desde la izquierda)

// Rutas públicas (sin sesión)
const _navPublic = [
  _NavItem(path: '/',              icon: Icons.home_outlined,            label: 'Inicio'),
];

// Rutas privadas (con sesión) — mismo orden que React Sidebar.jsx
const _navPrivate = [
  _NavItem(path: '/',              icon: Icons.home_outlined,            label: 'Inicio'),
  _NavItem(path: '/menus',         icon: Icons.restaurant_menu_outlined, label: 'Mis Menús'),
  _NavItem(path: '/notifications', icon: Icons.notifications_outlined,   label: 'Notificaciones'),
  _NavItem(path: '/logros',        icon: Icons.emoji_events_outlined,    label: 'Logros'),
  _NavItem(path: '/invitaciones',  icon: Icons.people_outlined,          label: 'Invitaciones'),
  _NavItem(path: '/settings',      icon: Icons.settings_outlined,        label: 'Ajustes'),
  _NavItem(path: '/suscripcion',   icon: Icons.credit_card_outlined,     label: 'Suscripciones'),
];

class _NavItem {
  const _NavItem({required this.path, required this.icon, required this.label});
  final String   path;
  final IconData icon;
  final String   label;
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthContext>();
    final notifCtx  = context.watch<NotificacionContext>();
    final location  = GoRouterState.of(context).uri.path;

    final nav = auth.isLoggedIn ? _navPrivate : _navPublic;

    return Drawer(
      backgroundColor: Colors.white,
      width: 288, // w-72 = 288px igual que React
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          children: [
            // ── Logo + botón cerrar ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 12, 20),
              child: Row(
                children: [
                  // imagotipo-indigo-zammpy.svg — mismo que Sidebar.jsx
                  SvgPicture.asset(
                    'assets/logos/imagotipo-indigo-zammpy.svg',
                    height: 28,
                  ),
                  const Spacer(),
                  // Botón X para cerrar (equivalente al <X> de React móvil)
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.close, size: 18,
                          color: AppColors.kTextSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // ── Navegación ─────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: nav.map((item) {
                  final isActive = item.path == '/'
                      ? location == '/'
                      : location.startsWith(item.path);

                  return _NavTile(
                    item:     item,
                    isActive: isActive,
                    unread:   item.path == '/notifications' ? notifCtx.unread : 0,
                    onTap:    () {
                      if (item.path == '/notifications') notifCtx.resetUnread();
                      Navigator.of(context).pop();
                      context.go(item.path);
                    },
                  );
                }).toList(),
              ),
            ),

            // ── Crear menú (solo si logueado) ──────────────────────────
            if (auth.isLoggedIn)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.kBlue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/menus/new');
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Crear menú',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),

            // ── Perfil / Login ─────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: auth.isLoggedIn
                  ? _ProfileTile(auth: auth, onClose: () => Navigator.of(context).pop())
                  : _LoginButton(onClose: () => Navigator.of(context).pop()),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ítem de navegación ────────────────────────────────────────────────────────
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.isActive,
    required this.unread,
    required this.onTap,
  });

  final _NavItem item;
  final bool     isActive;
  final int      unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF8FAFC) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  item.icon,
                  size: 21,
                  color: isActive ? AppColors.kTextPrimary : AppColors.kTextSecondary,
                ),
                if (unread > 0)
                  Positioned(
                    top: -4, right: -4,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: const BoxDecoration(
                        color: AppColors.kBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 9,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AppColors.kTextPrimary : AppColors.kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Perfil en la parte inferior ───────────────────────────────────────────────
class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.auth, required this.onClose});
  final AuthContext auth;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        GestureDetector(
          onTap: () { onClose(); context.go('/perfil'); },
          child: auth.avatarUrl != null && auth.avatarUrl!.isNotEmpty
              ? CircleAvatar(radius: 18, backgroundImage: NetworkImage(auth.avatarUrl!))
              : Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(
                      color: AppColors.kBlue, shape: BoxShape.circle),
                  child: Center(
                    child: Text(auth.initial,
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w900, fontSize: 14)),
                  ),
                ),
        ),
        const SizedBox(width: 10),
        // Nombre y correo
        Expanded(
          child: GestureDetector(
            onTap: () { onClose(); context.go('/perfil'); },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auth.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13,
                        fontWeight: FontWeight.w600, color: AppColors.kTextPrimary)),
                if (auth.email != null)
                  Text(auth.email!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
              ],
            ),
          ),
        ),
        // Cerrar sesión
        GestureDetector(
          onTap: () {
            onClose();
            auth.logout();
            context.go('/login');
          },
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(Icons.logout, size: 16, color: AppColors.kTextSecondary),
          ),
        ),
      ],
    );
  }
}

// ── Botón iniciar sesión ──────────────────────────────────────────────────────
class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.kTextSecondary,
          side: const BorderSide(color: AppColors.kCardBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () {
          onClose();
          context.go('/login');
        },
        icon: const Icon(Icons.login, size: 16),
        label: const Text('Iniciar sesión',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

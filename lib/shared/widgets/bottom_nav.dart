import 'package:flutter/material.dart';
import '../app_colors.dart';

/// Equivalente a BottomNav.jsx — barra de navegación inferior móvil.
/// items: Inicio · Menús · [Crear] · Notif · Pagos
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.kWhite,
        border: Border(top: BorderSide(color: AppColors.kCardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _NavItem(index: 0, current: currentIndex, icon: Icons.home_outlined,       activeIcon: Icons.home,            label: 'Inicio',  onTap: onTap),
              _NavItem(index: 1, current: currentIndex, icon: Icons.restaurant_menu_outlined, activeIcon: Icons.restaurant_menu, label: 'Menús',   onTap: onTap),
              // Botón Crear — centrado, azul
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.kBlue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add, color: AppColors.kWhite, size: 17),
                      ),
                      const SizedBox(height: 2),
                      Text('Crear',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.kTextMuted,
                          )),
                    ],
                  ),
                ),
              ),
              _NavItem(
                index: 3,
                current: currentIndex,
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications,
                label: 'Notif.',
                onTap: onTap,
                badge: unreadCount,
              ),
              _NavItem(index: 4, current: currentIndex, icon: Icons.credit_card_outlined, activeIcon: Icons.credit_card, label: 'Pagos', onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.current,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final int index;
  final int current;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final ValueChanged<int> onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    final color  = active ? AppColors.kTextPrimary : AppColors.kTextMuted;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(active ? activeIcon : icon,
                    size: 22,
                    color: color,
                    weight: active ? 700 : 400),
                if (badge > 0)
                  Positioned(
                    top: -3,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.kBlue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

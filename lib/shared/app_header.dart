import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_colors.dart';

// AppBar reutilizable para todas las páginas internas
// Maneja el botón atrás de forma inteligente: pop si hay historial, sino va a '/'

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  final String         title;
  final String?        subtitle;
  final List<Widget>?  actions;

  void _goBack(BuildContext context) {
    if (GoRouter.of(context).canPop()) {
      GoRouter.of(context).pop();
    } else {
      context.go('/');
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation:       0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.kTextPrimary),
        onPressed: () => _goBack(context),
      ),
      title: subtitle != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize:   17,
                    fontWeight: FontWeight.w900,
                    color:      AppColors.kTextPrimary,
                  ),
                ),
                Text(
                  subtitle!,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.kTextMuted),
                ),
              ],
            )
          : Text(
              title,
              style: const TextStyle(
                fontSize:   17,
                fontWeight: FontWeight.w900,
                color:      AppColors.kTextPrimary,
              ),
            ),
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.kCardBorder),
      ),
    );
  }
}

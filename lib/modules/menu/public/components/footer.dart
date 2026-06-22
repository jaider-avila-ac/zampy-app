import 'package:flutter/material.dart' hide MenuTheme;
import '../models/public_menu_model.dart';

// Equivalente a src/components/Footer.jsx en React

class MenuFooter extends StatelessWidget {
  const MenuFooter({super.key, required this.theme});
  final MenuTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Divider(color: theme.border),
          const SizedBox(height: 16),
          Text(
            'Menú digital creado con',
            style: TextStyle(fontSize: 11, color: theme.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            'Zammpy',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: theme.primary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'zammpy.com',
            style: TextStyle(fontSize: 11, color: theme.textMuted),
          ),
        ],
      ),
    );
  }
}

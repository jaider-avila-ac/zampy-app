import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/app_colors.dart';

// Barra de pestañas del editor del menú, como el MenuEditorLayout de React: las secciones se ven juntas
// (Grupos de opciones · Plan y visibilidad · Colaboradores · Mesas · Pedidos) pero cada una tiene su propio
// link; al tocar una se navega a su ruta. Se usa en el editor en vivo, en Mesas y en Pedidos.
class EditorTabsBar extends StatelessWidget {
  const EditorTabsBar({
    super.key,
    required this.codigo,
    required this.active,
    this.esPropio = true,
    this.onEditorTab,
  });

  final String codigo;

  /// 'groups' | 'publish' | 'collaborators' | 'mesas' | 'pedidos'
  final String active;
  final bool esPropio;

  /// Dentro del editor en vivo: cambiar entre las 3 secciones del editor sin recargar el menú
  /// (grupos/publish/collaborators). Si es null (Mesas/Pedidos), esas pestañas navegan al editor.
  final void Function(String id)? onEditorTab;

  static const _tabs = [
    ('groups', 'Grupos de opciones', '/edit?tab=groups'),
    ('publish', 'Plan y visibilidad', '/edit?tab=publish'),
    ('collaborators', 'Colaboradores', '/edit?tab=collaborators'),
    ('mesas', 'Mesas', '/mesas'),
    ('pedidos', 'Pedidos', '/pedidos'),
  ];

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs.where((t) => t.$1 != 'collaborators' || esPropio).toList();
    return Material(
      color: Colors.white,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.kCardBorder)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              for (final (id, label, path) in tabs)
                _TabItem(
                  label: label,
                  selected: id == active,
                  onTap: id == active
                      ? null
                      : () {
                          final esEditor = id == 'groups' || id == 'publish' || id == 'collaborators';
                          if (esEditor && onEditorTab != null) {
                            onEditorTab!(id);
                          } else {
                            context.go('/menus/$codigo$path');
                          }
                        },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.kBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.kBlue : AppColors.kTextSecondary,
          ),
        ),
      ),
    );
  }
}

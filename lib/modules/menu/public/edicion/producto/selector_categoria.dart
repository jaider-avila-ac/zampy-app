import 'package:flutter/material.dart';

import '../../models/public_menu_model.dart';

/// Elegir la categoría del producto (equivale al Select de categorías de los formularios de React).
class SelectorCategoria extends StatelessWidget {
  const SelectorCategoria({super.key, required this.categorias, required this.valor, required this.onChanged});

  final List<MenuCategory> categorias;
  final String? valor;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DropdownButtonFormField<String>(
          initialValue: valor,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Categoría',
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: [for (final c in categorias) DropdownMenuItem(value: c.id, child: Text(c.name))],
          onChanged: onChanged,
        ),
      );
}

import 'package:flutter/material.dart';

import '../../../data/category_icons.dart';
import '../../../shared/app_colors.dart';
import '../models/explore_models.dart';

// Equivalente a src/modules/explore/components/Filtros.jsx en React

class Filtros extends StatelessWidget {
  const Filtros({
    super.key,
    required this.filtros,
    required this.municipio,
    required this.categoria,
    required this.onMunicipio,
    required this.onCategoria,
  });

  final ExploreFiltros? filtros;
  final String? municipio;
  final String? categoria;
  final ValueChanged<String?> onMunicipio;
  final ValueChanged<String?> onCategoria;

  @override
  Widget build(BuildContext context) {
    final data = filtros;
    if (data == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 15,
              color: AppColors.kBlueLight,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kCardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: municipio ?? '',
                    isExpanded: true,
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.kTextPrimary,
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('Todos los lugares'),
                      ),
                      ...data.lugares.map(
                        (lugar) => DropdownMenuItem(
                          value: lugar.codigo,
                          child: Text(
                            lugar.detalle == null || lugar.detalle!.isEmpty
                                ? lugar.nombre
                                : '${lugar.nombre} · ${lugar.detalle}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) => onMunicipio(
                      value == null || value.isEmpty ? null : value,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _Chip(
                activo: categoria == null,
                onTap: () => onCategoria(null),
                label: 'Todo',
              ),
              ...data.categorias.map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _Chip(
                    activo: categoria == cat.codigo,
                    onTap: () => onCategoria(
                      categoria == cat.codigo ? null : cat.codigo,
                    ),
                    label: cat.nombre,
                    icon: categoryIcon(cat.detalle),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.activo,
    required this.onTap,
    required this.label,
    this.icon,
  });

  final bool activo;
  final VoidCallback onTap;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: activo ? AppColors.kBlue : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: activo ? AppColors.kBlue : AppColors.kCardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: activo ? Colors.white : AppColors.kTextSecondary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: activo ? Colors.white : AppColors.kTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

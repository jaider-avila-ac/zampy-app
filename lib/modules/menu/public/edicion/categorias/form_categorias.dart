import 'package:flutter/material.dart';

import '../../../../../shared/app_colors.dart';
import '../comun/guardar.dart';
import 'categorias_edicion.dart';
import 'fila_categoria.dart';
import 'nueva_categoria.dart';

// Equivalente a src/modules/menu/public/edicion/categorias/FormCategorias.jsx en React.

/// Categorías en el propio menú: la lista (con su orden sin guardar) y crear una nueva.
class FormCategorias extends StatefulWidget {
  const FormCategorias({super.key, required this.menuCodigo, required this.onCambio});

  final String menuCodigo;
  final Future<void> Function() onCambio;

  @override
  State<FormCategorias> createState() => _FormCategoriasState();
}

class _FormCategoriasState extends State<FormCategorias> {
  late final CategoriasEdicion _c = CategoriasEdicion(
    menuCodigo: widget.menuCodigo,
    onCambio: widget.onCambio,
    avisar: (m, {error = false}) {
      if (mounted) avisar(context, m, error: error);
    },
  )..addListener(_refrescar);

  void _refrescar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_refrescar);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lista = _c.lista;
    if (lista == null) {
      if (_c.errorCarga) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              const Text('No se pudieron cargar las categorías.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.kTextSecondary)),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _c.recargar,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        );
      }
      return cargandoPanel;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (lista.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('Aún no tienes categorías. Crea la primera abajo.',
                style: TextStyle(fontSize: 13, color: AppColors.kTextSecondary)),
          ),
        for (var i = 0; i < lista.length; i++)
          FilaCategoria(key: ValueKey(lista[i].codigo), cat: lista[i], i: i, total: lista.length, c: _c),
        if (_c.ordenCambiado)
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.kCardBorder),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Expanded(child: Text('Cambiaste el orden de las categorías.', style: TextStyle(fontSize: 13))),
                TextButton.icon(
                  onPressed: _c.ocupado != null ? null : _c.deshacerOrden,
                  icon: const Icon(Icons.undo, size: 16),
                  label: const Text('Deshacer'),
                ),
                FilledButton.icon(
                  onPressed: _c.ocupado != null ? null : _c.guardarOrden,
                  icon: _c.ocupado == 'orden'
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check, size: 16),
                  label: const Text('Guardar orden'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        NuevaCategoria(onCrear: _c.crear, creando: _c.ocupado == 'nueva', bloqueado: _c.bloqueado),
      ],
    );
  }
}

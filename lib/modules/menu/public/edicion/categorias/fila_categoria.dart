import 'package:flutter/material.dart';

import '../../../../../shared/app_colors.dart';
import '../../../editor/live/editor_models.dart';
import 'categorias_edicion.dart';

// Equivalente a src/modules/menu/public/edicion/categorias/FilaCategoria.jsx en React.

/// Una categoría en la lista: subir o bajar, renombrar en el sitio, mostrar u ocultar y eliminar.
class FilaCategoria extends StatefulWidget {
  const FilaCategoria({super.key, required this.cat, required this.i, required this.total, required this.c});

  final LiveCategory cat;
  final int i;
  final int total;
  final CategoriasEdicion c;

  @override
  State<FilaCategoria> createState() => _FilaCategoriaState();
}

class _FilaCategoriaState extends State<FilaCategoria> {
  late final _nombre = TextEditingController(text: widget.c.nombreDe(widget.cat));

  @override
  void didUpdateWidget(covariant FilaCategoria old) {
    super.didUpdateWidget(old);
    final actual = widget.c.nombreDe(widget.cat);
    if (_nombre.text != actual) _nombre.text = actual;
  }

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _eliminar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text('¿Eliminar "${widget.cat.name}" y sus productos? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.kRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok == true) widget.c.eliminar(widget.cat);
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.cat;
    final c = widget.c;
    final oculta = !cat.isVisible;
    final conFotos = cat.tipoContenido != 'sin_imagenes';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: oculta ? const Color(0xFFF1F5F9) : Colors.white,
        border: Border.all(color: AppColors.kCardBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Flecha(icono: Icons.keyboard_arrow_up, onTap: widget.i == 0 || c.ocupado != null ? null : () => c.mover(widget.i, -1)),
              _Flecha(
                icono: Icons.keyboard_arrow_down,
                onTap: widget.i == widget.total - 1 || c.ocupado != null ? null : () => c.mover(widget.i, 1),
              ),
            ],
          ),
          Tooltip(
            message: conFotos ? 'Productos con foto' : 'Solo texto',
            child: Icon(conFotos ? Icons.image_outlined : Icons.text_fields, size: 16, color: AppColors.kTextMuted),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _nombre,
              maxLength: 50,
              onChanged: (v) => c.editarNombre(cat, v),
              onSubmitted: (_) => c.renombrar(cat),
              style: TextStyle(fontSize: 14, color: oculta ? AppColors.kTextMuted : AppColors.kTextPrimary),
              decoration: const InputDecoration(counterText: '', isDense: true, border: InputBorder.none),
            ),
          ),
          if (c.nombreEditado(cat))
            IconButton(
              tooltip: 'Guardar nombre',
              onPressed: () => c.renombrar(cat),
              icon: const Icon(Icons.check, size: 18, color: AppColors.kBlue),
            ),
          if (c.ocupado == cat.codigo)
            const Padding(
              padding: EdgeInsets.all(10),
              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else ...[
            IconButton(
              tooltip: oculta ? 'Mostrar en el menú' : 'Ocultar del menú',
              onPressed: c.bloqueado ? null : () => c.alternarVisible(cat),
              icon: Icon(oculta ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
            ),
            IconButton(
              tooltip: 'Eliminar',
              onPressed: c.bloqueado ? null : _eliminar,
              icon: const Icon(Icons.delete_outline, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

class _Flecha extends StatelessWidget {
  const _Flecha({required this.icono, required this.onTap});
  final IconData icono;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Icon(icono, size: 20, color: onTap == null ? const Color(0xFFCBD5E1) : AppColors.kTextSecondary),
      );
}

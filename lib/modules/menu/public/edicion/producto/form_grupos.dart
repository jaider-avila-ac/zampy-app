import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../services/live_editor_service.dart';
import '../../../../../shared/app_colors.dart';
import '../../../editor/live/editor_models.dart';
import '../../models/public_menu_model.dart';
import '../comun/guardar.dart';

// Equivalente a src/modules/menu/public/edicion/producto/FormGrupos.jsx en React.

/// Los grupos de opciones del menú que aplican al producto (se crean una vez y se usan en varios productos).
class FormGrupos extends StatefulWidget {
  const FormGrupos({super.key, required this.menuCodigo, required this.producto, required this.onListo});

  final String menuCodigo;
  final MenuProduct producto;
  final Future<void> Function() onListo;

  @override
  State<FormGrupos> createState() => _FormGruposState();
}

class _FormGruposState extends State<FormGrupos> with GuardarSeccion {
  List<LiveGroup>? _grupos;
  late final Set<String> _elegidos = {...widget.producto.grupoIds};

  @override
  void initState() {
    super.initState();
    LiveEditorService.load(widget.menuCodigo)
        .then((m) => m.groups)
        .catchError((_) => <LiveGroup>[])
        .then((g) {
      if (mounted) setState(() => _grupos = g);
    });
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _grupos;
    if (grupos == null) return cargandoPanel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Los grupos son opciones que el cliente elige (salsas, acompañantes, bebidas…). '
          'Se crean una vez y se usan en varios productos.',
          style: TextStyle(fontSize: 13, color: AppColors.kTextSecondary),
        ),
        const SizedBox(height: 10),
        if (grupos.isEmpty) const Text('Aún no tienes grupos.', style: TextStyle(fontSize: 13)),
        for (final g in grupos)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _elegidos.contains(g.codigo),
            onChanged: (v) => setState(() => v == true ? _elegidos.add(g.codigo) : _elegidos.remove(g.codigo)),
            title: Text(g.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            secondary: Text('${g.items.length} opciones', style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/menus/${widget.menuCodigo}/edit?tab=groups');
            },
            child: const Text('Crear o editar grupos'),
          ),
        ),
        const SizedBox(height: 8),
        BotonGuardar(
          guardando: guardando,
          onPressed: () => guardar(
            () => LiveEditorService.updateProductPart(widget.menuCodigo, widget.producto.id, 'grupos', [..._elegidos]),
            onListo: widget.onListo,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../../shared/app_colors.dart';
import '../comun/guardar.dart';

// Equivalente a src/modules/menu/public/edicion/categorias/NuevaCategoria.jsx en React.

/// Crear una categoría: nombre y si sus productos llevan foto.
class NuevaCategoria extends StatefulWidget {
  const NuevaCategoria({super.key, required this.onCrear, required this.creando, required this.bloqueado});

  /// Devuelve true si se creó.
  final Future<bool> Function(String nombre, String tipo) onCrear;
  final bool creando;
  final bool bloqueado;

  @override
  State<NuevaCategoria> createState() => _NuevaCategoriaState();
}

class _NuevaCategoriaState extends State<NuevaCategoria> {
  final _nombre = TextEditingController();
  String _tipo = 'con_imagenes';

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (await widget.onCrear(_nombre.text, _tipo)) _nombre.clear();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.kCardBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nueva categoría', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            CampoTexto(etiqueta: 'Nombre', hint: 'Ej: Hamburguesas', controller: _nombre, maxLength: 50,
                onChanged: (_) => setState(() {})),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'con_imagenes', icon: Icon(Icons.image_outlined, size: 16), label: Text('Con fotos')),
                ButtonSegment(value: 'sin_imagenes', icon: Icon(Icons.text_fields, size: 16), label: Text('Solo texto')),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
            const SizedBox(height: 12),
            BotonGuardar(
              texto: 'Crear categoría',
              guardando: widget.creando,
              onPressed: _nombre.text.trim().isEmpty || widget.bloqueado ? null : _crear,
            ),
          ],
        ),
      );
}

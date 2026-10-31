import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../shared/location_cascade_input.dart';
import '../../../../../shared/telefono_input.dart';
import '../../models/public_menu_model.dart';
import '../comun/guardar.dart';
import 'informacion_negocio.dart';

// Equivalente a src/modules/menu/public/edicion/negocio/FormInformacion.jsx en React.

/// Todo el bloque de datos del menú en un solo formulario (ver InformacionNegocio).
class FormInformacion extends StatefulWidget {
  const FormInformacion({
    super.key,
    required this.menuCodigo,
    required this.info,
    this.categoriaCodigo,
    required this.onListo,
  });

  final String menuCodigo;
  final MenuInfo info;
  final String? categoriaCodigo;
  final Future<void> Function() onListo;

  @override
  State<FormInformacion> createState() => _FormInformacionState();
}

class _FormInformacionState extends State<FormInformacion> with GuardarSeccion {
  late final InformacionNegocio _f = InformacionNegocio(
    menuCodigo: widget.menuCodigo,
    info: widget.info,
    categoriaCodigo: widget.categoriaCodigo,
  )..addListener(_refrescar);

  void _refrescar() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _f.removeListener(_refrescar);
    _f.dispose();
    super.dispose();
  }

  Future<void> _agregarFotos() async {
    final fotos = await ImagePicker().pickMultiImage(imageQuality: 85);
    if (fotos.isNotEmpty) _f.agregarFotos([for (final x in fotos) File(x.path)]);
  }

  CampoTexto _campo(String campo, String etiqueta, {String? hint, int? max, bool requerido = false}) => CampoTexto(
        etiqueta: etiqueta,
        controller: _f.campos[campo]!,
        hint: hint,
        maxLength: max,
        requerido: requerido,
        onChanged: (_) => _f.cambioTexto(),
      );

  @override
  Widget build(BuildContext context) {
    final pais = _f.ubicacion.paisCodigo ?? 'CO';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloBloque('Tu negocio'),
        _campo('name', 'Nombre del negocio', max: 35, requerido: true),
        _campo('slogan', 'Eslogan', max: 70, hint: 'Ej: La pizza más auténtica de la ciudad'),
        DropdownButtonFormField<String>(
          key: ValueKey('cat-${_f.categoriasNegocio.length}'),
          initialValue: _f.categoria.isEmpty ? null : _f.categoria,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Categoría del negocio',
            helperText: 'Así te encuentran en Explorar.',
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: [
            for (final c in _f.categoriasNegocio) DropdownMenuItem(value: c.codigo, child: Text(c.nombre)),
          ],
          onChanged: _f.setCategoria,
        ),
        const TituloBloque('Ubicación'),
        LocationCascadeInput(value: _f.ubicacion, onChange: _f.setUbicacion),
        const TituloBloque('Galería'),
        _Galeria(fotos: _f.galeria, onQuitar: _f.quitarFoto, onAgregar: _agregarFotos),
        const TituloBloque('Contacto'),
        TelefonoInput(
          label: 'WhatsApp',
          value: _f.valor('whatsapp'),
          paisDefecto: pais,
          onChanged: (v) {
            _f.campos['whatsapp']!.text = v;
            _f.cambioTexto();
          },
        ),
        const SizedBox(height: 12),
        TelefonoInput(
          label: 'Teléfono',
          value: _f.valor('phone'),
          paisDefecto: pais,
          onChanged: (v) {
            _f.campos['phone']!.text = v;
            _f.cambioTexto();
          },
        ),
        const SizedBox(height: 12),
        _campo('email', 'Correo comercial', max: 320),
        const TituloBloque('Redes sociales'),
        _campo('instagram', 'Instagram', hint: 'usuario', max: 100),
        _campo('facebook', 'Facebook', hint: 'usuario o página', max: 100),
        _campo('tiktok', 'TikTok', hint: 'usuario', max: 100),
        _campo('website', 'Sitio web', hint: 'https://…', max: 255),
        const SizedBox(height: 8),
        BotonGuardar(
          texto: 'Guardar información',
          guardando: guardando,
          onPressed: _f.puedeGuardar
              ? () => guardar(_f.guardar, onListo: widget.onListo, mensaje: 'Información guardada')
              : null,
        ),
      ],
    );
  }
}

class _Galeria extends StatelessWidget {
  const _Galeria({required this.fotos, required this.onQuitar, required this.onAgregar});
  final List<FotoGaleria> fotos;
  final ValueChanged<int> onQuitar;
  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (fotos.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < fotos.length; i++)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 84,
                          height: 84,
                          child: fotos[i].archivo != null
                              ? Image.file(fotos[i].archivo!, fit: BoxFit.cover)
                              : Image.network(fotos[i].url!, fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFFF1F5F9))),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: InkWell(
                          onTap: () => onQuitar(i),
                          child: const CircleAvatar(
                            radius: 11,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 13, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onAgregar,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 16),
            label: const Text('Agregar fotos'),
          ),
        ],
      );
}

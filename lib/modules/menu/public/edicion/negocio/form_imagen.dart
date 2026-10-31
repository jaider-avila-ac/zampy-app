import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../services/image_upload_service.dart';
import '../../../../../services/live_editor_service.dart';
import '../../../../../shared/app_colors.dart';
import '../../../../../shared/logo_crop_dialog.dart';
import '../comun/guardar.dart';
import 'imagenes.dart';

// Equivalente a src/modules/menu/public/edicion/negocio/FormImagen.jsx en React.

/// Cambiar el logo o la portada (seccion: logo | portada). La imagen se sube al guardar.
class FormImagen extends StatefulWidget {
  const FormImagen({super.key, required this.menuCodigo, required this.seccion, this.valor, required this.onListo});

  final String menuCodigo;
  final String seccion;
  final String? valor;
  final Future<void> Function() onListo;

  @override
  State<FormImagen> createState() => _FormImagenState();
}

class _FormImagenState extends State<FormImagen> with GuardarSeccion {
  File? _nueva;
  String? _error;

  ImagenEncabezado get _imagen => imagenesEncabezado[widget.seccion]!;

  Future<void> _elegir() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (x == null || !mounted) return;
    var file = File(x.path);
    final invalida = ImageUploadService.validate(file);
    if (invalida != null) {
      setState(() => _error = invalida);
      return;
    }
    if (_imagen.recortarCuadrado) {
      final recortada = await showLogoCropDialog(context, file);
      if (recortada == null) return;
      file = recortada;
    }
    setState(() {
      _nueva = file;
      _error = null;
    });
  }

  Future<void> _guardar() => guardar(
        () async {
          final url = await ImageUploadService.upload(_nueva!, 'menus/${widget.menuCodigo}/${_imagen.carpeta}');
          await LiveEditorService.saveSection(widget.menuCodigo, widget.seccion, {_imagen.campo: url});
        },
        onListo: widget.onListo,
      );

  @override
  Widget build(BuildContext context) {
    final cuadrado = _imagen.recortarCuadrado;
    final vista = _nueva != null
        ? Image.file(_nueva!, fit: BoxFit.cover)
        : (widget.valor?.isNotEmpty ?? false)
            ? Image.network(widget.valor!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const _SinImagen())
            : const _SinImagen();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_imagen.etiqueta, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cuadrado ? 999 : 12),
            child: SizedBox(
              width: cuadrado ? 140 : double.infinity,
              child: AspectRatio(aspectRatio: cuadrado ? 1 : 3, child: vista),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: guardando ? null : _elegir,
          icon: const Icon(Icons.photo_library_outlined, size: 16),
          label: Text(_nueva == null ? 'Elegir imagen' : 'Elegir otra'),
        ),
        Text(_imagen.ayuda, style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.kRed)),
          ),
        const SizedBox(height: 16),
        BotonGuardar(guardando: guardando, onPressed: _nueva == null ? null : _guardar),
      ],
    );
  }
}

class _SinImagen extends StatelessWidget {
  const _SinImagen();

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFF1F5F9),
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: Color(0xFFCBD5E1), size: 32),
      );
}

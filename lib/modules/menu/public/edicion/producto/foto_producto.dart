import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../services/image_upload_service.dart';
import '../../../../../shared/app_colors.dart';
import 'ajustar_foto.dart';

// Equivalente a src/modules/menu/public/edicion/producto/FotoProducto.jsx en React.

/// La foto del producto en un formulario: la ya guardada (url) o una nueva (se sube al guardar), con su posición.
class FotoElegida {
  const FotoElegida({this.url, this.archivo, this.posicion = const Offset(50, 50)});
  final String? url;
  final File? archivo;
  final Offset posicion;

  bool get vacia => archivo == null && (url == null || url!.isEmpty);

  /// La url final: sube la foto nueva o devuelve la que ya estaba.
  Future<String?> resolver(String carpeta) async =>
      archivo != null ? ImageUploadService.upload(archivo!, carpeta) : url;
}

/// Sin foto, el botón para subirla; con foto, ajustar qué parte se ve en la tarjeta, cambiarla o quitarla.
class FotoProducto extends StatefulWidget {
  const FotoProducto({super.key, required this.foto, required this.onCambio, this.ayuda});

  final FotoElegida foto;
  final ValueChanged<FotoElegida> onCambio;
  final String? ayuda;

  @override
  State<FotoProducto> createState() => _FotoProductoState();
}

class _FotoProductoState extends State<FotoProducto> {
  String? _error;

  Future<void> _elegir() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (x == null) return;
    final file = File(x.path);
    final invalida = ImageUploadService.validate(file);
    setState(() => _error = invalida);
    if (invalida == null) widget.onCambio(FotoElegida(archivo: file));
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.foto;
    final contenido = f.vacia
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: _elegir,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: const Text('Subir foto del producto'),
              ),
              if (widget.ayuda != null)
                Text(widget.ayuda!, style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
            ],
          )
        : AjustarFoto(
            url: f.url,
            archivo: f.archivo,
            posicion: f.posicion,
            onPosicion: (p) => widget.onCambio(FotoElegida(url: f.url, archivo: f.archivo, posicion: p)),
            onCambiar: _elegir,
            onQuitar: () => widget.onCambio(const FotoElegida()),
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          contenido,
          if (_error != null) Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.kRed)),
        ],
      ),
    );
  }
}

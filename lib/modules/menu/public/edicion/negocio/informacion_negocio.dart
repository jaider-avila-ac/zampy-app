import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../services/image_upload_service.dart';
import '../../../../../services/live_editor_service.dart';
import '../../../../../services/public_api_service.dart';
import '../../../../../shared/location_cascade_input.dart';
import '../../../create/models/create_menu_models.dart';
import '../../models/public_menu_model.dart';

// Equivalente a src/modules/menu/public/edicion/negocio/useInformacionNegocio.js en React.

/// Una foto de la galería: ya subida (url) o nueva (se sube al guardar, como el logo y la portada).
class FotoGaleria {
  const FotoGaleria.url(String this.url) : archivo = null;
  const FotoGaleria.nueva(File this.archivo) : url = null;
  final String? url;
  final File? archivo;
}

/// La información del negocio como "editar información" de un perfil: nombre y eslogan, categoría, ubicación, galería,
/// contacto y redes en un solo formulario. Al guardar se envía solo cada parte que cambió, con su propia sección.
class InformacionNegocio extends ChangeNotifier {
  InformacionNegocio({required this.menuCodigo, required MenuInfo info, String? categoriaCodigo})
      : _info = info,
        _categoriaInicial = categoriaCodigo ?? '',
        categoria = categoriaCodigo ?? '',
        galeria = [for (final u in info.galeria) FotoGaleria.url(u)],
        ubicacion = LocationCascadeValue.fromUbicacion(
          info.ubicacion == null ? null : _ubicacionJson(info.ubicacion!),
          address: info.address ?? '',
        ) {
    for (final e in _iniciales.entries) {
      campos[e.key] = TextEditingController(text: e.value);
    }
    PublicApiService.listarCategorias().then((cs) {
      categoriasNegocio = cs;
      notifyListeners();
    }).catchError((_) {});
  }

  final String menuCodigo;
  final MenuInfo _info;
  final String _categoriaInicial;

  final Map<String, TextEditingController> campos = {};
  String categoria;
  List<CategoriaRestaurante> categoriasNegocio = const [];
  List<FotoGaleria> galeria;
  LocationCascadeValue ubicacion;

  Map<String, String> get _iniciales => {
        'name': _info.name,
        'slogan': _info.slogan ?? '',
        'phone': _info.phone ?? '',
        'whatsapp': _info.whatsapp ?? '',
        'email': _info.email ?? '',
        'instagram': _info.instagram ?? '',
        'facebook': _info.facebook ?? '',
        'tiktok': _info.tiktok ?? '',
        'website': _info.website ?? '',
      };

  static Map<String, dynamic> _ubicacionJson(MenuUbicacion u) => {
        'paisCodigo': u.paisCodigo,
        'divisionCodigo': u.divisionCodigo,
        'divisionTipo': u.divisionTipo,
        'municipioCodigo': u.municipioCodigo,
        'municipio': u.municipio,
      };

  String valor(String campo) => campos[campo]!.text.trim();
  bool _cambio(List<String> nombres) => nombres.any((c) => valor(c) != (_iniciales[c] ?? '').trim());

  bool get _galeriaCambio =>
      galeria.length != _info.galeria.length ||
      galeria.any((f) => f.archivo != null) ||
      [for (var i = 0; i < galeria.length; i++) galeria[i].url != _info.galeria[i]].any((d) => d);

  bool get _ubicacionCambio =>
      ubicacion.municipioCodigo != _info.ubicacion?.municipioCodigo || ubicacion.address != (_info.address ?? '');

  /// Sin nombre no se guarda, ni con un municipio escrito que no se eligió de la lista.
  bool get puedeGuardar => valor('name').isNotEmpty && !(ubicacion.municipio.isNotEmpty && !ubicacion.hasMunicipio);

  void setCategoria(String? c) {
    categoria = c ?? '';
    notifyListeners();
  }

  void setUbicacion(LocationCascadeValue v) {
    ubicacion = v;
    notifyListeners();
  }

  void agregarFotos(List<File> archivos) {
    galeria = [...galeria, for (final a in archivos) FotoGaleria.nueva(a)];
    notifyListeners();
  }

  void quitarFoto(int i) {
    galeria = [...galeria]..removeAt(i);
    notifyListeners();
  }

  void cambioTexto() => notifyListeners();

  Future<void> guardar() async {
    Future<void> seccion(String s, Map<String, dynamic> body) => LiveEditorService.saveSection(menuCodigo, s, body);
    if (categoria.isNotEmpty && categoria != _categoriaInicial) {
      await seccion('categoria', {'restaurantCategoryCode': categoria});
    }
    if (_cambio(['name', 'slogan'])) {
      await seccion('identidad', {'name': valor('name'), 'slogan': valor('slogan')});
    }
    if (_galeriaCambio) {
      final urls = [
        for (final f in galeria)
          f.url ?? await ImageUploadService.upload(f.archivo!, 'menus/$menuCodigo/galeria'),
      ];
      await seccion('galeria', {'galeria': urls});
    }
    if (_cambio(['phone', 'whatsapp', 'email'])) {
      await seccion('contacto', {'phone': valor('phone'), 'whatsapp': valor('whatsapp'), 'email': valor('email')});
    }
    if (_ubicacionCambio) {
      await seccion('ubicacion', {'municipioCodigo': ubicacion.municipioCodigo, 'address': ubicacion.address});
    }
    if (_cambio(['instagram', 'facebook', 'tiktok', 'website'])) {
      await seccion('redes', {
        'instagram': valor('instagram'),
        'facebook': valor('facebook'),
        'tiktok': valor('tiktok'),
        'website': valor('website'),
      });
    }
  }

  @override
  void dispose() {
    for (final c in campos.values) {
      c.dispose();
    }
    super.dispose();
  }
}

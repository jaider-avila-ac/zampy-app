import 'package:flutter/material.dart' hide MenuTheme;

import '../../../../components/menu_page.dart';
import '../../../../services/themes_catalog_service.dart';
import '../models/public_menu_model.dart';
import 'cabecera/menu_hamburguesa.dart';
import 'edicion_menu.dart';
import 'panel/panel_edicion.dart';
import 'panel/secciones.dart';
import 'tema/prueba_tema.dart';
import 'tema/tema_elegido.dart';

// Equivalente a src/modules/menu/public/edicion/MenuEditable.jsx en React.

/// El menú tal como lo ve el cliente, en su mismo enlace (/menu/:slug). Lo único distinto para el dueño o el editor
/// (lo decide el backend, GET /menus/acceso) son las opciones de edición: el menú de la cabecera, tocar la portada o el
/// logo, y el "⋯" de cada producto.
/// seccionInicial: `?editar=sección` la abre al llegar (desde "Completa tu menú")
class MenuEditable extends StatefulWidget {
  const MenuEditable({
    super.key,
    required this.menuData,
    required this.menuCodigo,
    required this.publicado,
    required this.esPropio,
    required this.recargar,
    required this.onEstado,
    this.seccionInicial,
    this.initialProductId,
  });

  final PublicMenuData menuData;
  final String menuCodigo;
  final bool publicado;
  final bool esPropio;
  final Future<void> Function() recargar;
  final Future<void> Function() onEstado;
  final String? seccionInicial;
  final String? initialProductId;

  @override
  State<MenuEditable> createState() => _MenuEditableState();
}

class _MenuEditableState extends State<MenuEditable> {
  List<CatalogSkin> _catalogo = const [];
  // el tema que se está probando sobre el menú (sin guardar) mientras el dueño decide
  TemaElegido? _prueba;
  bool _temaAbierto = false;

  TemaElegido get _guardado => TemaElegido(widget.menuData.design?.skinId, widget.menuData.design?.paletteId);

  @override
  void initState() {
    super.initState();
    ThemesCatalogService.load().then((c) {
      if (mounted) setState(() => _catalogo = c);
    });
    final inicial = widget.seccionInicial;
    if (inicial != null && seccionesDeEnlace.contains(inicial)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _abrir(inicial);
      });
    }
  }

  void _probar(TemaElegido t) => setState(() => _prueba = t.igualA(_guardado) ? null : t);

  String _nombreTema(TemaElegido t) {
    final skin = _catalogo.where((s) => '${s.id}' == '${t.skin}').firstOrNull;
    final paleta = skin?.palettes.where((p) => '${p.id}' == '${t.paleta}').firstOrNull;
    return [skin?.label, paleta?.name].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
  }

  Future<void> _abrir(String seccion, [Object? datos]) async {
    final esTema = seccion == 'tema';
    if (esTema) setState(() => _temaAbierto = true);
    await abrirPanelEdicion(
      context,
      seccion: seccion,
      datos: datos,
      menuCodigo: widget.menuCodigo,
      menu: widget.menuData,
      onRecargar: widget.recargar,
      tema: TemaPanel(actual: _prueba ?? _guardado, guardado: _guardado, onElegir: _probar),
    );
    if (esTema && mounted) setState(() => _temaAbierto = false);
  }

  @override
  Widget build(BuildContext context) {
    final prueba = _prueba;
    final data = prueba == null || _catalogo.isEmpty
        ? widget.menuData
        : widget.menuData.copyWithTheme(ThemesCatalogService.resolveTheme(_catalogo, prueba.skin, prueba.paleta));

    return Column(
      children: [
        Expanded(
          child: EdicionMenu(
            abrir: _abrir,
            menuCodigo: widget.menuCodigo,
            recargar: widget.recargar,
            encabezado: MenuHamburguesa(
              menuCodigo: widget.menuCodigo,
              publicado: widget.publicado,
              esPropio: widget.esPropio,
              abrir: _abrir,
              onEstado: widget.onEstado,
              color: data.theme.navText,
            ),
            // el dueño lo ve igual que el cliente (QR, carrito y pedidos si está publicado); solo se suman las
            // opciones de edición
            child: MenuPage(
              menuData: data,
              menuSlug: widget.menuData.slug,
              menuCodigo: widget.menuCodigo,
              isPublished: widget.publicado,
              esPropio: widget.esPropio,
              initialProductId: widget.initialProductId,
            ),
          ),
        ),
        if (prueba != null && !_temaAbierto)
          PruebaTema(
            menuCodigo: widget.menuCodigo,
            tema: prueba,
            nombre: _nombreTema(prueba),
            onVolver: () => setState(() => _prueba = null),
            onElegirOtro: () => _abrir('tema'),
            onGuardado: () async {
              await widget.recargar();
              if (mounted) setState(() => _prueba = null);
            },
          ),
      ],
    );
  }
}

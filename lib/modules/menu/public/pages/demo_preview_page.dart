import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../hooks/use_public_menu.dart';
import '../components/theme_selector.dart';
import '../models/public_menu_model.dart';
import '../../../../components/menu_page.dart';
import '../../../../services/themes_catalog_service.dart';
import '../../../../shared/app_colors.dart';

// Equivalente a src/pages/DemoPreviewPage.jsx en React
// Muestra el menú demo con ThemeSelector para cambiar skin/paleta en vivo

class DemoPreviewPage extends StatelessWidget {
  const DemoPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UsePublicMenu()..load(isDemo: true),
      child: const _DemoView(),
    );
  }
}

class _DemoView extends StatefulWidget {
  const _DemoView();

  @override
  State<_DemoView> createState() => _DemoViewState();
}

class _DemoViewState extends State<_DemoView> {
  List<CatalogSkin> _catalog   = [];
  dynamic           _skinId;
  dynamic           _paletteId;

  // menuData con el tema actualmente seleccionado
  PublicMenuData? _effectiveMenu(PublicMenuData base) {
    if (_catalog.isEmpty) return base;
    if (_skinId == null && _paletteId == null) return base;
    final theme = ThemesCatalogService.resolveTheme(_catalog, _skinId, _paletteId);
    return base.copyWithTheme(theme);
  }

  void _onSkinChange(CatalogSkin sk) {
    final firstPalette = sk.palettes.isNotEmpty ? sk.palettes.first.id : null;
    setState(() {
      _skinId    = sk.id;
      _paletteId = firstPalette;
    });
  }

  void _onPaletteChange(CatalogPalette pal) {
    setState(() => _paletteId = pal.id);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<UsePublicMenu>();

    if (ctrl.loading) {
      return const Scaffold(
        backgroundColor: AppColors.kBgPage,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (ctrl.menuData == null) {
      return const Scaffold(
        backgroundColor: AppColors.kBgPage,
        body: Center(child: Text('Error al cargar demo')),
      );
    }

    // Carga el catálogo si aún no está disponible
    if (_catalog.isEmpty) {
      ThemesCatalogService.load().then((cat) {
        if (!mounted) return;
        final base = ctrl.menuData!;
        setState(() {
          _catalog   = cat;
          _skinId    = base.design?.skinId;
          _paletteId = base.design?.paletteId;
        });
      });
    }

    final base      = ctrl.menuData!;
    final menuData  = _effectiveMenu(base) ?? base;
    final theme     = menuData.theme;

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Banner "DEMO" + botón cerrar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: const Color(0xFF7C3AED),
                  child: Row(
                    children: [
                      const Icon(Icons.visibility, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Vista previa del menú demo',
                          style: TextStyle(
                            color:      Colors.white,
                            fontSize:   12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: const Icon(Icons.close, size: 18, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: MenuPage(
                    menuData:    menuData,
                    isPublished: false,
                  ),
                ),
              ],
            ),

            // Botón flotante "Temas" — abre ThemeSelector como bottom sheet
            if (_catalog.isNotEmpty)
              Positioned(
                right:  16,
                bottom: 20,
                child: GestureDetector(
                  onTap: () => ThemeSelector.show(
                    context,
                    theme:           theme,
                    catalog:         _catalog,
                    currentSkinId:   _skinId ?? base.design?.skinId,
                    currentPaletteId: _paletteId ?? base.design?.paletteId,
                    onSkinChange:    _onSkinChange,
                    onPaletteChange: _onPaletteChange,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color:        theme.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color:      Colors.black.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset:     const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.palette_outlined, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Temas',
                          style: TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w700,
                            color:      Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

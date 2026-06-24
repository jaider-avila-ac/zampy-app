import 'package:flutter/material.dart' hide MenuTheme;
import '../models/public_menu_model.dart';
import '../../../../services/themes_catalog_service.dart';

// Equivalente a src/components/ThemeSelector.jsx
// Se abre como bottom sheet desde demo_preview_page.dart

class ThemeSelector extends StatefulWidget {
  const ThemeSelector({
    super.key,
    required this.theme,
    required this.catalog,
    required this.initialSkinId,
    required this.initialPaletteId,
    required this.onSkinChange,
    required this.onPaletteChange,
  });

  final MenuTheme            theme;
  final List<CatalogSkin>    catalog;
  final dynamic              initialSkinId;
  final dynamic              initialPaletteId;
  final ValueChanged<CatalogSkin>    onSkinChange;
  final ValueChanged<CatalogPalette> onPaletteChange;

  static Future<void> show(
    BuildContext context, {
    required MenuTheme theme,
    required List<CatalogSkin> catalog,
    required dynamic currentSkinId,
    required dynamic currentPaletteId,
    required ValueChanged<CatalogSkin> onSkinChange,
    required ValueChanged<CatalogPalette> onPaletteChange,
  }) {
    return showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (_) => ThemeSelector(
        theme:            theme,
        catalog:          catalog,
        initialSkinId:    currentSkinId,
        initialPaletteId: currentPaletteId,
        onSkinChange:     onSkinChange,
        onPaletteChange:  onPaletteChange,
      ),
    );
  }

  @override
  State<ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<ThemeSelector> {
  late dynamic _skinId;
  late dynamic _paletteId;

  @override
  void initState() {
    super.initState();
    _skinId    = widget.initialSkinId;
    _paletteId = widget.initialPaletteId;
  }

  CatalogSkin? get _currentSkin {
    if (widget.catalog.isEmpty) return null;
    return widget.catalog.firstWhere(
      (s) => s.id.toString() == _skinId?.toString(),
      orElse: () => widget.catalog.first,
    );
  }

  void _selectSkin(CatalogSkin sk) {
    final firstPalette = sk.palettes.isNotEmpty ? sk.palettes.first : null;
    setState(() {
      _skinId    = sk.id;
      _paletteId = firstPalette?.id;
    });
    widget.onSkinChange(sk);
    if (firstPalette != null) widget.onPaletteChange(firstPalette);
  }

  void _selectPalette(CatalogPalette pal) {
    setState(() => _paletteId = pal.id);
    widget.onPaletteChange(pal);
  }

  @override
  Widget build(BuildContext context) {
    final t    = widget.theme;
    final skin = _currentSkin;

    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color:        t.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // Drag handle
              Center(
                child: Container(
                  width:  36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color:        t.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Icon(Icons.palette_outlined, size: 18, color: t.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Preview de Diseño',
                    style: TextStyle(
                      fontSize:   17,
                      fontWeight: FontWeight.w900,
                      color:      t.text,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width:  32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:        t.surfaceAlt,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.close, size: 16, color: t.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Selector de estilo (skins)
              Text(
                'Estilo',
                style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w700,
                  color:      t.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.catalog.map((sk) {
                    final isActive = sk.id.toString() == _skinId?.toString();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _selectSkin(sk),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color:        isActive
                                ? t.primary.withValues(alpha: 0.12)
                                : Colors.transparent,
                            border: Border.all(
                              color: isActive ? t.primary : t.border,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            sk.label,
                            style: TextStyle(
                              fontSize:   12,
                              fontWeight: FontWeight.w700,
                              color:      isActive ? t.primary : t.textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Selector de paleta
              Text(
                'Paleta de colores',
                style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w700,
                  color:      t.textMuted,
                ),
              ),
              const SizedBox(height: 10),

              if (skin != null)
                GridView.builder(
                  shrinkWrap:      true,
                  physics:         const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:   2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing:  10,
                    childAspectRatio: 2.4,
                  ),
                  itemCount: skin.palettes.length,
                  itemBuilder: (_, i) {
                    final pal      = skin.palettes[i];
                    final isActive = pal.id.toString() == _paletteId?.toString();
                    return GestureDetector(
                      onTap: () => _selectPalette(pal),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color:        isActive
                              ? t.primary.withValues(alpha: 0.08)
                              : t.surfaceAlt,
                          border: Border.all(
                            color: isActive ? t.primary : t.border,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            // Swatches
                            ...pal.preview.take(3).map((hex) {
                              Color c;
                              try {
                                c = Color(int.parse(hex.replaceAll('#', '0xFF')));
                              } catch (_) {
                                c = t.primary;
                              }
                              return Container(
                                width:  16,
                                height: 16,
                                margin: const EdgeInsets.only(right: 3),
                                decoration: BoxDecoration(
                                  color:  c,
                                  shape:  BoxShape.circle,
                                  border: Border.all(color: Colors.white24, width: 0.5),
                                ),
                              );
                            }),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                pal.name,
                                style: TextStyle(
                                  fontSize:   11,
                                  fontWeight: FontWeight.w600,
                                  color:      t.text,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isActive)
                              Icon(Icons.check_circle, size: 14, color: t.primary),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 16),

              // Footer label
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:        t.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Vista previa del administrador',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w500,
                    color:      t.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

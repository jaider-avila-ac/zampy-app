import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/themes_catalog_service.dart';
import '../../../../shared/app_colors.dart';
import '../models/editor_menu_model.dart';
import '../shared/save_bar.dart';

// Equivalente a src/modules/menu/editor/DesignTab.jsx en React
// Usa el mismo layout que StepDesign.jsx: skins como lista expandible,
// paletas inline bajo el skin seleccionado, preview de color.

class DesignTab extends StatefulWidget {
  const DesignTab({
    super.key,
    required this.draft,
    required this.menuId,
    required this.onSave,
    required this.saving,
  });

  final EditorDraft draft;
  final int menuId;
  final Future<void> Function(Map<String, dynamic> patch) onSave;
  final bool saving;

  @override
  State<DesignTab> createState() => _DesignTabState();
}

class _DesignTabState extends State<DesignTab> {
  dynamic _skinId;
  dynamic _paletteId;
  bool    _dirty = false;

  List<CatalogSkin> _catalog = [];
  bool _loadingCatalog = true;

  @override
  void initState() {
    super.initState();
    _skinId    = widget.draft.design.skinId;
    _paletteId = widget.draft.design.paletteId;
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final catalog = await ThemesCatalogService.load();
    if (!mounted) return;
    setState(() { _catalog = catalog; _loadingCatalog = false; });
  }

  void _pickSkin(dynamic skinId) {
    final skin = ThemesCatalogService.findSkin(_catalog, skinId);
    setState(() {
      _skinId    = skinId;
      _paletteId = skin?.palettes.isNotEmpty == true ? skin!.palettes.first.id : null;
      _dirty = true;
    });
  }

  void _pickPalette(dynamic paletteId) {
    setState(() { _paletteId = paletteId; _dirty = true; });
  }

  Future<void> _handleSave() async {
    await widget.onSave({'design': {'skinId': _skinId, 'paletteId': _paletteId}});
    if (mounted) setState(() => _dirty = false);
  }

  CatalogSkin? get _currentSkin =>
      _skinId != null
          ? ThemesCatalogService.findSkin(_catalog, _skinId)
          : (_catalog.isNotEmpty ? _catalog.first : null);

  CatalogPalette? get _currentPalette {
    final skin = _currentSkin;
    if (skin == null) return null;
    if (_paletteId != null) {
      final found = skin.palettes
          .where((p) => p.id.toString() == _paletteId.toString())
          .cast<CatalogPalette?>()
          .firstOrNull;
      if (found != null) return found;
    }
    return skin.palettes.isNotEmpty ? skin.palettes.first : null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _loadingCatalog
              ? const Center(child: CircularProgressIndicator())
              : _catalog.isEmpty
                  ? const Center(
                      child: Text('No se pudieron cargar los estilos.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      children: [
                        // ── Sección título ─────────────────────────────────
                        _SectionHeader(
                          title: 'Estilo del menú *',
                          subtitle: 'El estilo define la forma de las tarjetas, botones y el diseño general.',
                        ),
                        const SizedBox(height: 10),

                        // ── Lista de skins ──────────────────────────────────
                        ..._catalog.map((skin) {
                          final isSelected = _skinId?.toString() == skin.id.toString()
                              || (_skinId == null && skin.id == _catalog.first.id);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Fila del skin
                                GestureDetector(
                                  onTap: () => _pickSkin(skin.id),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFEEF2FF)
                                          : Colors.white,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.kBlue
                                            : const Color(0xFFE2E8F0),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                skin.label,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                              if (skin.description.isNotEmpty)
                                                Text(
                                                  skin.description,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          isSelected
                                              ? Icons.check
                                              : Icons.expand_more,
                                          size: 18,
                                          color: isSelected
                                              ? AppColors.kBlue
                                              : const Color(0xFF94A3B8),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Paletas inline (solo skin seleccionado)
                                if (isSelected && skin.palettes.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
                                    child: GridView.count(
                                      crossAxisCount: 2,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                      childAspectRatio: 2.0,
                                      children: skin.palettes.map((palette) {
                                        final isPalActive =
                                            _paletteId?.toString() == palette.id.toString() ||
                                            (_paletteId == null &&
                                                palette.id == skin.palettes.first.id);

                                        return GestureDetector(
                                          onTap: () => _pickPalette(palette.id),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 150),
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: isPalActive
                                                    ? AppColors.kBlue
                                                    : const Color(0xFFE2E8F0),
                                                width: isPalActive ? 2 : 1,
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                // Barra de colores preview — usa gradient con stops duros
                                                // para no depender de Row/Expanded y constraints de ancho
                                                _ColorBar(hexColors: palette.preview.take(4).toList()),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        palette.name,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                          color: isPalActive
                                                              ? AppColors.kBlue
                                                              : const Color(0xFF374151),
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (isPalActive)
                                                      const Icon(Icons.check,
                                                          size: 11, color: AppColors.kBlue),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 12),

                        // ── Preview de paleta seleccionada ──────────────────
                        if (_currentPalette != null)
                          _PalettePreview(
                            palette: _currentPalette!,
                            businessName: widget.draft.info.name,
                            slogan:       widget.draft.info.slogan,
                          ),

                        const SizedBox(height: 16),

                        // ── Botón preview externo ───────────────────────────
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/preview/${widget.menuId}'),
                            icon: const Icon(Icons.open_in_new, size: 14),
                            label: const Text('Abrir preview completa'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
        ),
        SaveBar(dirty: _dirty, saving: widget.saving, onSave: _handleSave),
      ],
    );
  }
}

// ── Widgets auxiliares ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});
  final String  title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(subtitle!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ),
        ],
      );
}

// Mini-preview del menú con la paleta seleccionada (igual que StepDesign.jsx)
class _PalettePreview extends StatelessWidget {
  const _PalettePreview({
    required this.palette,
    required this.businessName,
    required this.slogan,
  });

  final CatalogPalette palette;
  final String         businessName;
  final String         slogan;

  Color _hex(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
      if (h.length == 8) return Color(int.parse(h, radix: 16));
    } catch (_) {}
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final colors = palette.colors;

    final bg         = _hex(colors['bg']        ?? '#F8FAFC');
    final navBg      = _hex(colors['navBg']      ?? '#FFFFFF');
    final navBorder  = _hex(colors['navBorder']  ?? '#E2E8F0');
    final primary    = _hex(colors['primary']    ?? '#4F46E5');
    final text       = _hex(colors['text']       ?? '#0F172A');
    final textMuted  = _hex(colors['textMuted']  ?? '#94A3B8');
    final surface    = _hex(colors['surface']    ?? '#FFFFFF');
    final surfaceAlt = _hex(colors['surfaceAlt'] ?? '#F1F5F9');
    final border     = _hex(colors['border']     ?? '#E2E8F0');
    final badge      = _hex(colors['badge']      ?? '#EEF2FF');
    final badgeText  = _hex(colors['badgeText']  ?? '#4F46E5');

    final borderRadius = palette.borderRadius;
    // El backend envía radius como números (12, 8, 99), no strings.
    // React los convierte a "12px" antes de usarlos, aquí convertimos directo.
    double parseR(String key, double fb) =>
        double.tryParse('${borderRadius[key]}'.replaceAll('px', '')) ?? fb;
    final cardRadius = parseR('card', 12);
    final btnRadius  = parseR('button', 8);
    final bdgRadius  = parseR('badge', 99);

    return Container(
      decoration: BoxDecoration(
        color:        bg,
        border:       Border.all(color: border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Nav
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: navBg,
              border: Border(bottom: BorderSide(color: navBorder)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      businessName.isNotEmpty ? businessName[0].toUpperCase() : 'N',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w900, color: badgeText),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    businessName.isNotEmpty ? businessName : 'Tu negocio',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: text),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(btnRadius),
                  ),
                  child: const Text('Ver menú',
                      style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slogan.isNotEmpty ? slogan : palette.name,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: textMuted,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:        surface,
                    border:       Border.all(color: border),
                    borderRadius: BorderRadius.circular(cardRadius),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color:        surfaceAlt,
                          borderRadius: BorderRadius.circular(cardRadius),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Producto de ejemplo',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700, color: text)),
                            Text('Descripción del plato',
                                style: TextStyle(fontSize: 11, color: textMuted)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color:        badge,
                                    borderRadius: BorderRadius.circular(bdgRadius),
                                  ),
                                  child: Text('Popular',
                                      style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: badgeText)),
                                ),
                                const Spacer(),
                                Text('\$18.000',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: primary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Barra horizontal de colores de la paleta.
// Usa LinearGradient con stops duros para evitar dependencias de layout
// con Row/Expanded que pueden colapsar a 0 en Column(crossAxisAlignment.start).
class _ColorBar extends StatelessWidget {
  const _ColorBar({required this.hexColors});
  final List<String> hexColors;

  Color _parse(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
      if (h.length == 8) return Color(int.parse(h, radix: 16));
    } catch (_) {}
    return const Color(0xFFE2E8F0);
  }

  @override
  Widget build(BuildContext context) {
    if (hexColors.isEmpty) return const SizedBox(height: 16);

    final dartColors = hexColors.map(_parse).toList();
    final n = dartColors.length;

    // Stops duplicados para crear bloques de color sólidos sin degradado
    final stops  = <double>[for (int i = 0; i < n; i++) ...[i / n, (i + 1) / n]];
    final colors = <Color>[for (final c in dartColors) ...[c, c]];

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 16,
        width:  double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, stops: stops),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/menu_publico_model.dart';
import '../themes/theme_catalog.dart';

/// Equivalente a ThemeSelector.jsx — panel flotante (bottom-right) que
/// permite cambiar skin y paleta en modo demo/preview.
class ThemeSelectorPanel extends StatelessWidget {
  const ThemeSelectorPanel({
    super.key,
    required this.open,
    required this.activeSkin,
    required this.activePalette,
    required this.allSkins,
    required this.theme,
    required this.onToggle,
    required this.onSkinChanged,
    required this.onPaletteChanged,
  });

  final bool open;
  final ThemeSkin activeSkin;
  final ThemePalette activePalette;
  final List<ThemeSkin> allSkins;
  final MenuPublicoTheme theme;
  final VoidCallback onToggle;
  final void Function(String skinId) onSkinChanged;
  final void Function(String paletteId) onPaletteChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (open) ...[
          _buildPanel(),
          const SizedBox(height: 8),
        ],
        _buildToggleButton(),
      ],
    );
  }

  Widget _buildToggleButton() {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.primary,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.palette_outlined, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            const Text(
              'Temas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              open ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
              color: Colors.white,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel() {
    final th = theme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 480, maxWidth: 272),
      child: Container(
      width: 272,
      decoration: BoxDecoration(
        color: th.surface,
        border: Border.all(color: th.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: th.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.palette_outlined, size: 15, color: th.primary),
                const SizedBox(width: 8),
                Text(
                  'PREVIEW DE DISEÑO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: th.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Skin selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              'Estilo',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: th.textMuted,
              ),
            ),
          ),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: allSkins.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final sk = allSkins[i];
                final isActive = sk.id == activeSkin.id;
                return GestureDetector(
                  onTap: () => onSkinChanged(sk.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isActive ? th.primary : th.border,
                        width: 1.5,
                      ),
                      color: isActive
                          ? th.primary.withValues(alpha: 0.13)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sk.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isActive ? th.primary : th.textMuted,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Palette selector
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'Paleta de colores',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: th.textMuted,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeSkin.palettes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.4,
              ),
              itemBuilder: (_, i) {
                final pal = activeSkin.palettes[i];
                final isActive = pal.id == activePalette.id;
                return GestureDetector(
                  onTap: () => onPaletteChanged(pal.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isActive ? th.primary : th.border,
                        width: 1.5,
                      ),
                      color: isActive
                          ? th.primary.withValues(alpha: 0.07)
                          : th.surfaceAlt,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Color swatches
                        Row(
                          children: pal.preview.take(3).map((hex) {
                            Color? c;
                            try {
                              final h = hex.replaceAll('#', '');
                              final full = h.length == 6 ? 'FF$h' : h;
                              c = Color(int.parse(full, radix: 16));
                            } catch (_) {}
                            return Container(
                              width: 16,
                              height: 16,
                              margin: const EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(
                                color: c ?? Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                pal.name,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: th.text,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isActive)
                              Icon(Icons.check, size: 11, color: th.primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer note
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: th.surfaceAlt,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Vista previa del administrador',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: th.text),
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

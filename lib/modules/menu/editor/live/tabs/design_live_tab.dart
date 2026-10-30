import 'package:flutter/material.dart';

import '../../../../../services/live_editor_service.dart';
import '../../../../../services/themes_catalog_service.dart';
import '../../../../../shared/app_colors.dart';
import '../editor_models.dart';

class DesignLiveTab extends StatefulWidget {
  const DesignLiveTab({super.key, required this.menu, required this.onChanged});

  final LiveMenu menu;
  final Future<void> Function() onChanged;

  @override
  State<DesignLiveTab> createState() => _DesignLiveTabState();
}

class _DesignLiveTabState extends State<DesignLiveTab> {
  List<CatalogSkin>? _catalog;
  String? _skin;
  String? _palette;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final catalog = await ThemesCatalogService.load();
    if (!mounted) return;
    setState(() {
      _catalog = catalog;
      _skin =
          widget.menu.skinId ??
          (catalog.isNotEmpty ? catalog.first.id.toString() : null);
      final skin =
          catalog.where((s) => s.id.toString() == _skin).firstOrNull ??
          (catalog.isNotEmpty ? catalog.first : null);
      _palette =
          widget.menu.paletteId ??
          (skin != null && skin.palettes.isNotEmpty
              ? skin.palettes.first.id.toString()
              : null);
    });
  }

  Future<void> _save() async {
    if (_skin == null || _palette == null) return;
    setState(() => _busy = true);
    try {
      await LiveEditorService.saveSection(widget.menu.codigo, 'diseno', {
        'skinId': _skin,
        'paletteId': _palette,
      });
      await widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diseño guardado.'),
            backgroundColor: AppColors.kGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.kRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _catalog;
    if (catalog == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (catalog.isEmpty) {
      return const Center(child: Text('No se pudieron cargar los temas.'));
    }
    final skin =
        catalog.where((s) => s.id.toString() == _skin).firstOrNull ??
        catalog.first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        const Text(
          'Estilo del menú',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final s in catalog)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: s.id.toString() == _skin
                    ? AppColors.kBlue
                    : AppColors.kCardBorder,
                width: s.id.toString() == _skin ? 2 : 1,
              ),
            ),
            child: ListTile(
              title: Text(
                s.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                s.description,
                style: const TextStyle(fontSize: 11),
              ),
              trailing: s.id.toString() == _skin
                  ? const Icon(Icons.check_circle, color: AppColors.kBlue)
                  : null,
              onTap: () => setState(() {
                _skin = s.id.toString();
                _palette = s.palettes.isNotEmpty
                    ? s.palettes.first.id.toString()
                    : null;
              }),
            ),
          ),
        const SizedBox(height: 12),
        const Text(
          'Paleta',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in skin.palettes)
              GestureDetector(
                onTap: () => setState(() => _palette = p.id.toString()),
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: p.id.toString() == _palette
                          ? AppColors.kBlue
                          : AppColors.kCardBorder,
                      width: p.id.toString() == _palette ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (final hex in p.preview.take(4))
                            Expanded(
                              child: Container(height: 18, color: _parse(hex)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'Guardando…' : 'Guardar diseño'),
        ),
      ],
    );
  }

  Color _parse(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
      if (h.length == 8) return Color(int.parse(h, radix: 16));
    } catch (_) {}
    return const Color(0xFFE2E8F0);
  }
}

import 'package:flutter/material.dart';

import '../../../../../services/themes_catalog_service.dart';
import '../../../../../shared/app_colors.dart';
import '../comun/guardar.dart';
import 'tema_elegido.dart';

// Equivalente a src/modules/menu/public/edicion/tema/FormTema.jsx en React.

Color _color(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16) ?? 0xFF94A3B8);
}

/// Elegir el tema del menú: al tocar un estilo o una paleta el menú de atrás cambia al instante. Al cerrar (o con "Ver
/// cómo queda") se ve el menú completo con ese tema y una barra para dejarlo o volver al anterior (PruebaTema):
/// primero se aprecia, después se decide.
/// actual: el tema que se ve ahora · guardado: el del menú · onElegir: cambia el tema del menú de atrás
class FormTema extends StatefulWidget {
  const FormTema({super.key, required this.actual, required this.guardado, required this.onElegir, required this.onCerrar});

  final TemaElegido actual;
  final TemaElegido guardado;
  final ValueChanged<TemaElegido> onElegir;
  final VoidCallback onCerrar;

  @override
  State<FormTema> createState() => _FormTemaState();
}

class _FormTemaState extends State<FormTema> {
  List<CatalogSkin>? _catalogo;
  late TemaElegido _tema = widget.actual;

  @override
  void initState() {
    super.initState();
    ThemesCatalogService.load().then((c) {
      if (mounted) setState(() => _catalogo = c);
    });
  }

  void _elegir(TemaElegido t) {
    setState(() => _tema = t);
    widget.onElegir(t);
  }

  @override
  Widget build(BuildContext context) {
    final catalogo = _catalogo;
    if (catalogo == null) return cargandoPanel;
    final skin = catalogo.where((s) => '${s.id}' == '${_tema.skin}').firstOrNull ?? catalogo.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloBloque('Estilo'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final s in catalogo)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s.label),
                    selected: '${s.id}' == '${skin?.id}',
                    onSelected: (_) => _elegir(TemaElegido(s.id, s.palettes.firstOrNull?.id)),
                  ),
                ),
            ],
          ),
        ),
        const TituloBloque('Paleta de colores'),
        GridView.extent(
          maxCrossAxisExtent: 170,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.2,
          children: [
            for (final p in skin?.palettes ?? const <CatalogPalette>[])
              _Paleta(
                paleta: p,
                activa: '${p.id}' == '${_tema.paleta}',
                onTap: () => _elegir(TemaElegido(skin!.id, p.id)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 46,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: AppColors.kBlue),
            onPressed: _tema.igualA(widget.guardado) ? null : widget.onCerrar,
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('Ver cómo queda'),
          ),
        ),
      ],
    );
  }
}

class _Paleta extends StatelessWidget {
  const _Paleta({required this.paleta, required this.activa, required this.onTap});
  final CatalogPalette paleta;
  final bool activa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: activa ? AppColors.kBlue : AppColors.kCardBorder, width: activa ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  for (final c in paleta.preview.take(3))
                    Container(
                      width: 18,
                      height: 18,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: _color(c),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(paleta.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  if (activa) const Icon(Icons.check, size: 14, color: AppColors.kBlue),
                ],
              ),
            ],
          ),
        ),
      );
}

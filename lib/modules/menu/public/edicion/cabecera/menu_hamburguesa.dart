import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/app_colors.dart';
import 'opciones_edicion.dart';
import 'publicacion.dart';

// Equivalente a src/modules/menu/public/edicion/cabecera/MenuHamburguesa.jsx en React.

/// El botón de la cabecera que abre el menú de edición: todo lo que se edita, y publicar o despublicar.
class MenuHamburguesa extends StatelessWidget {
  const MenuHamburguesa({
    super.key,
    required this.menuCodigo,
    required this.publicado,
    required this.esPropio,
    required this.abrir,
    required this.onEstado,
    required this.color,
  });

  final String menuCodigo;
  final bool publicado;
  final bool esPropio;
  final void Function(String seccion) abrir;

  /// El menú se publicó o despublicó (recargar).
  final Future<void> Function() onEstado;
  final Color color;

  void _abrirPanel(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black38,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, _) => Align(
        alignment: Alignment.centerRight,
        child: _PanelLateral(
          menuCodigo: menuCodigo,
          publicado: publicado,
          esPropio: esPropio,
          abrir: abrir,
          onEstado: onEstado,
        ),
      ),
      transitionBuilder: (_, anim, _, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Opciones de edición',
        onPressed: () => _abrirPanel(context),
        style: IconButton.styleFrom(backgroundColor: color.withValues(alpha: 0.12)),
        icon: Icon(Icons.menu, color: color, size: 20),
      );
}

class _PanelLateral extends StatefulWidget {
  const _PanelLateral({
    required this.menuCodigo,
    required this.publicado,
    required this.esPropio,
    required this.abrir,
    required this.onEstado,
  });

  final String menuCodigo;
  final bool publicado;
  final bool esPropio;
  final void Function(String seccion) abrir;
  final Future<void> Function() onEstado;

  @override
  State<_PanelLateral> createState() => _PanelLateralState();
}

class _PanelLateralState extends State<_PanelLateral> {
  bool _cambiando = false;

  void _elegir(OpcionEdicion o) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    if (o.ruta != null) {
      router.push(o.ruta!(widget.menuCodigo));
    } else {
      widget.abrir(o.seccion!);
    }
  }

  Future<void> _cambiarEstado(Future<bool> Function(BuildContext, String) accion) async {
    setState(() => _cambiando = true);
    final ok = await accion(context, widget.menuCodigo);
    if (!mounted) return;
    setState(() => _cambiando = false);
    if (ok) {
      Navigator.of(context).pop();
      await widget.onEstado();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    return Material(
      color: Colors.white,
      elevation: 16,
      child: SizedBox(
        width: ancho * 0.85 > 340 ? 340 : ancho * 0.85,
        height: double.infinity,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Editar tu menú', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.publicado ? AppColors.kBlue : const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              widget.publicado ? 'Publicado · lo que cambies se ve al instante' : 'No publicado · solo tú lo ves',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(tooltip: 'Cerrar', onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (final g in gruposEdicion) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                        child: Text(g.titulo.toUpperCase(),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.kTextMuted, letterSpacing: 0.6)),
                      ),
                      for (final o in g.opciones)
                        ListTile(
                          dense: true,
                          leading: Icon(o.icono, color: AppColors.kBlue, size: 20),
                          title: Text(o.texto, style: const TextStyle(fontSize: 14)),
                          onTap: () => _elegir(o),
                        ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!widget.publicado)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.kBlue),
                        onPressed: _cambiando ? null : () => _cambiarEstado(publicarMenu),
                        icon: const Icon(Icons.upload_outlined, size: 18),
                        label: const Text('Publicar'),
                      ),
                    if (widget.publicado && widget.esPropio)
                      OutlinedButton.icon(
                        onPressed: _cambiando ? null : () => _cambiarEstado(despublicarMenu),
                        icon: const Icon(Icons.visibility_off_outlined, size: 18),
                        label: const Text('Despublicar'),
                      ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        final router = GoRouter.of(context);
                        Navigator.of(context).pop();
                        router.push('/menus/${widget.menuCodigo}');
                      },
                      icon: const Icon(Icons.dashboard_outlined, size: 18),
                      label: const Text('Ir al panel del menú'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

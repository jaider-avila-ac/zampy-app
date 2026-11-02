import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../components/layout/sidebar.dart';
import '../../../../services/live_editor_service.dart';
import '../../../../shared/app_colors.dart';
import '../../../../shared/app_header.dart';
import '../../../../shared/responsive.dart';
import '../live/editor_models.dart';
import 'info_menu_form.dart';

// Equivalente a src/modules/menu/editor/MenuInfoPage.jsx en React (/menus/:id/info, ?paso=4 = horario).

/// Toda la información del menú en una pantalla aparte (ver InfoMenuForm).
class MenuInfoPage extends StatefulWidget {
  const MenuInfoPage({super.key, required this.codigo, this.enfocarHorario = false});

  final String codigo;
  final bool enfocarHorario;

  @override
  State<MenuInfoPage> createState() => _MenuInfoPageState();
}

class _MenuInfoPageState extends State<MenuInfoPage> {
  LiveMenu? _menu;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final m = await LiveEditorService.load(widget.codigo);
      if (mounted) setState(() => _menu = m);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final menu = _menu;
    return Scaffold(
      backgroundColor: AppColors.kBgPage,
      drawer: const AppSidebar(),
      appBar: AppHeader(
        title: widget.enfocarHorario ? 'Horario de atención' : 'Información del menú',
        subtitle: menu?.info.name,
        actions: [
          // En el editor de horario (independiente) no va el "Ver mi menú": sobra.
          if (menu != null && !widget.enfocarHorario)
            IconButton(
              tooltip: 'Ver mi menú',
              onPressed: () => context.go('/${menu.slug}'),
              icon: const Icon(Icons.open_in_new, size: 19),
            ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, style: const TextStyle(color: AppColors.kTextMuted)),
                  TextButton(onPressed: _cargar, child: const Text('Reintentar')),
                ],
              ),
            )
          : menu == null
              ? const Center(child: CircularProgressIndicator())
              // en tablet el formulario no se estira de borde a borde
              : Padding(
                  padding: EdgeInsets.symmetric(horizontal: contenidoPadding(context, top: 0, bottom: 0).left - 16),
                  child: InfoMenuForm(menu: menu, onChanged: _cargar, enfocarHorario: widget.enfocarHorario),
                ),
    );
  }
}

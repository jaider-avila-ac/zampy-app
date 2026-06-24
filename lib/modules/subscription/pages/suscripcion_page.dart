import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/suscripcion_service.dart';

// Equivalente a src/modules/subscription/pages/SuscripcionPage.jsx en React
// Página de redirección: carga la suscripción del menú y decide a dónde ir.
// - Tiene suscripción → /billing/sus/{id}
// - No tiene (o error) → /menus/{menuId}/planes

class SuscripcionPage extends StatefulWidget {
  const SuscripcionPage({super.key, required this.menuId});
  final int menuId;

  @override
  State<SuscripcionPage> createState() => _SuscripcionPageState();
}

class _SuscripcionPageState extends State<SuscripcionPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    try {
      final sub = await SuscripcionService.getMiSuscripcion(widget.menuId);
      if (!mounted) return;
      final id = sub?['id'];
      if (id != null) {
        context.replace('/billing/sus/$id');
      } else {
        context.replace('/menus/${widget.menuId}/planes');
      }
    } catch (_) {
      if (mounted) context.replace('/menus/${widget.menuId}/planes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

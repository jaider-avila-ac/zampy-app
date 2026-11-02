import 'package:flutter/material.dart' hide MenuTheme;

import '../../../../shared/responsive.dart';
import '../../../mesero/hooks/use_orden_mesero.dart';
import '../../../orders/utils/formato.dart';
import '../../../orders/utils/order_items.dart';
import '../models/public_menu_model.dart';
import 'cart_sheet.dart' show CartItemTile;

/// "La orden" que arma el mesero para una mesa (equivale a OrderSheet.jsx): no crea un pedido de cliente, agrega una
/// ronda a la cuenta. Reutiliza la fila del carrito. Devuelve true si el mesero eligió volver a sus mesas.
class OrderSheet extends StatefulWidget {
  const OrderSheet({super.key, required this.orden, required this.theme});

  final UseOrdenMesero orden;
  final MenuTheme theme;

  static Future<bool> show(BuildContext context, {required UseOrdenMesero orden, required MenuTheme theme}) async {
    final volver = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: hojaConstraints(context),
      backgroundColor: Colors.transparent,
      builder: (_) => OrderSheet(orden: orden, theme: theme),
    );
    return volver == true;
  }

  @override
  State<OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<OrderSheet> {
  final _nota = TextEditingController();
  bool _ok = false;
  String _mesaEnviada = '';

  @override
  void dispose() {
    _nota.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final destino = widget.orden.destino;
    if (await widget.orden.enviar(_nota.text) && mounted) {
      setState(() {
        _ok = true;
        _mesaEnviada = destino.mesaNombre;
        _nota.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final o = widget.orden;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
        decoration: BoxDecoration(color: t.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: ListenableBuilder(
          listenable: o,
          builder: (context, _) {
            final nueva = o.destino.nuevaCuenta;
            final cabecera = Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 10),
              child: Row(children: [
                Icon(Icons.assignment_outlined, size: 18, color: t.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('La orden', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.text)),
                      Text(o.destino.mesaNombre,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: t.textMuted)),
                    ],
                  ),
                ),
                if (!_ok)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: t.primary, borderRadius: BorderRadius.circular(20)),
                    child: Text('${o.items.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                IconButton(onPressed: () => Navigator.pop(context, false), icon: Icon(Icons.close, color: t.textMuted, size: 20)),
              ]),
            );
            if (_ok) return Column(mainAxisSize: MainAxisSize.min, children: [cabecera, _enviada(t)]);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                cabecera,
                Divider(height: 1, color: t.border),
                Flexible(
                  child: o.items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                          child: Text('Busca o navega el menú y agrega productos a la orden.',
                              textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: t.textMuted)),
                        )
                      : ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                          children: [
                            for (final item in o.items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: CartItemTile(
                                  item: item,
                                  theme: t,
                                  onRemove: () => o.quitar(buildOrderItemKey(item)),
                                  onUpdate: (d) => o.cantidadDe(buildOrderItemKey(item), d),
                                ),
                              ),
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.person_outline, size: 13, color: t.textMuted),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text('Nota o para quién es (opcional)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.textMuted)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _nota,
                        maxLength: nueva ? 60 : 250,
                        style: TextStyle(fontSize: 13, color: t.text),
                        decoration: InputDecoration(
                          hintText: nueva ? 'Ej: "Camisa azul", "Gorra roja", "Juan"' : 'Ej: sin cebolla, para la señora de gorra roja',
                          hintStyle: TextStyle(fontSize: 13, color: t.textMuted),
                          counterText: '',
                          isDense: true,
                          filled: true,
                          fillColor: t.surfaceAlt,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: t.border)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nueva
                            ? 'Abre una cuenta nueva y separada en ${o.destino.mesaNombre}. Si lo dejas vacío, se numera sola ("Cuenta 2", etc.).'
                            : 'Se agrega a la cuenta actual de ${o.destino.mesaNombre}.',
                        style: TextStyle(fontSize: 11, color: t.textMuted),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: t.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Expanded(child: Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.textMuted))),
                        Text(precio(o.total), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: t.text)),
                      ]),
                      if (o.error != null) ...[
                        const SizedBox(height: 6),
                        Text(o.error!, style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
                      ],
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: o.enviando || o.items.isEmpty ? null : _confirmar,
                          style: FilledButton.styleFrom(
                            backgroundColor: t.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: o.enviando
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle_outline, size: 18),
                          label: Text(o.enviando ? 'Enviando…' : 'Confirmar orden', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _enviada(MenuTheme t) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: t.primary, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline, size: 34, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text('¡Orden enviada!', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: t.text)),
            const SizedBox(height: 4),
            Text('Se agregó a la cuenta de $_mesaEnviada.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: t.textMuted)),
            const SizedBox(height: 20),
            SizedBox(
              height: 46,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, false),
                style: FilledButton.styleFrom(backgroundColor: t.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Agregar más productos', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Volver a mesas', style: TextStyle(color: t.textMuted, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

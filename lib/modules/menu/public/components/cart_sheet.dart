import 'package:flutter/material.dart' hide MenuTheme;
import 'package:provider/provider.dart';
import '../../../../shared/responsive.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../context/auth_context.dart';
import '../../../../context/cart_context.dart';
import '../../../../services/pedido_service.dart';
import '../../../orders/utils/order_items.dart';
import '../models/public_menu_model.dart';

// Equivalente a src/modules/menu/public/components/CartSheet.jsx en React.
// Ítems del carrito, datos de contacto y envío de la solicitud de pedido (POST /pedidos).

String fmtPrecio(num? v) {
  final s = (v ?? 0).round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '\$$buf';
}

Future<void> abrirUrl(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

class CartSheet extends StatefulWidget {
  const CartSheet({super.key, required this.menuCodigo, required this.theme, this.info});

  final String menuCodigo;
  final MenuTheme theme;
  final MenuInfo? info;

  static Future<void> show(BuildContext context, {required String menuCodigo, required MenuTheme theme, MenuInfo? info}) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        constraints: hojaConstraints(context),
        backgroundColor: Colors.transparent,
        builder: (_) => CartSheet(menuCodigo: menuCodigo, theme: theme, info: info),
      );

  @override
  State<CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<CartSheet> {
  late final TextEditingController _telefono;
  late final TextEditingController _direccion;
  late final TextEditingController _referencia;
  bool _sending = false;
  String _error = '';
  bool _ok = false;
  String _waUrl = '';
  // Se conserva mientras no cambie el pedido: un reintento tras un fallo no lo duplica.
  String _requestId = PedidoService.nuevoRequestId();
  String _firma = '';

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthContext>().user;
    _telefono = TextEditingController(text: u?['telefono'] as String? ?? '');
    _direccion = TextEditingController(text: u?['direccion'] as String? ?? '');
    _referencia = TextEditingController(text: u?['direccionReferencia'] as String? ?? '');
  }

  @override
  void dispose() {
    _telefono.dispose();
    _direccion.dispose();
    _referencia.dispose();
    super.dispose();
  }

  Future<void> _enviar(CartContext cart) async {
    if (_sending || cart.items.isEmpty) return;
    if (_direccion.text.trim().isEmpty) {
      setState(() => _error = 'Escribe la dirección de entrega para poder enviar el pedido.');
      return;
    }
    if (_telefono.text.trim().isEmpty) {
      setState(() => _error = 'Escribe un número de teléfono de contacto para poder enviar el pedido.');
      return;
    }
    final firma = [
      cart.items.map(buildOrderItemKey).join('|'),
      cart.items.map((i) => i['quantity']).join(','),
      _telefono.text.trim(),
      _direccion.text.trim(),
      _referencia.text.trim(),
    ].join('#');
    if (firma != _firma) {
      _firma = firma;
      _requestId = PedidoService.nuevoRequestId();
    }
    setState(() {
      _error = '';
      _sending = true;
    });
    try {
      final r = await PedidoService.crear(
        menuCodigo: widget.menuCodigo,
        requestId: _requestId,
        direccionEntrega: _direccion.text.trim(),
        direccionReferencia: _referencia.text.trim().isEmpty ? null : _referencia.text.trim(),
        telefono: _telefono.text.trim(),
        items: cart.items.map(toOrderItemPayload).toList(),
      );
      cart.clearCart();
      if (!mounted) return;
      setState(() {
        _waUrl = r['waUrl']?.toString() ?? '';
        _ok = true;
      });
    } catch (e) {
      final m = e.toString().replaceFirst('Exception: ', '');
      if (mounted) setState(() => _error = m.isEmpty ? 'No se pudo guardar el pedido. Intenta de nuevo.' : m);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final cart = context.watch<CartContext>();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(t.cardRadius.clamp(12, 24))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 10),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.border))),
              child: Row(
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 18, color: t.primary),
                  const SizedBox(width: 8),
                  Text('Tu carrito', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: t.text)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: t.primary, borderRadius: BorderRadius.circular(99)),
                    child: Text('${cart.items.length}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: t.textMuted)),
                ],
              ),
            ),
            Flexible(child: _ok ? _confirmacion() : _formulario(cart)),
          ],
        ),
      ),
    );
  }

  Widget _confirmacion() {
    final t = widget.theme;
    final info = widget.info;
    final phone = (info?.whatsapp?.isNotEmpty ?? false) ? info!.whatsapp : info?.phone;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: t.primary, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle, size: 36, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text('¡Solicitud registrada!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: t.text)),
          const SizedBox(height: 4),
          Text(
            'El negocio debe confirmar disponibilidad, precio final, forma de pago y entrega.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: t.textMuted),
          ),
          if (_waUrl.isNotEmpty) ...[
            const SizedBox(height: 20),
            // Bloque "Recomendado: WhatsApp" — temizado con el color del menú (como c.primary en React), no verde.
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: t.surface,
                border: Border.all(color: t.primary, width: 1.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('★ RECOMENDADO',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: t.primary)),
                  const SizedBox(height: 4),
                  Text('Confirma tu pedido por WhatsApp',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.text)),
                  Text(
                    'Envía los detalles al restaurante para que puedan prepararlo y coordinarte la entrega.',
                    style: TextStyle(fontSize: 12, color: t.textMuted),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: t.primary, foregroundColor: Colors.white),
                    onPressed: () {
                      abrirUrl(_waUrl);
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.chat_outlined, size: 17),
                    label: const Text('Enviar por WhatsApp'),
                  ),
                ],
              ),
            ),
          ],
          if ((phone?.isNotEmpty ?? false) || (info?.email?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 16),
            _Contacto(info: info!, theme: t),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          ),
        ],
      ),
    );
  }

  Widget _formulario(CartContext cart) {
    final t = widget.theme;
    final puedeEnviar = !_sending &&
        cart.items.isNotEmpty &&
        _direccion.text.trim().isNotEmpty &&
        _telefono.text.trim().isNotEmpty;
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        if (cart.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('Tu carrito está vacío. Agrega productos del menú para hacer un pedido.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: t.textMuted)),
          )
        else
          for (final item in cart.items)
            CartItemTile(
              item: item,
              theme: t,
              onRemove: () => cart.removeItem(buildOrderItemKey(item)),
              onUpdate: (d) => cart.updateQuantity(buildOrderItemKey(item), d),
            ),
        const SizedBox(height: 12),
        _campo(_telefono, Icons.phone_outlined, 'Teléfono de contacto', 'Ej: 300 123 4567', obligatorio: true,
            teclado: TextInputType.phone),
        _campo(_direccion, Icons.location_on_outlined, 'Dirección de entrega', 'Ej: Calle 45 #12-30, Apto 201',
            obligatorio: true),
        _campo(_referencia, Icons.location_on_outlined, 'Referencia', 'Ej: Al lado de la casa roja'),
        Divider(color: t.border, height: 24),
        Row(
          children: [
            Text('Total estimado', style: TextStyle(fontSize: 13, color: t.textMuted)),
            const Spacer(),
            Text(fmtPrecio(cart.total), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: t.text)),
          ],
        ),
        if (_error.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_error, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
          ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 13, color: t.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Envías una solicitud a ${widget.info?.name.isNotEmpty == true ? widget.info!.name : 'este negocio'}. '
                'El negocio confirma el pedido y cobra directamente; Zammpy no recibe ni custodia este dinero.',
                style: TextStyle(fontSize: 11, color: t.textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: t.primary),
            onPressed: puedeEnviar ? () => _enviar(cart) : null,
            icon: _sending
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline, size: 17),
            label: Text(_sending ? 'Enviando solicitud…' : 'Enviar solicitud de pedido'),
          ),
        ),
      ],
    );
  }

  Widget _campo(TextEditingController c, IconData icon, String label, String hint,
      {bool obligatorio = false, TextInputType? teclado}) {
    final t = widget.theme;
    final vacio = obligatorio && c.text.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: t.textMuted),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: t.textMuted)),
              const SizedBox(width: 4),
              Text(obligatorio ? '* obligatorio' : '(opcional)',
                  style: TextStyle(fontSize: 11, color: obligatorio ? const Color(0xFFEF4444) : t.textMuted)),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: c,
            keyboardType: teclado,
            onChanged: (_) => setState(() => _error = ''),
            style: TextStyle(fontSize: 14, color: t.text),
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              filled: true,
              fillColor: t.surfaceAlt,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: vacio ? const Color(0xFFF87171) : t.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: t.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Contacto extends StatelessWidget {
  const _Contacto({required this.info, required this.theme});
  final MenuInfo info;
  final MenuTheme theme;

  @override
  Widget build(BuildContext context) {
    final wa = info.whatsapp ?? '';
    final tel = info.phone ?? '';
    final email = info.email ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceAlt,
        border: Border.all(color: theme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Contactar al negocio',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.text)),
          Wrap(
            spacing: 8,
            children: [
              if (wa.isNotEmpty || tel.isNotEmpty)
                TextButton.icon(
                  onPressed: () => abrirUrl(wa.isNotEmpty
                      ? 'https://wa.me/${wa.replaceAll(RegExp(r'\D'), '')}'
                      : 'tel:${tel.replaceAll(RegExp(r'[^\d+]'), '')}'),
                  icon: const Icon(Icons.phone_outlined, size: 14),
                  label: Text(wa.isNotEmpty ? 'WhatsApp' : tel),
                ),
              if (email.isNotEmpty)
                TextButton.icon(
                  onPressed: () => abrirUrl('mailto:$email'),
                  icon: const Icon(Icons.mail_outline, size: 14),
                  label: Text(email),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fila de un ítem del carrito (equivalente a CartItem de React).
class CartItemTile extends StatelessWidget {
  const CartItemTile({super.key, required this.item, required this.theme, required this.onRemove, required this.onUpdate});
  final Map<String, dynamic> item;
  final MenuTheme theme;
  final VoidCallback onRemove;
  final ValueChanged<int> onUpdate;

  List<String> _detalles() {
    final out = <String>[];
    if (item['sizeLabel'] != null) out.add('Tamaño: ${item['sizeLabel']}');
    for (final key in const ['ingredientDetails', 'extraDetails']) {
      for (final d in (item[key] as List? ?? const [])) {
        if (d is! Map) continue;
        final price = (d['price'] as num?) ?? 0;
        out.add('${d['label']}${price != 0 ? ' ${price > 0 ? '+' : '−'}${fmtPrecio(price.abs())}' : ''}');
      }
    }
    final grupos = item['gruposResumen'];
    if (grupos is Map) {
      grupos.forEach((k, v) => out.add('$k: ${(v as List).join(', ')}'));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final img = item['productImage'] as String?;
    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
    final unit = (item['unitPrice'] as num?) ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: img != null && img.isNotEmpty
                  ? Image.network(img, fit: BoxFit.cover, errorBuilder: (_, _, _) => ColoredBox(color: t.border))
                  : ColoredBox(color: t.border),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item['productName'] ?? ''}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.text)),
                for (final d in _detalles()) Text(d, style: TextStyle(fontSize: 11, color: t.textMuted)),
                const SizedBox(height: 4),
                Text(fmtPrecio(unit * qty), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.primary)),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: onRemove,
                icon: Icon(Icons.delete_outline, size: 18, color: t.textMuted),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QtyButton(icon: Icons.remove, onTap: () => onUpdate(-1), theme: t),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('$qty', style: TextStyle(fontWeight: FontWeight.w700, color: t.text)),
                  ),
                  _QtyButton(icon: Icons.add, onTap: () => onUpdate(1), theme: t),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap, required this.theme});
  final IconData icon;
  final VoidCallback onTap;
  final MenuTheme theme;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(99),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: theme.border)),
          child: Icon(icon, size: 14, color: theme.text),
        ),
      );
}

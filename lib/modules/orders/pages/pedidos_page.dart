import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../shared/responsive.dart';

import '../../../components/layout/sidebar.dart';
import '../../../services/pedido_service.dart';
import '../../../shared/app_colors.dart';
import '../../../shared/app_header.dart';

// Equivalente a src/modules/orders/pages/PedidosPage.jsx en React: pedidos que hizo el cliente,
// por páginas (cursor), con cancelar (pendiente) y marcar recibido (pendiente / en preparación).

const _estados = {
  'pendiente': ('Pendiente', Color(0xFF475569), Color(0xFFF8FAFC)),
  'en_proceso': ('En preparación', Color(0xFF4F46E5), Color(0xFFEEF2FF)),
  'entregado': ('Entregado', Color(0xFF334155), Color(0xFFF1F5F9)),
  'cancelado': ('Cancelado', Color(0xFF64748B), Color(0xFFF8FAFC)),
};

String _precio(dynamic v) {
  final n = v is num ? v : num.tryParse('$v') ?? 0;
  final s = n.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '\$$buf';
}

String _fecha(String? iso) {
  final d = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  const m = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic'];
  return '${d.day} ${m[d.month - 1]} ${d.year}, ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  List<Map<String, dynamic>> _pedidos = [];
  String? _siguiente;
  bool _loading = true;
  bool _cargandoMas = false;
  String _error = '';
  String? _marcando;
  String? _cancelando;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  List<Map<String, dynamic>> _items(Map<String, dynamic> r) =>
      (r['items'] as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final r = await PedidoService.misPedidos();
      if (!mounted) return;
      setState(() {
        _pedidos = _items(r);
        _siguiente = r['siguiente'] as String?;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudieron cargar tus pedidos.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cargarMas() async {
    if (_siguiente == null || _cargandoMas) return;
    setState(() => _cargandoMas = true);
    try {
      final r = await PedidoService.misPedidos(despues: _siguiente);
      if (!mounted) return;
      setState(() {
        _pedidos = [..._pedidos, ..._items(r)];
        _siguiente = r['siguiente'] as String?;
      });
    } catch (_) {
      _snack('No se pudieron cargar más pedidos.');
    } finally {
      if (mounted) setState(() => _cargandoMas = false);
    }
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: AppColors.kRed,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _cambiarEstado(String codigo, String estado) => setState(() {
        _pedidos = [for (final p in _pedidos) p['codigo'] == codigo ? {...p, 'estado': estado} : p];
      });

  Future<void> _recibido(String codigo) async {
    setState(() => _marcando = codigo);
    try {
      await PedidoService.marcarRecibido(codigo);
      _cambiarEstado(codigo, 'entregado');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _marcando = null);
    }
  }

  Future<void> _cancelar(String codigo) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: const Text('¿Cancelar esta solicitud de pedido?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Volver')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.kRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _cancelando = codigo);
    try {
      await PedidoService.cancelarPedido(codigo);
      _cambiarEstado(codigo, 'cancelado');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cancelando = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgPage,
      drawer: const AppSidebar(),
      appBar: AppHeader(
        title: 'Mis pedidos',
        subtitle: 'Pedidos realizados en restaurantes',
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _cargar,
            icon: const Icon(Icons.refresh, size: 20, color: AppColors.kTextPrimary),
          ),
        ],
      ),
      body: _loading && _pedidos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: contenidoPadding(context),
                children: [
                  const _Nota(),
                  const SizedBox(height: 12),
                  if (_error.isNotEmpty)
                    _Mensaje(texto: _error, onRetry: _cargar)
                  else if (_pedidos.isEmpty)
                    const _Vacio()
                  else ...[
                    for (final p in _pedidos)
                      _PedidoCard(
                        pedido: p,
                        marcando: _marcando == p['codigo'],
                        cancelando: _cancelando == p['codigo'],
                        onRecibido: () => _recibido(p['codigo'] as String),
                        onCancelar: () => _cancelar(p['codigo'] as String),
                      ),
                    if (_siguiente != null)
                      Center(
                        child: TextButton(
                          onPressed: _cargandoMas ? null : _cargarMas,
                          child: Text(_cargandoMas ? 'Cargando…' : 'Cargar más'),
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _Nota extends StatelessWidget {
  const _Nota();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          border: Border.all(color: const Color(0xFFE0E7FF)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 14, color: Color(0xFF4338CA)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Zammpy no gestiona pagos ni envíos. El costo de entrega y la forma de pago los coordinas directamente con el restaurante.',
                style: TextStyle(fontSize: 12, color: Color(0xFF4338CA)),
              ),
            ),
          ],
        ),
      );
}

class _Vacio extends StatelessWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.kCardBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.receipt_long_outlined, size: 32, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 8),
            const Text('No has realizado pedidos aún',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.kTextSecondary)),
            const SizedBox(height: 4),
            const Text('Cuando hagas un pedido desde un menú aparecerá aquí',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
            TextButton(onPressed: () => context.go('/'), child: const Text('Explorar menús')),
          ],
        ),
      );
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.texto, required this.onRetry});
  final String texto;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(texto, style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      );
}

class _PedidoCard extends StatefulWidget {
  const _PedidoCard({
    required this.pedido,
    required this.marcando,
    required this.cancelando,
    required this.onRecibido,
    required this.onCancelar,
  });
  final Map<String, dynamic> pedido;
  final bool marcando;
  final bool cancelando;
  final VoidCallback onRecibido;
  final VoidCallback onCancelar;

  @override
  State<_PedidoCard> createState() => _PedidoCardState();
}

class _PedidoCardState extends State<_PedidoCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.pedido;
    final estado = p['estado'] as String? ?? '';
    final cfg = _estados[estado] ?? (estado, const Color(0xFF475569), const Color(0xFFF8FAFC));
    final items = (p['items'] as List? ?? []).whereType<Map>().toList();
    final puedeRecibir = estado == 'pendiente' || estado == 'en_proceso';
    final puedeCancelar = estado == 'pendiente';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.kCardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cfg.$3,
                  border: Border.all(color: AppColors.kCardBorder),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(cfg.$1, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cfg.$2)),
              ),
              if (p['codigo'] != null) ...[
                const SizedBox(width: 6),
                Text('#${p['codigo']}', style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
              ],
              const Spacer(),
              Text(_precio(p['total']),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.kTextPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            [if (p['menNombre'] != null) p['menNombre'], _fecha(p['creadoEn'] as String?)].join(' · '),
            style: const TextStyle(fontSize: 12, color: AppColors.kTextSecondary),
          ),
          if (_expanded) ...[
            const Divider(height: 20),
            for (final it in items) _Item(item: Map<String, dynamic>.from(it)),
            Row(
              children: [
                const Text('Total estimado', style: TextStyle(fontSize: 12, color: AppColors.kTextMuted)),
                const Spacer(),
                Text(_precio(p['total']), style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 10),
            _Soporte(pedido: p),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded
                    ? 'Ocultar detalle'
                    : 'Ver ${items.length} ítem${items.length != 1 ? 's' : ''}'),
              ),
              const Spacer(),
              if (puedeCancelar)
                TextButton.icon(
                  onPressed: widget.cancelando ? null : widget.onCancelar,
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                  icon: const Icon(Icons.cancel_outlined, size: 15),
                  label: Text(widget.cancelando ? 'Cancelando…' : 'Cancelar'),
                ),
              if (puedeRecibir)
                IconButton(
                  tooltip: 'Marcar como recibido',
                  onPressed: widget.marcando ? null : widget.onRecibido,
                  icon: widget.marcando
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline, color: AppColors.kBlue),
                ),
              if (estado == 'entregado') const Icon(Icons.check_circle, size: 18, color: AppColors.kTextSecondary),
              if (estado == 'cancelado') const Icon(Icons.cancel, size: 18, color: AppColors.kTextMuted),
            ],
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final breakdown = item['priceBreakdown'] is Map ? item['priceBreakdown'] as Map : const {};
    final unit = (breakdown['unitPrice'] ?? item['unitPrice'] ?? 0) as num;
    final qty = (item['quantity'] as num?) ?? 1;
    String nombres(dynamic l) => (l as List).map((x) => x is Map ? x['label'] : x).join(', ');
    final size = item['size'] is Map ? (item['size'] as Map)['label'] : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item['productName'] ?? ''}${size != null ? ' · $size' : ''}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                if ((item['ingredients'] as List?)?.isNotEmpty ?? false)
                  Text('Personaliz.: ${nombres(item['ingredients'])}',
                      style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
                if ((item['extras'] as List?)?.isNotEmpty ?? false)
                  Text('Adiciones: ${nombres(item['extras'])}',
                      style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
                for (final g in (item['grupos'] as List? ?? const []))
                  if (g is Map)
                    Text('${g['name'] ?? g['grupoLabel'] ?? 'Grupo'}: ${(g['selectedItems'] as List? ?? const []).join(', ')}',
                        style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
                Text('${_precio(unit)} × $qty', style: const TextStyle(fontSize: 11, color: AppColors.kTextSecondary)),
              ],
            ),
          ),
          Text(_precio(unit * qty), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Soporte extends StatelessWidget {
  const _Soporte({required this.pedido});
  final Map<String, dynamic> pedido;

  @override
  Widget build(BuildContext context) {
    final wa = pedido['menWhatsapp'] as String? ?? '';
    final tel = pedido['menTelefono'] as String? ?? '';
    final email = pedido['menEmail'] as String? ?? '';
    final dir = pedido['menDireccion'] as String? ?? '';
    final slug = pedido['menuSlug'] as String?;
    void abrir(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Soporte de este pedido: ${pedido['menNombre'] ?? ''}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          Wrap(
            spacing: 4,
            children: [
              if (wa.isNotEmpty || tel.isNotEmpty)
                TextButton.icon(
                  onPressed: () => abrir(wa.isNotEmpty
                      ? 'https://wa.me/${wa.replaceAll(RegExp(r'\D'), '')}'
                      : 'tel:${tel.replaceAll(RegExp(r'[^\d+]'), '')}'),
                  icon: const Icon(Icons.phone_outlined, size: 14),
                  label: Text(wa.isNotEmpty ? 'WhatsApp' : tel),
                ),
              if (email.isNotEmpty)
                TextButton.icon(
                  onPressed: () => abrir('mailto:$email'),
                  icon: const Icon(Icons.mail_outline, size: 14),
                  label: Text(email),
                ),
              if (slug != null)
                TextButton.icon(
                  onPressed: () => context.push('/menu/$slug'),
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text('Ver menú'),
                ),
            ],
          ),
          if (dir.isNotEmpty)
            Text(dir, style: const TextStyle(fontSize: 11, color: AppColors.kTextSecondary)),
          const SizedBox(height: 4),
          const Text(
            'El negocio atiende preparación, cobro, entrega, cambios y reclamaciones del pedido. '
            'Zammpy atiende únicamente problemas técnicos de la plataforma.',
            style: TextStyle(fontSize: 11, color: AppColors.kTextMuted),
          ),
        ],
      ),
    );
  }
}

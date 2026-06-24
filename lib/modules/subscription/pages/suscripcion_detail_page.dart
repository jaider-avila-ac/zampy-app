import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/suscripcion_service.dart';
import '../../../shared/app_colors.dart';
import '../../../components/layout/sidebar.dart';

// Equivalente a src/modules/subscription/pages/SuscripcionDetailPage.jsx en React

class SuscripcionDetailPage extends StatefulWidget {
  const SuscripcionDetailPage({super.key, required this.susId});
  final int susId;

  @override
  State<SuscripcionDetailPage> createState() => _SuscripcionDetailPageState();
}

class _SuscripcionDetailPageState extends State<SuscripcionDetailPage> {
  Map<String, dynamic>? _sub;
  List<dynamic>         _pagos    = [];
  bool                  _loading  = true;
  String                _error    = '';
  bool                  _canceling = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final data = await SuscripcionService.getMiSuscripcionById(widget.susId);
      if (!mounted) return;
      setState(() {
        _sub     = data;
        _pagos   = (data['pagos'] as List?) ?? [];
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  Future<void> _cancelar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar suscripción', style: TextStyle(fontSize: 16)),
        content: const Text(
          'Tu menú seguirá publicado hasta el fin del período actual. Después se despublicará.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No, conservar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _canceling = true);
    try {
      await SuscripcionService.cancelarAlFin(widget.susId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suscripción cancelada. Correrá hasta el fin del período.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _canceling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AppSidebar(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mi suscripción',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          Builder(builder: (ctx) {
            final hasDrawer = Scaffold.maybeOf(ctx)?.hasDrawer ?? false;
            if (!hasDrawer) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.menu, size: 22),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            );
          }),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? _ErrorView(error: _error, onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final sub    = _sub!;
    final estado = sub['estado'] as String? ?? '';
    final menuId = sub['menuId'] as int?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Estado ──
        _EstadoCard(sub: sub, estado: estado),
        const SizedBox(height: 16),

        // ── Detalles ──
        _DetallesCard(sub: sub),
        const SizedBox(height: 16),

        // ── Acciones ──
        _AccionesCard(
          estado:    estado,
          menuId:    menuId,
          canceling: _canceling,
          susId:     widget.susId,
          onCancelar: _cancelar,
        ),
        const SizedBox(height: 16),

        // ── Historial de pagos ──
        if (_pagos.isNotEmpty) _PagosCard(pagos: _pagos),
      ],
    );
  }
}

// ── Estado card ───────────────────────────────────────────────────────────────
class _EstadoCard extends StatelessWidget {
  const _EstadoCard({required this.sub, required this.estado});
  final Map<String, dynamic> sub;
  final String estado;

  @override
  Widget build(BuildContext context) {
    final (color, bgColor, icon, label) = _estadoInfo(estado);
    final tipoPlan = sub['tipoPlan'] as String? ?? '';
    final planName = tipoPlan == 'trial' ? 'Prueba gratuita' : (tipoPlan.isNotEmpty ? tipoPlan : '–');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 12, color: color),
                    const SizedBox(width: 5),
                    Text(label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(planName.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Estado de tu suscripción',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          const SizedBox(height: 2),
          Text(_estadoDescripcion(estado, sub),
              style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  (Color, Color, IconData, String) _estadoInfo(String estado) {
    return switch (estado) {
      'ACTIVE'             => (const Color(0xFF16A34A), const Color(0xFFF0FDF4), Icons.check_circle_outline, 'Activa'),
      'TRIAL'              => (const Color(0xFF16A34A), const Color(0xFFF0FDF4), Icons.star_outline, 'Prueba gratuita'),
      'PAYMENT_REMINDER'   => (const Color(0xFFB45309), const Color(0xFFFFFBEB), Icons.shopping_cart_outlined, 'Aviso de pago'),
      'PAST_DUE'           => (const Color(0xFFEA580C), const Color(0xFFFFF7ED), Icons.refresh, 'Período de gracia'),
      'WAITING_ACTIVATION' => (const Color(0xFF2563EB), const Color(0xFFEFF6FF), Icons.access_time, 'Activando...'),
      'CANCELLED'          => (const Color(0xFF94A3B8), const Color(0xFFF8FAFC), Icons.cancel_outlined, 'Cancelada'),
      _                    => (const Color(0xFF64748B), const Color(0xFFF1F5F9), Icons.info_outline, estado),
    };
  }

  String _estadoDescripcion(String estado, Map<String, dynamic> sub) {
    final dias = (sub['diasRestantes'] as num?)?.toInt() ?? 0;
    return switch (estado) {
      'ACTIVE'             => dias > 0 ? 'Vence en $dias día${dias != 1 ? 's' : ''}' : 'Tu menú está activo',
      'TRIAL'              => dias > 0 ? '$dias día${dias != 1 ? 's' : ''} de prueba restantes' : 'Prueba activa',
      'PAYMENT_REMINDER'   => dias > 0 ? '$dias día${dias != 1 ? 's' : ''} para el vencimiento' : 'Próxima a vencer',
      'PAST_DUE'           => dias > 0 ? '$dias día${dias != 1 ? 's' : ''} de gracia restantes' : 'Período de gracia activo',
      'WAITING_ACTIVATION' => 'Pago aprobado, activando...',
      'CANCELLED'          => 'Tu suscripción fue cancelada',
      _                    => '',
    };
  }
}

// ── Detalles card ─────────────────────────────────────────────────────────────
class _DetallesCard extends StatelessWidget {
  const _DetallesCard({required this.sub});
  final Map<String, dynamic> sub;

  @override
  Widget build(BuildContext context) {
    final periodoFin      = sub['periodoFin'] as String?;
    final montoTotal      = sub['montoTotal'] as num?;
    final limiteProductos = (sub['limiteProductos'] as num?)?.toInt();
    final moneda          = sub['moneda'] as String? ?? 'COP';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detalles',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          if (periodoFin != null) _Row(label: 'Próximo vencimiento', value: _fmtDate(periodoFin)),
          if (montoTotal != null)
            _Row(label: 'Monto', value: '\$${_fmtPrice(montoTotal.toInt())} $moneda'),
          if (limiteProductos != null)
            _Row(label: 'Límite de productos', value: '$limiteProductos productos', isLast: true),
        ],
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _fmtPrice(int cents) {
    final n = (cents / 100).round();
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.isLast = false});
  final String label;
  final String value;
  final bool   isLast;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
          ],
        ),
      );
}

// ── Acciones card ─────────────────────────────────────────────────────────────
class _AccionesCard extends StatelessWidget {
  const _AccionesCard({
    required this.estado,
    required this.menuId,
    required this.susId,
    required this.canceling,
    required this.onCancelar,
  });

  final String   estado;
  final int?     menuId;
  final int      susId;
  final bool     canceling;
  final VoidCallback onCancelar;

  @override
  Widget build(BuildContext context) {
    final puedeRenovar = ['PAST_DUE', 'PAYMENT_REMINDER'].contains(estado);
    final puedeCancelar = ['ACTIVE', 'TRIAL', 'PAYMENT_REMINDER'].contains(estado);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Acciones',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),

          // Ver planes
          if (menuId != null)
            _ActionButton(
              icon: Icons.grid_view_outlined,
              label: 'Ver planes disponibles',
              onTap: () => context.push('/billing/$menuId'),
            ),

          // Renovar
          if (puedeRenovar && menuId != null) ...[
            const SizedBox(height: 8),
            _ActionButton(
              icon: Icons.refresh,
              label: 'Renovar suscripción',
              onTap: () => context.push('/billing/$menuId/checkout?tipo=renovacion'),
            ),
          ],

          // Cancelar
          if (puedeCancelar) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 8),
            canceling
                ? const Center(child: CircularProgressIndicator())
                : TextButton(
                    onPressed: onCancelar,
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF94A3B8),
                        padding: EdgeInsets.zero),
                    child: const Text('Cancelar suscripción',
                        style: TextStyle(fontSize: 12)),
                  ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap});
  final IconData     icon;
  final String       label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.kBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}

// ── Historial de pagos ────────────────────────────────────────────────────────
class _PagosCard extends StatelessWidget {
  const _PagosCard({required this.pagos});
  final List<dynamic> pagos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Historial de pagos',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          ...List.generate(pagos.length, (i) {
            final pago    = pagos[i] as Map<String, dynamic>;
            final isLast  = i == pagos.length - 1;
            return _PagoRow(pago: pago, isLast: isLast);
          }),
        ],
      ),
    );
  }
}

class _PagoRow extends StatelessWidget {
  const _PagoRow({required this.pago, required this.isLast});
  final Map<String, dynamic> pago;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final fecha  = pago['fechaPago'] as String? ?? pago['createdAt'] as String? ?? '';
    final monto  = (pago['monto'] as num?)?.toInt() ?? 0;
    final moneda = pago['moneda'] as String? ?? 'COP';
    final estado = pago['estado'] as String? ?? '';

    final (color, label) = switch (estado) {
      'APPROVED' => (const Color(0xFF16A34A), 'Aprobado'),
      'PENDING'  => (const Color(0xFFB45309), 'Pendiente'),
      'DECLINED' => (const Color(0xFFDC2626), 'Rechazado'),
      _          => (const Color(0xFF94A3B8), estado),
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_fmtDate(fecha),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A))),
                Text('\$${_fmtPrice(monto)} $moneda',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  String _fmtPrice(int cents) {
    final n = (cents / 100).round();
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Color(0xFF94A3B8)),
              const SizedBox(height: 12),
              Text(error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
}

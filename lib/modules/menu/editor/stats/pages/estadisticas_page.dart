import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../components/layout/sidebar.dart';
import '../../../../../services/estadisticas_service.dart';
import '../../../../../services/mis_menus_service.dart';
import '../../../../../shared/app_colors.dart';
import '../../../../../shared/app_header.dart';

// Equivalente a src/modules/menu/editor/stats/pages/EstadisticasPage.jsx (+ hooks/useEstadisticas.js).
// El rango desde/hasta se aplica a todos los indicadores; sin rango es el histórico completo.

String _num(num? n) {
  final v = (n ?? 0).round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < v.length; i++) {
    if (i > 0 && (v.length - i) % 3 == 0) buf.write('.');
    buf.write(v[i]);
  }
  return buf.toString();
}

String _money(dynamic v) => '\$ ${_num(v is num ? v : num.tryParse('$v'))}';

String _iso(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key, required this.menuId});

  /// Código público del menú.
  final String menuId;

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  Map<String, dynamic>? _stats;
  String _menuName = 'Menú';
  bool _loading = true;
  String _error = '';

  List<Map<String, dynamic>> _prodStats = const [];
  bool _loadingProd = false;
  String _prodError = '';

  DateTime? _desde;
  DateTime? _hasta;
  // Rango con el que se cargaron los datos que se están viendo.
  String? _aplicadoDesde;
  String? _aplicadoHasta;

  @override
  void initState() {
    super.initState();
    _cargar();
    MisMenusService.getResumen(widget.menuId).then((m) {
      if (mounted && m.nombre.isNotEmpty) setState(() => _menuName = m.nombre);
    }).catchError((_) {});
  }

  Future<void> _cargar() async {
    final d = _desde == null ? null : _iso(_desde!);
    final h = _hasta == null ? null : _iso(_hasta!);
    setState(() {
      _aplicadoDesde = d;
      _aplicadoHasta = h;
      _loading = _stats == null;
      _error = '';
      _loadingProd = true;
      _prodError = '';
    });
    try {
      final s = await EstadisticasService.getEstadisticas(widget.menuId, desde: d, hasta: h);
      if (mounted) setState(() => _stats = s);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudieron cargar las estadísticas.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    try {
      final p = await EstadisticasService.getEstadisticasProductos(widget.menuId, desde: d, hasta: h);
      if (mounted) setState(() => _prodStats = p);
    } catch (e) {
      if (mounted) {
        setState(() {
          _prodStats = const [];
          final m = e.toString().replaceFirst('Exception: ', '');
          _prodError = m.isEmpty ? 'No se pudieron cargar las ventas por producto.' : m;
        });
      }
    } finally {
      if (mounted) setState(() => _loadingProd = false);
    }
  }

  Future<void> _elegirFecha({required bool desde}) async {
    final ahora = DateTime.now();
    final actual = desde ? _desde : _hasta;
    final elegido = await showDatePicker(
      context: context,
      initialDate: actual ?? (desde ? (_hasta ?? ahora) : ahora),
      firstDate: desde ? DateTime(2020) : (_desde ?? DateTime(2020)),
      lastDate: desde ? (_hasta ?? ahora) : ahora,
      helpText: desde ? 'Desde' : 'Hasta',
    );
    if (elegido == null || !mounted) return;
    setState(() => desde ? _desde = elegido : _hasta = elegido);
  }

  void _limpiarRango() {
    setState(() {
      _desde = null;
      _hasta = null;
    });
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgPage,
      drawer: const AppSidebar(),
      appBar: AppHeader(title: 'Estadísticas', subtitle: _menuName),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? _ErrorBody(mensaje: _error, onRetry: _cargar)
              : RefreshIndicator(onRefresh: _cargar, child: _contenido(_stats!)),
    );
  }

  Widget _contenido(Map<String, dynamic> s) {
    final productos = (s['productos'] as List? ?? []).whereType<Map>().toList();
    final encantas = (s['encantasProductos'] as List? ?? []).whereType<Map>().toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _rango(),
        const SizedBox(height: 6),
        Text(
          _aplicadoDesde != null
              ? 'Periodo: $_aplicadoDesde a $_aplicadoHasta'
              : 'Periodo: histórico completo',
          style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted),
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(_error, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
        ],
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.35,
          children: [
            _Metrica(icon: Icons.visibility_outlined, valor: _num(s['totalVistas'] as num?), label: 'Vistas del menú'),
            _Metrica(
              icon: Icons.favorite_outline,
              color: const Color(0xFFF43F5E),
              valor: _num(s['meEncantas'] as num?),
              label: 'Me encanta (menú completo)',
            ),
            _Metrica(
              icon: Icons.shopping_cart_outlined,
              color: const Color(0xFF059669),
              valor: _num(s['totalOperaciones'] as num?),
              label: 'Operaciones entregadas',
              detalle: '${s['pedidosDomicilio'] ?? 0} domicilio · ${s['rondasMesa'] ?? 0} rondas',
            ),
            _Metrica(
              icon: Icons.trending_up,
              color: const Color(0xFFD97706),
              valor: '${(s['conversionOperaciones'] as num? ?? 0).toString().replaceAll('.', ',')}%',
              label: 'Operaciones por visita',
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _Titulo(icon: Icons.trending_up, texto: 'Productos más vistos'),
        if (productos.isEmpty)
          const _Vacio(
            icon: Icons.inventory_2_outlined,
            titulo: 'Sin datos todavía',
            texto: 'Las vistas aparecerán aquí cuando los clientes abran los detalles de los productos.',
          )
        else
          _Lista(children: [
            for (var i = 0; i < productos.length; i++)
              _FilaProducto(
                rank: i + 1,
                nombre: productos[i]['nombre']?.toString() ?? '',
                imageUrl: productos[i]['imageUrl'] as String?,
                valor: _num(productos[i]['vistas'] as num?),
                icon: Icons.visibility_outlined,
              ),
          ]),
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('Conteo de "ver más" únicos por producto.',
              style: TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
        ),
        const SizedBox(height: 24),
        const _Titulo(icon: Icons.favorite_outline, texto: 'Productos que más encantan'),
        if (encantas.isEmpty)
          const _Vacio(
            icon: Icons.favorite_outline,
            titulo: 'Sin "me encanta" todavía',
            texto: 'Aparecerán aquí los productos que les encantan a tus clientes.',
          )
        else
          _Lista(children: [
            for (final p in encantas)
              _FilaProducto(
                nombre: p['nombre']?.toString() ?? '',
                imageUrl: p['imageUrl'] as String?,
                valor: _num(p['meEncantas'] as num?),
                icon: Icons.favorite,
                iconColor: const Color(0xFFF43F5E),
              ),
          ]),
        const SizedBox(height: 24),
        const _Titulo(icon: Icons.shopping_cart_outlined, texto: 'Productos más pedidos'),
        if (_prodError.isNotEmpty)
          _Vacio(icon: Icons.error_outline, titulo: _prodError, texto: '', error: true)
        else if (_loadingProd)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_prodStats.isEmpty)
          const _Vacio(
            icon: Icons.shopping_cart_outlined,
            titulo: 'Sin datos de pedidos',
            texto: 'Los productos más pedidos aparecerán aquí cuando haya pedidos registrados.',
          )
        else
          _Lista(children: [
            for (var i = 0; i < _prodStats.length; i++) _FilaPedido(rank: i + 1, p: _prodStats[i]),
          ]),
      ],
    );
  }

  Widget _rango() {
    String etiqueta(DateTime? d, String vacio) => d == null ? vacio : _iso(d);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () => _elegirFecha(desde: true),
          icon: const Icon(Icons.calendar_today_outlined, size: 14),
          label: Text(etiqueta(_desde, 'Desde')),
        ),
        OutlinedButton.icon(
          onPressed: () => _elegirFecha(desde: false),
          icon: const Icon(Icons.calendar_today_outlined, size: 14),
          label: Text(etiqueta(_hasta, 'Hasta')),
        ),
        FilledButton(
          onPressed: _desde != null && _hasta != null ? _cargar : null,
          child: const Text('Buscar'),
        ),
        if (_desde != null || _hasta != null)
          TextButton(onPressed: _limpiarRango, child: const Text('Ver histórico completo')),
      ],
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({
    required this.icon,
    required this.valor,
    required this.label,
    this.detalle,
    this.color = AppColors.kBlue,
  });
  final IconData icon;
  final String valor;
  final String label;
  final String? detalle;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.kCardBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(valor,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.kTextPrimary)),
            ),
            Text(label, maxLines: 2, style: const TextStyle(fontSize: 11, color: AppColors.kTextSecondary)),
            if (detalle != null)
              Text(detalle!, maxLines: 1, style: const TextStyle(fontSize: 10, color: AppColors.kTextMuted)),
          ],
        ),
      );
}

class _Titulo extends StatelessWidget {
  const _Titulo({required this.icon, required this.texto});
  final IconData icon;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.kTextSecondary),
            const SizedBox(width: 6),
            Text(texto, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.kTextPrimary)),
          ],
        ),
      );
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.icon, required this.titulo, required this.texto, this.error = false});
  final IconData icon;
  final String titulo;
  final String texto;
  final bool error;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: error ? const Color(0xFFFEF2F2) : Colors.white,
          border: Border.all(color: error ? const Color(0xFFFECACA) : AppColors.kCardBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 26, color: error ? const Color(0xFFDC2626) : const Color(0xFFCBD5E1)),
            const SizedBox(height: 8),
            Text(titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: error ? const Color(0xFFB91C1C) : AppColors.kTextSecondary)),
            if (texto.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(texto, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
            ],
          ],
        ),
      );
}

class _Lista extends StatelessWidget {
  const _Lista({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.kCardBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(height: 1, color: Color(0xFFF1F5F9)),
              children[i],
            ],
          ],
        ),
      );
}

class _FilaProducto extends StatelessWidget {
  const _FilaProducto({
    required this.nombre,
    required this.imageUrl,
    required this.valor,
    required this.icon,
    this.rank,
    this.iconColor = AppColors.kTextMuted,
  });
  final int? rank;
  final String nombre;
  final String? imageUrl;
  final String valor;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            if (rank != null)
              SizedBox(
                width: 22,
                child: Text('$rank',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.kTextMuted)),
              ),
            const SizedBox(width: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 36,
                height: 36,
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(imageUrl!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const _Thumb())
                    : const _Thumb(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.kTextPrimary)),
            ),
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 4),
            Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.kTextPrimary)),
          ],
        ),
      );
}

class _FilaPedido extends StatelessWidget {
  const _FilaPedido({required this.rank, required this.p});
  final int rank;
  final Map<String, dynamic> p;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text('$rank',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.kTextMuted)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['prodNombre']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.kTextPrimary)),
                  Text('${p['pedidosDomicilio'] ?? 0} domicilio · ${p['rondasMesa'] ?? 0} mesa',
                      style: const TextStyle(fontSize: 11, color: AppColors.kTextMuted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${_num(p['totalPedidos'] as num?)} oper. · ${_num(p['totalUnidades'] as num?)} und.',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.kBlue)),
                Text(_money(p['ingresos']),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF047857))),
              ],
            ),
          ],
        ),
      );
}

class _Thumb extends StatelessWidget {
  const _Thumb();

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFFF1F5F9),
        child: const Icon(Icons.restaurant_outlined, size: 16, color: Color(0xFFCBD5E1)),
      );
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.mensaje, required this.onRetry});
  final String mensaje;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mensaje.isEmpty ? 'No se pudieron cargar las estadísticas.' : mensaje,
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Color(0xFFDC2626))),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh, size: 16), label: const Text('Reintentar')),
              TextButton(onPressed: () => context.go('/menus'), child: const Text('Volver a mis menús')),
            ],
          ),
        ),
      );
}

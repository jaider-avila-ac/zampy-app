import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../../services/api.dart';
import '../../../../../shared/app_colors.dart';
import '../../../../../shared/app_header.dart';

// Equivalente a src/modules/menu/editor/stats/pages/EstadisticasPage.jsx en React

class EstadisticasPage extends StatefulWidget {
  const EstadisticasPage({super.key, required this.menuId});
  final int menuId;

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Map<String, dynamic>? _stats;
  String  _menuName = 'Menú';
  bool    _loading  = true;
  String  _error    = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String?> _token() async {
    try {
      final raw = await _storage.read(key: 'auth');
      if (raw == null) return null;
      return (jsonDecode(raw) as Map<String, dynamic>)['token'] as String?;
    } catch (_) { return null; }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final tok     = await _token();
      final headers = tok != null
          ? {'Authorization': 'Bearer $tok', 'Content-Type': 'application/json'}
          : <String, String>{};

      final results = await Future.wait([
        http.get(Uri.parse('$kApiBase/api/v1/menus/${widget.menuId}/estadisticas'),
            headers: headers).timeout(const Duration(seconds: 15)),
        http.get(Uri.parse('$kApiBase/api/v1/menus/${widget.menuId}'),
            headers: headers).timeout(const Duration(seconds: 15)),
      ]);

      final statsRes = results[0];
      final menuRes  = results[1];

      if (statsRes.statusCode != 200 || menuRes.statusCode != 200) {
        throw Exception('Error al cargar');
      }

      final statsData = jsonDecode(statsRes.body) as Map<String, dynamic>;
      final menuData  = jsonDecode(menuRes.body)  as Map<String, dynamic>;
      final draft     = menuData['draft'] as Map<String, dynamic>?;
      final info      = draft?['info'] as Map<String, dynamic>?;

      setState(() {
        _stats    = statsData;
        _menuName = info?['name'] as String? ?? 'Menú';
        _loading  = false;
      });
    } catch (_) {
      setState(() { _error = 'No se pudieron cargar las estadísticas.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgPage,
      appBar: AppHeader(title: _menuName),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.kBlue))
          : _error.isNotEmpty
              ? _ErrorBody(message: _error, onRetry: _load,
                  onBack: () => context.pop())
              : RefreshIndicator(
                  color: AppColors.kBlue,
                  onRefresh: _load,
                  child: _Body(stats: _stats!, menuId: widget.menuId),
                ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.stats, required this.menuId});
  final Map<String, dynamic> stats;
  final int menuId;

  @override
  Widget build(BuildContext context) {
    final totalVistas = stats['totalVistas'] as int? ?? 0;
    final productos   = (stats['productos'] as List? ?? [])
        .cast<Map<String, dynamic>>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [

        // ── Total vistas ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(20),
            border:       Border.all(color: AppColors.kCardBorder),
          ),
          child: Row(
            children: [
              const Icon(Icons.visibility_outlined,
                  size: 32, color: AppColors.kBlue),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fmtNum(totalVistas),
                    style: const TextStyle(
                      fontSize:   34,
                      fontWeight: FontWeight.w900,
                      color:      AppColors.kTextPrimary,
                      height:     1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Vistas únicas del menú',
                      style: TextStyle(fontSize: 13, color: AppColors.kTextMuted)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Productos más vistos ──────────────────────────────────────────
        const Row(
          children: [
            Icon(Icons.trending_up_rounded, size: 15, color: AppColors.kTextSecondary),
            SizedBox(width: 6),
            Text('Productos más vistos',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: AppColors.kTextPrimary)),
          ],
        ),
        const SizedBox(height: 10),

        if (productos.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: AppColors.kCardBorder),
            ),
            child: const Column(
              children: [
                Icon(Icons.inventory_2_outlined, size: 32, color: AppColors.kSkeleton),
                SizedBox(height: 10),
                Text('Sin datos todavía',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.kTextMuted)),
                SizedBox(height: 4),
                Text(
                  'Las vistas aparecerán aquí cuando los clientes abran los detalles de los productos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.kTextMuted, height: 1.5),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(20),
              border:       Border.all(color: AppColors.kCardBorder),
            ),
            child: Column(
              children: [
                // Encabezado tabla
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color:        Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 20,
                          child: Text('#', style: TextStyle(fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.kTextMuted))),
                      SizedBox(width: 12),
                      Expanded(child: Text('Producto',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                              color: AppColors.kTextMuted))),
                      Row(children: [
                        Icon(Icons.visibility_outlined, size: 10,
                            color: AppColors.kTextMuted),
                        SizedBox(width: 3),
                        Text('Vistas', style: TextStyle(fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.kTextMuted)),
                      ]),
                    ],
                  ),
                ),
                // Filas
                ...productos.asMap().entries.map((e) => _ProductRow(
                  producto: e.value,
                  rank:     e.key + 1,
                  isLast:   e.key == productos.length - 1,
                )),
              ],
            ),
          ),

        const SizedBox(height: 12),
        const Text(
          'Conteo de "ver más" únicos por producto.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.kTextMuted),
        ),
      ],
    );
  }

  static String _fmtNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.producto,
    required this.rank,
    required this.isLast,
  });
  final Map<String, dynamic> producto;
  final int  rank;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final nombre   = producto['nombre']   as String? ?? '';
    final imageUrl = producto['imageUrl'] as String?;
    final vistas   = producto['vistas']   as int? ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900,
                  color: AppColors.kSkeleton),
            ),
          ),
          const SizedBox(width: 12),
          // Imagen o placeholder
          SizedBox(
            width: 40, height: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover,
                      errorBuilder: (ctx, e, s) => _ImgPlaceholder())
                  : _ImgPlaceholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(nombre,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.kTextPrimary)),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              const Icon(Icons.visibility_outlined, size: 13,
                  color: AppColors.kTextMuted),
              const SizedBox(width: 4),
              Text(
                vistas.toString(),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900,
                    color: AppColors.kBlue),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImgPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.kSkeleton,
      alignment: Alignment.center,
      child: const Icon(Icons.inventory_2_outlined, size: 18,
          color: AppColors.kTextMuted),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });
  final String   message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.kTextMuted)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Reintentar',
                      style: TextStyle(color: AppColors.kBlue)),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: onBack,
                  child: const Text('Volver a mis menús',
                      style: TextStyle(color: AppColors.kTextMuted)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

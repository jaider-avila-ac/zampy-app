import 'package:flutter/material.dart';
import '../../core/app_cache.dart';
import '../../shared/app_colors.dart';
import 'logro_model.dart';
import 'logro_service.dart';

/// Equivalente a LogrosPage.jsx — progreso de logros del usuario.
/// Solo accesible si el usuario tiene al menos un menú.
class LogrosScreen extends StatefulWidget {
  const LogrosScreen({super.key});

  @override
  State<LogrosScreen> createState() => _LogrosScreenState();
}

class _LogrosScreenState extends State<LogrosScreen> {
  List<Logro> _logros = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final cached = AppCache.get<List<Logro>>('logros');
    if (cached != null) {
      _logros = cached;
      _loading = false;
    }
    _bgFetch();
  }

  Future<void> _bgFetch() async {
    final data = await LogroService.miProgreso();
    if (!mounted) return;
    AppCache.set('logros', data);
    setState(() { _logros = data; _loading = false; });
  }

  Future<void> _load() => _bgFetch();

  List<Logro> get _pendientes    => _logros.where((l) => !l.desbloqueado).toList();
  List<Logro> get _desbloqueados => _logros.where((l) => l.desbloqueado).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgPage,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppColors.kCardBorder)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back,
                      size: 20, color: AppColors.kTextSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
                const Icon(Icons.emoji_events_outlined,
                    size: 18, color: AppColors.kBlue),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Logros',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kTextPrimary,
                    ),
                  ),
                ),
                if (!_loading && _desbloqueados.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.kSkeleton,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_desbloqueados.length} desbloqueado${_desbloqueados.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.kTextSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: AppColors.kBlue),
        ),
      );
    }

    if (_logros.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('No hay logros configurados',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kTextPrimary)),
            SizedBox(height: 4),
            Text('Vuelve pronto.',
                style: TextStyle(fontSize: 13, color: AppColors.kTextMuted)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.kBlue,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Banner informativo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              border: Border.all(color: const Color(0xFFC7D2FE)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Los días que ganas se aplican automáticamente a tu publicación más reciente.',
              style: TextStyle(fontSize: 12, color: AppColors.kBlue, height: 1.5),
            ),
          ),

          // Por desbloquear
          if (_pendientes.isNotEmpty) ...[
            const _SectionLabel(label: 'Por desbloquear'),
            const SizedBox(height: 8),
            ..._pendientes.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _LogroCard(logro: l),
                )),
            const SizedBox(height: 16),
          ],

          // Desbloqueados
          if (_desbloqueados.isNotEmpty) ...[
            const _SectionLabel(label: 'Desbloqueados'),
            const SizedBox(height: 8),
            ..._desbloqueados.map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _LogroCard(logro: l),
                )),
          ],
        ],
      ),
    );
  }
}

// ── Widgets internos ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.kTextMuted,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _LogroCard extends StatelessWidget {
  const _LogroCard({required this.logro});
  final Logro logro;

  @override
  Widget build(BuildContext context) {
    final icon = _iconForCondicion(logro.condicion);
    final label = _labelForCondicion(logro.condicion);
    final faltan = (logro.cantidad - logro.progreso).clamp(0, logro.cantidad);
    final pct = logro.cantidad > 0
        ? (logro.progreso / logro.cantidad).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: logro.desbloqueado
              ? const Color(0xFF6EE7B7) // emerald-200
              : AppColors.kCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícono + texto
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 18, color: AppColors.kBlue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            logro.nombre,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.kTextPrimary,
                              height: 1.3,
                            ),
                          ),
                          if (logro.descripcion != null &&
                              logro.descripcion!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              logro.descripcion!,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.kTextMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badge días recompensa
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.kBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+${logro.diasRecompensa} días',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Estado: desbloqueado o barra de progreso
          if (logro.desbloqueado) ...[
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 13, color: Color(0xFF059669)),
                const SizedBox(width: 4),
                const Text(
                  'Desbloqueado',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                  ),
                ),
                if (logro.desbloqueadoEn != null) ...[
                  const Text(
                    ' · ',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.kTextMuted),
                  ),
                  Text(
                    _formatDate(logro.desbloqueadoEn!),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.kTextMuted),
                  ),
                ],
              ],
            ),
          ] else ...[
            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: AppColors.kSkeleton,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.kBlue),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 11, color: AppColors.kTextMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${logro.progreso} / ${logro.cantidad} $label',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.kTextMuted),
                    ),
                  ],
                ),
                Text(
                  faltan > 0 ? 'Faltan $faltan' : '¡Listo!',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static IconData _iconForCondicion(String condicion) {
    switch (condicion) {
      case 'ME_ENCANTAS':  return Icons.favorite_border;
      case 'VISITAS':      return Icons.visibility_outlined;
      case 'RESENAS':      return Icons.chat_bubble_outline;
      case 'INVITACIONES': return Icons.people_outline;
      default:             return Icons.emoji_events_outlined;
    }
  }

  static String _labelForCondicion(String condicion) {
    switch (condicion) {
      case 'ME_ENCANTAS':  return 'me encantas';
      case 'VISITAS':      return 'visitas';
      case 'RESENAS':      return 'reseñas';
      case 'INVITACIONES': return 'invitaciones completadas';
      default:             return condicion.toLowerCase();
    }
  }

  static String _formatDate(DateTime dt) {
    const meses = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${dt.day} ${meses[dt.month]} ${dt.year}';
  }
}

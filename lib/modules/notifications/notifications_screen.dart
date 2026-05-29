import 'package:flutter/material.dart';
import '../../core/app_cache.dart';
import '../../shared/app_colors.dart';
import 'models/notification_item.dart';
import 'notification_service.dart';

/// Equivalente a NotificationsPage.jsx — lista de notificaciones del usuario.
/// Permite marcar como leída (individual o todas) y eliminar.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final cached = AppCache.get<List<NotificationItem>>('notifications');
    if (cached != null) { _items = cached; _loading = false; }
    _bgFetch();
  }

  Future<void> _bgFetch() async {
    final data = await NotificationService.getNotificaciones();
    if (!mounted) return;
    AppCache.set('notifications', data);
    setState(() { _items = data; _loading = false; });
  }

  Future<void> _loadNotifications() => _bgFetch();

  // ── Marcar una como leída (optimista) ──────────────────────────────────────
  Future<void> _markRead(int id) async {
    setState(() {
      _items = _items
          .map((n) => n.id == id ? n.copyWith(leida: true) : n)
          .toList();
    });
    NotificationService.marcarLeida(id); // fire-and-forget
  }

  // ── Marcar todas como leídas (optimista) ───────────────────────────────────
  Future<void> _markAllRead() async {
    setState(() {
      _items = _items.map((n) => n.copyWith(leida: true)).toList();
    });
    NotificationService.marcarTodasLeidas(); // fire-and-forget
  }

  // ── Eliminar (optimista) ───────────────────────────────────────────────────
  void _delete(int id) {
    setState(() => _items = _items.where((n) => n.id != id).toList());
    NotificationService.eliminar(id); // fire-and-forget
  }

  int get _unreadCount => _items.where((n) => !n.leida).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgPage,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
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
                const Expanded(
                  child: Text(
                    'Notificaciones',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kTextPrimary,
                    ),
                  ),
                ),
                // "Marcar todas" — solo si hay sin leer
                if (!_loading && _unreadCount > 0)
                  TextButton.icon(
                    onPressed: _markAllRead,
                    icon: const Icon(Icons.done_all,
                        size: 15, color: AppColors.kBlue),
                    label: const Text(
                      'Marcar todas',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.kBlue,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_loading) return _buildLoading();
    if (_items.isEmpty) return _buildEmpty();
    return _buildList();
  }

  Widget _buildLoading() {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.kBlue,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.kCardBorder),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 40, color: AppColors.kTextMuted),
            SizedBox(height: 12),
            Text(
              'Sin notificaciones',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.kTextPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Aquí aparecerán las reseñas, calificaciones\ny actividad de tus menús.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.kTextMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      color: AppColors.kBlue,
      onRefresh: _loadNotifications,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Subtítulo con conteo
          if (_unreadCount > 0) ...[
            Text(
              '$_unreadCount sin leer',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.kTextMuted),
            ),
            const SizedBox(height: 12),
          ],
          // Tiles
          ...List.generate(_items.length, (i) {
            final n = _items[i];
            return Padding(
              padding: EdgeInsets.only(bottom: i < _items.length - 1 ? 8 : 0),
              child: _NotifTile(
                item: n,
                onMarkRead: () => _markRead(n.id),
                onDelete: () => _delete(n.id),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Tile individual ──────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  const _NotifTile({
    required this.item,
    required this.onMarkRead,
    required this.onDelete,
  });

  final NotificationItem item;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final unread = !item.leida;
    final bg     = unread ? const Color(0xFFEEF2FF) : Colors.white;
    final border = unread ? const Color(0xFFC7D2FE) : AppColors.kCardBorder;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Área izquierda clickeable (ícono + texto) ─────────────────────
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: unread ? onMarkRead : null,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ícono del tipo
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      _iconForTipo(item.tipo),
                      size: 18,
                      color: AppColors.kBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // actorNombre + label + entidadNombre
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.kTextPrimary,
                              height: 1.4,
                            ),
                            children: [
                              if (item.actorNombre != null &&
                                  item.actorNombre!.isNotEmpty)
                                TextSpan(
                                  text: item.actorNombre,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                              if (_labelForTipo(item.tipo).isNotEmpty)
                                TextSpan(
                                    text: ' ${_labelForTipo(item.tipo)}'),
                              if (item.entidadNombre != null &&
                                  item.entidadNombre!.isNotEmpty)
                                TextSpan(
                                  text: ' "${item.entidadNombre}"',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.kTextSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Vista previa
                        if (item.vistaPrevia != null &&
                            item.vistaPrevia!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            item.vistaPrevia!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.kTextSecondary,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        // Tiempo relativo
                        const SizedBox(height: 4),
                        Text(
                          item.tiempoRelativo,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.kTextMuted),
                        ),
                        // Acción "Reactivar menú" para tipos de suscripción
                        if (_esTipoAccion(item.tipo)) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.credit_card_outlined,
                                  size: 11, color: AppColors.kRed),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () {}, // TODO: navegar a suscripción
                                child: const Text(
                                  'Reactivar menú',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.kRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Punto sin leer
                  if (unread)
                    const Padding(
                      padding: EdgeInsets.only(top: 4, left: 6),
                      child: _UnreadDot(),
                    ),
                ],
              ),
            ),
          ),
          // ── Botón eliminar ────────────────────────────────────────────────
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Padding(
              padding: EdgeInsets.only(left: 4, top: 1),
              child: Icon(
                Icons.delete_outline,
                size: 18,
                color: AppColors.kTextMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Ícono según tipo (equivale a ICON_MAP en JSX) ─────────────────────────
  static IconData _iconForTipo(String tipo) {
    switch (tipo) {
      case 'nueva_resena':
        return Icons.chat_bubble_outline;
      case 'nuevo_me_encanta':
        return Icons.favorite_border;
      case 'nueva_calificacion':
        return Icons.star_outline;
      case 'prueba_por_vencer':
      case 'RECORDATORIO_PAGO':
        return Icons.access_time_outlined;
      case 'pago_fallido':
      case 'PAGO_VENCIDO':
      case 'PAGO_EXPIRADO':
        return Icons.warning_amber_outlined;
      case 'plan_suspendido':
      case 'SUSCRIPCION_SUSPENDIDA':
        return Icons.block_outlined;
      case 'nuevo_colaborador':
        return Icons.person_add_outlined;
      case 'PAGO_APROBADO':
      case 'PAGO_RENOVACION':
        return Icons.check_circle_outline;
      case 'PLAN_ACTUALIZADO':
        return Icons.bolt_outlined;
      case 'LOGRO_DESBLOQUEADO':
        return Icons.emoji_events_outlined;
      case 'CUPON_APLICADO':
      case 'CUPON_VENCIDO':
        return Icons.confirmation_number_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  // ── Texto descriptivo (equivale a labelFor en JSX) ────────────────────────
  static String _labelForTipo(String tipo) {
    switch (tipo) {
      case 'nueva_resena':
        return 'dejó una reseña en tu menú';
      case 'nuevo_me_encanta':
        return 'marcó Me encanta en tu menú';
      case 'nueva_calificacion':
        return 'calificó un plato de';
      case 'nuevo_colaborador':
        return 'te invitó a colaborar en';
      case 'PAGO_APROBADO':
        return 'Tu pago fue aprobado —';
      case 'PAGO_RENOVACION':
        return 'Renovación completada —';
      case 'PLAN_ACTUALIZADO':
        return 'Plan actualizado —';
      case 'LOGRO_DESBLOQUEADO':
        return '¡Lograste un nuevo logro!';
      case 'CUPON_APLICADO':
        return 'Cupón aplicado —';
      case 'CUPON_VENCIDO':
        return 'Cupón vencido —';
      case 'PAGO_EXPIRADO':
        return 'Pago cancelado —';
      default:
        return '';
    }
  }

  static bool _esTipoAccion(String tipo) =>
      tipo == 'SUSCRIPCION_SUSPENDIDA' || tipo == 'plan_suspendido';
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.kBlue,
        shape: BoxShape.circle,
      ),
    );
  }
}

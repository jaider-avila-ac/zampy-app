import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../context/notificacion_context.dart';
import '../hooks/use_notifications.dart';
import '../components/notification_item.dart';
import '../../../shared/app_colors.dart';
import '../../../shared/app_header.dart';
import '../../../components/layout/sidebar.dart';
import '../../../shared/responsive.dart';

// Equivalente a src/modules/notifications/pages/NotificationsPage.jsx

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UseNotifications()..load(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  int? _lastNotifSeq;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificacionContext>().resetUnread();
    });
  }

  void _goBack() {
    if (GoRouter.of(context).canPop()) {
      GoRouter.of(context).pop();
    } else {
      context.go('/');
    }
  }

  void _onLiveNotification(UseNotifications ctrl, NotificacionContext notif) {
    if (_lastNotifSeq == null) {
      _lastNotifSeq = notif.notificacionSeq;
      return;
    }
    if (_lastNotifSeq == notif.notificacionSeq) return;
    _lastNotifSeq = notif.notificacionSeq;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ctrl.refresh();
      notif.resetUnread();
    });
  }

  Future<void> _markAllRead(
    UseNotifications ctrl,
    NotificacionContext notif,
  ) async {
    await ctrl.markAllRead();
    if (!mounted) return;
    if (ctrl.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ctrl.error!)));
      ctrl.clearError();
    } else {
      notif.resetUnread();
    }
  }

  // los pedidos (del cliente y del negocio) se abren encima, para volver a las notificaciones
  void _navigate(String destino) {
    if (destino == '/pedidos' || RegExp(r'^/menus/[^/]+/pedidos$').hasMatch(destino)) {
      context.push(destino);
      return;
    }
    context.go(destino);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<UseNotifications>();
    final notifCtx = context.watch<NotificacionContext>();
    _onLiveNotification(ctrl, notifCtx);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) => _goBack(),
      child: Scaffold(
        backgroundColor: AppColors.kBgPage,
        drawer: const AppSidebar(),
        appBar: AppHeader(
          title: 'Notificaciones',
          subtitle: ctrl.unread > 0 ? '${ctrl.unread} sin leer' : null,
          actions: [
            if (ctrl.unread > 0)
              TextButton.icon(
                onPressed: () => _markAllRead(ctrl, notifCtx),
                icon: const Icon(
                  Icons.done_all,
                  size: 14,
                  color: AppColors.kBlue,
                ),
                label: const Text(
                  'Marcar leídas',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kBlue,
                  ),
                ),
              ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            if (!notifCtx.websocketConectado)
              SliverPadding(
                padding: contenidoPadding(context, horizontal: 20, top: 0, bottom: 12),
                sliver: SliverToBoxAdapter(
                  child: _ConnectionNotice(error: notifCtx.websocketError),
                ),
              ),

            if (ctrl.loading && ctrl.items.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.kBlue),
                ),
              )
            else if (ctrl.error != null && ctrl.items.isEmpty)
              SliverPadding(
                padding: contenidoPadding(context, horizontal: 20, top: 0, bottom: 0),
                sliver: SliverToBoxAdapter(
                  child: _ErrorCard(
                    message: ctrl.error!,
                    onRetry: ctrl.refresh,
                  ),
                ),
              )
            else if (ctrl.items.isEmpty)
              SliverPadding(
                padding: contenidoPadding(context, horizontal: 20, top: 0, bottom: 0),
                sliver: const SliverToBoxAdapter(child: _EmptyCard()),
              )
            else ...[
              SliverPadding(
                padding: contenidoPadding(context, horizontal: 20, top: 0, bottom: 8),
                sliver: SliverList.separated(
                  itemCount: ctrl.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final notif = ctrl.items[i];
                    return NotificationItem(
                      notif: notif,
                      onMarkRead: ctrl.markRead,
                      onDelete: ctrl.deleteNotif,
                      onNavigate: _navigate,
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: contenidoPadding(context, horizontal: 20, top: 0, bottom: 32),
                sliver: SliverToBoxAdapter(
                  child: _LoadMore(
                    hayMas: ctrl.hayMas,
                    cargando: ctrl.loadingMore,
                    error: ctrl.error,
                    onTap: ctrl.loadMore,
                    onRetry: ctrl.loadMore,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConnectionNotice extends StatelessWidget {
  const _ConnectionNotice({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_tethering_off,
            size: 15,
            color: Color(0xFFB45309),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error ?? 'Conectando en tiempo real…',
              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.kCardBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 36,
            color: AppColors.kTextMuted,
          ),
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
            'Aquí aparecerán las reseñas, calificaciones y actividad de tus menús.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.kTextMuted),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.kCardBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 34,
            color: AppColors.kTextMuted,
          ),
          const SizedBox(height: 10),
          const Text(
            'No se pudieron cargar las notificaciones',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.kTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.kTextMuted),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 15),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _LoadMore extends StatelessWidget {
  const _LoadMore({
    required this.hayMas,
    required this.cargando,
    required this.error,
    required this.onTap,
    required this.onRetry,
  });

  final bool hayMas;
  final bool cargando;
  final String? error;
  final Future<void> Function() onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.kRed),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (!hayMas) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Center(
        child: OutlinedButton(
          onPressed: cargando ? null : onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.kTextSecondary,
            side: const BorderSide(color: AppColors.kCardBorder),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cargando) ...[
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
                const SizedBox(width: 6),
              ],
              Text(cargando ? 'Cargando…' : 'Cargar más'),
            ],
          ),
        ),
      ),
    );
  }
}

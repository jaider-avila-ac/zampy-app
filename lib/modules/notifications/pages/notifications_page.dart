import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../context/notificacion_context.dart';
import '../hooks/use_notifications.dart';
import '../components/notification_item.dart';
import '../../../shared/app_colors.dart';
import '../../../shared/app_header.dart';
import '../../../components/layout/sidebar.dart';

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

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<UseNotifications>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) => _goBack(),
      child: Scaffold(
        backgroundColor: AppColors.kBgPage,
        drawer: const AppSidebar(),
        appBar: AppHeader(
          title:    'Notificaciones',
          subtitle: ctrl.unread > 0 ? '${ctrl.unread} sin leer' : null,
          actions: [
            if (ctrl.unread > 0)
              TextButton.icon(
                onPressed: ctrl.markAllRead,
                icon: const Icon(Icons.done_all,
                    size: 14, color: AppColors.kBlue),
                label: const Text(
                  'Marcar leídas',
                  style: TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    color:      AppColors.kBlue,
                  ),
                ),
              ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            if (ctrl.loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.kBlue),
                ),
              )

            else if (ctrl.items.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 48),
                    decoration: BoxDecoration(
                      color:        Colors.white,
                      border:       Border.all(color: AppColors.kCardBorder),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.notifications_off_outlined,
                            size: 36, color: AppColors.kTextMuted),
                        SizedBox(height: 12),
                        Text(
                          'Sin notificaciones',
                          style: TextStyle(
                            fontSize:   15,
                            fontWeight: FontWeight.w700,
                            color:      AppColors.kTextPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Aquí aparecerán las reseñas, calificaciones y actividad de tus menús.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13, color: AppColors.kTextMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              )

            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList.separated(
                  itemCount: ctrl.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final notif = ctrl.items[i];
                    return NotificationItem(
                      notif:      notif,
                      onMarkRead: ctrl.markRead,
                      onDelete:   ctrl.deleteNotif,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../services/colaboracion_service.dart';
import '../../../services/mis_menus_service.dart';
import '../models/notification_model.dart';
import '../../../shared/app_colors.dart';

// Equivalente a src/modules/notifications/components/NotificationItem.jsx

// Mapa tipo → ícono (equivalente a ICON_MAP en React)
IconData _iconFor(String tipo) => switch (tipo) {
  'NUEVA_RESENA' => Icons.message_outlined,
  'NUEVO_ME_ENCANTA' => Icons.favorite_outline,
  'NUEVA_CALIFICACION' => Icons.star_outline,
  'NUEVO_COLABORADOR' => Icons.person_add_outlined,
  'COLABORACION_ACEPTADA' => Icons.check_circle_outline,
  'COLABORACION_RECHAZADA' => Icons.cancel_outlined,
  'TRIAL_INICIADO' => Icons.check_circle_outline,
  'RECORDATORIO_TRIAL' => Icons.access_time_outlined,
  'RECORDATORIO_PAGO' => Icons.access_time_outlined,
  'PAGO_VENCIDO' => Icons.warning_amber_outlined,
  'SUSCRIPCION_SUSPENDIDA' => Icons.block_outlined,
  'PAGO_APROBADO' => Icons.check_circle_outline,
  'PAGO_RENOVACION' => Icons.check_circle_outline,
  'PLAN_ACTUALIZADO' => Icons.bolt_outlined,
  'LOGRO_DESBLOQUEADO' => Icons.emoji_events_outlined,
  'CUPON_APLICADO' => Icons.confirmation_number_outlined,
  'CUPON_VENCIDO' => Icons.confirmation_number_outlined,
  'PAGO_EXPIRADO' => Icons.cancel_outlined,
  'MENU_PUBLICADO' => Icons.check_box_outlined,
  'NUEVO_PEDIDO' => Icons.receipt_long_outlined,
  'PEDIDO_EN_PROCESO' => Icons.receipt_long_outlined,
  'PEDIDO_ENTREGADO' => Icons.check_circle_outline,
  'PEDIDO_CANCELADO' => Icons.cancel_outlined,
  'MESA_ORDEN_CANCELADA' => Icons.cancel_outlined,
  'PEDIDO_CONFIRMADO' => Icons.check_circle_outline,
  'PEDIDO_CANCELADO_CLIENTE' => Icons.cancel_outlined,
  'TRANSFERENCIA_PENDIENTE' => Icons.swap_horiz_outlined,
  'TRANSFERENCIA_ACEPTADA' => Icons.check_circle_outline,
  'TRANSFERENCIA_RECHAZADA' => Icons.cancel_outlined,
  _ => Icons.notifications_outlined,
};

// Equivalente a labelFor() en React
String _labelFor(String tipo) => switch (tipo) {
  'NUEVA_RESENA' => 'dejó una reseña en tu menú',
  'NUEVO_ME_ENCANTA' => 'marcó Me encanta en tu menú',
  'NUEVA_CALIFICACION' => 'calificó un plato de',
  'NUEVO_COLABORADOR' => 'te invitó a colaborar en',
  'COLABORACION_ACEPTADA' => 'aceptó tu invitación de colaboración en',
  'COLABORACION_RECHAZADA' => 'rechazó tu invitación de colaboración en',
  'TRIAL_INICIADO' => 'Periodo de prueba iniciado —',
  'PAGO_APROBADO' => 'Pago aprobado —',
  'PAGO_RENOVACION' => 'Renovación completada —',
  'PLAN_ACTUALIZADO' => 'Plan actualizado —',
  'RECORDATORIO_TRIAL' => 'Prueba por vencer —',
  'RECORDATORIO_PAGO' => 'Recordatorio de pago —',
  'PAGO_VENCIDO' => 'Suscripción vencida —',
  'SUSCRIPCION_SUSPENDIDA' => 'Menú suspendido —',
  'PAGO_EXPIRADO' => 'Pago cancelado —',
  'LOGRO_DESBLOQUEADO' => '¡Lograste un nuevo logro!',
  'CUPON_APLICADO' => 'Cupón aplicado —',
  'CUPON_VENCIDO' => 'Cupón vencido —',
  'MENU_PUBLICADO' => 'Menú publicado —',
  'NUEVO_PEDIDO' => 'realizó un pedido en',
  'PEDIDO_EN_PROCESO' => 'está preparando tu pedido',
  'PEDIDO_ENTREGADO' => 'marcó tu pedido como entregado',
  'PEDIDO_CANCELADO' => 'canceló tu pedido',
  'MESA_ORDEN_CANCELADA' => 'canceló la orden de la mesa',
  'PEDIDO_CONFIRMADO' => 'confirmó haber recibido su pedido en',
  'PEDIDO_CANCELADO_CLIENTE' => 'canceló su pedido en',
  'TRANSFERENCIA_PENDIENTE' => 'quiere transferirte el menú',
  'TRANSFERENCIA_ACEPTADA' => 'aceptó la transferencia del menú',
  'TRANSFERENCIA_RECHAZADA' => 'rechazó la transferencia del menú',
  _ => '',
};

// Tipos que muestran un botón de acción (pedidos, suscripción o plan).
const _tiposConAccion = {
  'SUSCRIPCION_SUSPENDIDA',
  'RECORDATORIO_TRIAL',
  'RECORDATORIO_PAGO',
  'PAGO_VENCIDO',
  'NUEVO_PEDIDO',
  'PEDIDO_CONFIRMADO',
  'PEDIDO_CANCELADO_CLIENTE',
  'PEDIDO_EN_PROCESO',
  'PEDIDO_ENTREGADO',
  'PEDIDO_CANCELADO',
};

// Tipos que dicen "Adquirir plan" (vs "Renovar plan")
const _tiposAdquirir = {'RECORDATORIO_TRIAL', 'SUSCRIPCION_SUSPENDIDA'};

// Notificaciones de pedidos del admin: entidadCodigo = menú.
const _tiposPedidoAdmin = {
  'NUEVO_PEDIDO',
  'PEDIDO_CONFIRMADO',
  'PEDIDO_CANCELADO_CLIENTE',
};

// Notificaciones de pedidos del cliente (sin menú).
const _tiposPedidoCliente = {
  'PEDIDO_EN_PROCESO',
  'PEDIDO_ENTREGADO',
  'PEDIDO_CANCELADO',
};

class NotificationItem extends StatefulWidget {
  const NotificationItem({
    super.key,
    required this.notif,
    required this.onMarkRead,
    required this.onDelete,
    required this.onNavigate,
  });

  final NotificationModel notif;
  final ValueChanged<String> onMarkRead;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onNavigate;

  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  bool _respondiendo = false;
  String? _respuesta; // 'aceptada' | 'rechazada'
  String? _errorResp;

  bool get _esTransferencia => widget.notif.tipo == 'TRANSFERENCIA_PENDIENTE';
  bool get _esInvitacionColaboracion =>
      widget.notif.tipo == 'NUEVO_COLABORADOR';
  bool get _esInvitacionPendiente =>
      _esTransferencia || _esInvitacionColaboracion;
  bool get _tieneAccion => _tiposConAccion.contains(widget.notif.tipo);
  bool get _pedidoAdmin => _tiposPedidoAdmin.contains(widget.notif.tipo);
  bool get _pedidoCliente => _tiposPedidoCliente.contains(widget.notif.tipo);

  Future<void> _responder(String accion) async {
    final menuId = widget.notif.entidadCodigo;
    if (menuId == null) return;
    setState(() {
      _respondiendo = true;
      _errorResp = null;
    });
    try {
      if (_esInvitacionColaboracion) {
        if (accion == 'aceptar') {
          await ColaboracionService.aceptarColaboracion(menuId);
        } else {
          await ColaboracionService.rechazarColaboracion(menuId);
        }
      } else {
        if (accion == 'aceptar') {
          await ColaboracionService.aceptarTransferencia(menuId);
        } else {
          await ColaboracionService.rechazarTransferencia(menuId);
        }
      }
      // El menú entra/sale de "Mis menús" o "Colaboraciones".
      MisMenusService.invalidate();
      if (!mounted) return;
      setState(
        () => _respuesta = accion == 'aceptar' ? 'aceptada' : 'rechazada',
      );
      widget.onMarkRead(widget.notif.codigo);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorResp = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _respondiendo = false);
    }
  }

  void _irASuscripcion() {
    final codigo = widget.notif.entidadCodigo;
    widget.onNavigate(codigo != null ? '/billing/$codigo' : '/suscripcion');
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notif;
    final label = _labelFor(n.tipo);
    final bgColor = n.leida
        ? Colors.white
        : const Color(0xFFEEF2FF); // indigo-50
    final border = n.leida
        ? AppColors.kCardBorder
        : const Color(0xFFC7D2FE); // indigo-200

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Área principal (ícono + texto)
          Expanded(
            child: GestureDetector(
              onTap: !n.leida && !_esInvitacionPendiente
                  ? () => widget.onMarkRead(n.codigo)
                  : null,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ícono
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      _iconFor(n.tipo),
                      size: 18,
                      color: AppColors.kBlueLight,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Descripción: actorNombre + label + entidadNombre
                        Text.rich(
                          TextSpan(
                            children: [
                              if (n.actorNombre != null)
                                TextSpan(
                                  text: n.actorNombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.kTextPrimary,
                                  ),
                                ),
                              if (label.isNotEmpty) TextSpan(text: ' $label'),
                              if (n.entidadNombre != null)
                                TextSpan(
                                  text: ' "${n.entidadNombre}"',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.kTextSecondary,
                                  ),
                                ),
                            ],
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.kTextPrimary,
                            height: 1.35,
                          ),
                        ),

                        if (n.vistaPrevia != null && n.vistaPrevia!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              n.vistaPrevia!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.kTextMuted,
                              ),
                            ),
                          ),

                        // Botones aceptar / rechazar invitación o transferencia
                        if (_esInvitacionPendiente && _respuesta == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                _TransferBtn(
                                  label: 'Aceptar',
                                  icon: Icons.check_circle_outline,
                                  primary: true,
                                  loading: _respondiendo,
                                  onTap: _respondiendo
                                      ? null
                                      : () => _responder('aceptar'),
                                ),
                                const SizedBox(width: 8),
                                _TransferBtn(
                                  label: 'Rechazar',
                                  icon: Icons.cancel_outlined,
                                  primary: false,
                                  loading: false,
                                  onTap: _respondiendo
                                      ? null
                                      : () => _responder('rechazar'),
                                ),
                              ],
                            ),
                          ),

                        // Resultado de la invitación o transferencia
                        if (_esInvitacionPendiente && _respuesta != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _respuesta == 'aceptada'
                                  ? (_esInvitacionColaboracion
                                        ? '¡Invitación aceptada! Ya eres colaborador de este menú.'
                                        : '¡Menú aceptado! Ya eres el propietario.')
                                  : (_esInvitacionColaboracion
                                        ? 'Invitación rechazada.'
                                        : 'Transferencia rechazada.'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _respuesta == 'aceptada'
                                    ? AppColors.kGreen
                                    : AppColors.kTextMuted,
                              ),
                            ),
                          ),

                        if (_errorResp != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _errorResp!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.kRed,
                              ),
                            ),
                          ),

                        // Tiempo + botón de acción (ir a suscripción)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              if (n.tiempoRelativo != null)
                                Text(
                                  n.tiempoRelativo!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.kTextMuted,
                                  ),
                                ),
                              if (_tieneAccion) ...[
                                const SizedBox(width: 12),
                                if (_pedidoAdmin && n.entidadCodigo != null)
                                  _ActionLink(
                                    icon: Icons.receipt_long_outlined,
                                    label: 'Ver pedidos',
                                    onTap: () => widget.onNavigate(
                                      '/menus/${n.entidadCodigo}/pedidos',
                                    ),
                                  )
                                else if (_pedidoCliente)
                                  _ActionLink(
                                    icon: Icons.receipt_long_outlined,
                                    label: 'Ver mis pedidos',
                                    onTap: () => widget.onNavigate('/pedidos'),
                                  )
                                else
                                  _ActionLink(
                                    icon: Icons.credit_card_outlined,
                                    label: _tiposAdquirir.contains(n.tipo)
                                        ? 'Adquirir plan'
                                        : 'Renovar plan',
                                    onTap: _irASuscripcion,
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Punto azul: no leída
                  if (!n.leida)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 4, left: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.kBlueLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Botón eliminar
          GestureDetector(
            onTap: () => widget.onDelete(n.codigo),
            child: Padding(
              padding: const EdgeInsets.only(left: 6, top: 2),
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
}

class _ActionLink extends StatelessWidget {
  const _ActionLink({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.kBlue),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.kBlue,
          ),
        ),
      ],
    ),
  );
}

// ── Botón de transferencia ────────────────────────────────────────────────────

class _TransferBtn extends StatelessWidget {
  const _TransferBtn({
    required this.label,
    required this.icon,
    required this.primary,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool primary;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primary ? AppColors.kBlue : Colors.transparent,
        border: Border.all(
          color: primary ? AppColors.kBlue : AppColors.kCardBorder,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: loading && primary
          ? const SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 11,
                  color: primary ? Colors.white : AppColors.kTextSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: primary ? Colors.white : AppColors.kTextSecondary,
                  ),
                ),
              ],
            ),
    ),
  );
}

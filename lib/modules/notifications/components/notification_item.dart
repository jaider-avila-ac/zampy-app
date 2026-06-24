import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/colaboracion_service.dart';
import '../models/notification_model.dart';
import '../../../shared/app_colors.dart';

// Equivalente a src/modules/notifications/components/NotificationItem.jsx

// Mapa tipo → ícono (equivalente a ICON_MAP en React)
IconData _iconFor(String tipo) => switch (tipo) {
      'nueva_resena'             => Icons.message_outlined,
      'nuevo_me_encanta'         => Icons.favorite_outline,
      'nueva_calificacion'       => Icons.star_outline,
      'nuevo_colaborador'        => Icons.person_add_outlined,
      'TRIAL_INICIADO'           => Icons.check_circle_outline,
      'RECORDATORIO_TRIAL'       => Icons.access_time_outlined,
      'RECORDATORIO_PAGO'        => Icons.access_time_outlined,
      'PAGO_VENCIDO'             => Icons.warning_amber_outlined,
      'SUSCRIPCION_SUSPENDIDA'   => Icons.block_outlined,
      'PAGO_APROBADO'            => Icons.check_circle_outline,
      'PAGO_RENOVACION'          => Icons.check_circle_outline,
      'PLAN_ACTUALIZADO'         => Icons.bolt_outlined,
      'LOGRO_DESBLOQUEADO'       => Icons.emoji_events_outlined,
      'CUPON_APLICADO'           => Icons.confirmation_number_outlined,
      'CUPON_VENCIDO'            => Icons.confirmation_number_outlined,
      'PAGO_EXPIRADO'            => Icons.cancel_outlined,
      'MENU_PUBLICADO'           => Icons.check_box_outlined,
      'TRANSFERENCIA_PENDIENTE'  => Icons.swap_horiz_outlined,
      'TRANSFERENCIA_ACEPTADA'   => Icons.check_circle_outline,
      'TRANSFERENCIA_RECHAZADA'  => Icons.cancel_outlined,
      _                          => Icons.notifications_outlined,
    };

// Equivalente a labelFor() en React
String _labelFor(String tipo) => switch (tipo) {
      'nueva_resena'             => 'dejó una reseña en tu menú',
      'nuevo_me_encanta'         => 'marcó Me encanta en tu menú',
      'nueva_calificacion'       => 'calificó un plato de',
      'nuevo_colaborador'        => 'te invitó a colaborar en',
      'TRIAL_INICIADO'           => 'Periodo de prueba iniciado —',
      'PAGO_APROBADO'            => 'Pago aprobado —',
      'PAGO_RENOVACION'          => 'Renovación completada —',
      'PLAN_ACTUALIZADO'         => 'Plan actualizado —',
      'RECORDATORIO_TRIAL'       => 'Prueba por vencer —',
      'RECORDATORIO_PAGO'        => 'Recordatorio de pago —',
      'PAGO_VENCIDO'             => 'Suscripción vencida —',
      'SUSCRIPCION_SUSPENDIDA'   => 'Menú suspendido —',
      'PAGO_EXPIRADO'            => 'Pago cancelado —',
      'LOGRO_DESBLOQUEADO'       => '¡Lograste un nuevo logro!',
      'CUPON_APLICADO'           => 'Cupón aplicado —',
      'CUPON_VENCIDO'            => 'Cupón vencido —',
      'MENU_PUBLICADO'           => 'Menú publicado —',
      'TRANSFERENCIA_PENDIENTE'  => 'quiere transferirte el menú',
      'TRANSFERENCIA_ACEPTADA'   => 'aceptó la transferencia del menú',
      'TRANSFERENCIA_RECHAZADA'  => 'rechazó la transferencia del menú',
      _                          => '',
    };

// Tipos que muestran botón "Adquirir / Renovar plan" — navegan a /suscripcion
const _tiposConAccion = {
  'SUSCRIPCION_SUSPENDIDA',
  'RECORDATORIO_TRIAL',
  'RECORDATORIO_PAGO',
  'PAGO_VENCIDO',
};

// Tipos que dicen "Adquirir plan" (vs "Renovar plan")
const _tiposAdquirir = {
  'RECORDATORIO_TRIAL',
  'SUSCRIPCION_SUSPENDIDA',
};

class NotificationItem extends StatefulWidget {
  const NotificationItem({
    super.key,
    required this.notif,
    required this.onMarkRead,
    required this.onDelete,
  });

  final NotificationModel          notif;
  final ValueChanged<String>       onMarkRead;
  final ValueChanged<String>       onDelete;

  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  bool    _respondiendo = false;
  String? _respuesta;   // 'aceptada' | 'rechazada'
  String? _errorResp;

  bool get _esTransferencia => widget.notif.tipo == 'TRANSFERENCIA_PENDIENTE';
  bool get _tieneAccion     => _tiposConAccion.contains(widget.notif.tipo);

  Future<void> _responder(String accion) async {
    final menuId = widget.notif.entidadId;
    if (menuId == null) return;
    setState(() { _respondiendo = true; _errorResp = null; });
    try {
      if (accion == 'aceptar') {
        await ColaboracionService.aceptarTransferencia(menuId);
        setState(() => _respuesta = 'aceptada');
      } else {
        await ColaboracionService.rechazarTransferencia(menuId);
        setState(() => _respuesta = 'rechazada');
      }
      widget.onMarkRead(widget.notif.id);
    } catch (e) {
      setState(() => _errorResp = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _respondiendo = false);
    }
  }

  void _irASuscripcion(BuildContext context) {
    // Equivalente a navigate(entidadId ? `/billing/${entidadId}` : '/suscripcion')
    // Siempre navegamos a /suscripcion porque /billing no existe en Flutter aún
    context.go('/suscripcion');
  }

  @override
  Widget build(BuildContext context) {
    final n       = widget.notif;
    final label   = _labelFor(n.tipo);
    final bgColor = n.leida ? Colors.white : const Color(0xFFEEF2FF);   // indigo-50
    final border  = n.leida ? AppColors.kCardBorder : const Color(0xFFC7D2FE); // indigo-200

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        bgColor,
        border:       Border.all(color: border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Área principal (ícono + texto)
          Expanded(
            child: GestureDetector(
              onTap: !n.leida && !_esTransferencia
                  ? () => widget.onMarkRead(n.id)
                  : null,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ícono
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(_iconFor(n.tipo),
                        size: 18, color: AppColors.kBlueLight),
                  ),
                  const SizedBox(width: 10),

                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Descripción: actorNombre + label + entidadNombre
                        Text.rich(
                          TextSpan(children: [
                            if (n.actorNombre != null)
                              TextSpan(
                                text: n.actorNombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color:      AppColors.kTextPrimary),
                              ),
                            if (label.isNotEmpty)
                              TextSpan(text: ' $label'),
                            if (n.entidadNombre != null)
                              TextSpan(
                                text: ' "${n.entidadNombre}"',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color:      AppColors.kTextSecondary),
                              ),
                          ]),
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.kTextPrimary,
                              height: 1.35),
                        ),

                        // Botones aceptar / rechazar transferencia
                        if (_esTransferencia && _respuesta == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                _TransferBtn(
                                  label:       'Aceptar',
                                  icon:        Icons.check_circle_outline,
                                  primary:     true,
                                  loading:     _respondiendo,
                                  onTap:       _respondiendo ? null : () => _responder('aceptar'),
                                ),
                                const SizedBox(width: 8),
                                _TransferBtn(
                                  label:       'Rechazar',
                                  icon:        Icons.cancel_outlined,
                                  primary:     false,
                                  loading:     false,
                                  onTap:       _respondiendo ? null : () => _responder('rechazar'),
                                ),
                              ],
                            ),
                          ),

                        // Resultado de la transferencia
                        if (_esTransferencia && _respuesta != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _respuesta == 'aceptada'
                                  ? '¡Menú aceptado! Ya eres el propietario.'
                                  : 'Transferencia rechazada.',
                              style: TextStyle(
                                fontSize:   12,
                                fontWeight: FontWeight.w600,
                                color:      _respuesta == 'aceptada'
                                    ? AppColors.kGreen : AppColors.kTextMuted,
                              ),
                            ),
                          ),

                        if (_errorResp != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(_errorResp!,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.kRed)),
                          ),

                        // Tiempo + botón de acción (ir a suscripción)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              if (n.tiempoRelativo != null)
                                Text(n.tiempoRelativo!,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color:    AppColors.kTextMuted)),
                              if (_tieneAccion) ...[
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () => _irASuscripcion(context),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.credit_card_outlined,
                                          size: 11, color: AppColors.kBlue),
                                      const SizedBox(width: 3),
                                      Text(
                                        _tiposAdquirir.contains(n.tipo)
                                            ? 'Adquirir plan'
                                            : 'Renovar plan',
                                        style: const TextStyle(
                                          fontSize:   11,
                                          fontWeight: FontWeight.w600,
                                          color:      AppColors.kBlue,
                                        ),
                                      ),
                                    ],
                                  ),
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
                      width: 8, height: 8,
                      margin: const EdgeInsets.only(top: 4, left: 4),
                      decoration: const BoxDecoration(
                          color: AppColors.kBlueLight, shape: BoxShape.circle),
                    ),
                ],
              ),
            ),
          ),

          // Botón eliminar
          GestureDetector(
            onTap: () => widget.onDelete(n.id),
            child: Padding(
              padding: const EdgeInsets.only(left: 6, top: 2),
              child: Icon(Icons.delete_outline,
                  size: 18, color: AppColors.kTextMuted),
            ),
          ),
        ],
      ),
    );
  }
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

  final String     label;
  final IconData   icon;
  final bool       primary;
  final bool       loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color:        primary ? AppColors.kBlue : Colors.transparent,
            border:       Border.all(
                color: primary ? AppColors.kBlue : AppColors.kCardBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: loading && primary
              ? const SizedBox(
                  width: 11, height: 11,
                  child: CircularProgressIndicator(strokeWidth: 1.5,
                      color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 11,
                        color: primary
                            ? Colors.white : AppColors.kTextSecondary),
                    const SizedBox(width: 4),
                    Text(label,
                        style: TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w600,
                          color:      primary
                              ? Colors.white : AppColors.kTextSecondary,
                        )),
                  ],
                ),
        ),
      );
}

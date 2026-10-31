import 'package:flutter/material.dart';

import '../../../shared/confirmar_dialog.dart';

// Los estados de un pedido (o de una ronda de mesa): cómo se ven y qué se confirma al cambiar a cada uno.
// Equivale a estadoPedido.js de React.

class EstadoVista {
  const EstadoVista(this.label, this.texto, this.fondo, this.barra);

  final String label;
  final Color texto;
  final Color fondo;
  final Color barra;
}

const estadosPedido = <String, EstadoVista>{
  'pendiente': EstadoVista('Pendiente', Color(0xFF64748B), Color(0xFFF1F5F9), Color(0xFFCBD5E1)),
  'en_proceso': EstadoVista('En preparación', Color(0xFF4338CA), Color(0xFFE0E7FF), Color(0xFF6366F1)),
  'entregado': EstadoVista('Entregado', Color(0xFF475569), Color(0xFFF1F5F9), Color(0xFF94A3B8)),
  'cancelado': EstadoVista('Cancelado', Color(0xFF94A3B8), Color(0xFFF1F5F9), Color(0xFFE2E8F0)),
};

EstadoVista estadoPedido(String estado) => estadosPedido[estado] ?? estadosPedido['pendiente']!;

const confirmacionEstado = <String, Confirmacion>{
  'en_proceso': Confirmacion(
      '¿Poner en preparación?', 'El pedido pasará al estado "En preparación".', 'Sí, preparar'),
  'entregado': Confirmacion(
      '¿Marcar como entregado?', 'Confirma que el pedido fue entregado al cliente.', 'Sí, entregado'),
  'cancelado': Confirmacion('¿Cancelar este pedido?',
      'El pedido se marcará como cancelado. Esta acción no se puede deshacer.', 'Sí, cancelar',
      peligro: true),
};

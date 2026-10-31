import 'package:flutter/material.dart';

import '../../orders/utils/estado_pedido.dart';

// Estados de una ronda en la vista del mesero: igual que los de un pedido, pero "Entregado" en verde (ya salió a la
// mesa), como en React.

EstadoVista estadoRonda(String estado) => estado == 'entregado'
    ? const EstadoVista('Entregado', Color(0xFF15803D), Color(0xFFDCFCE7), Color(0xFF22C55E))
    : estadoPedido(estado);

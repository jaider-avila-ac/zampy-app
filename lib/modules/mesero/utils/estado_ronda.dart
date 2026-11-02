import 'package:flutter/material.dart';

import '../../../shared/app_colors.dart';
import '../../orders/utils/estado_pedido.dart';

// Estados de una ronda en la vista del mesero: igual que los de un pedido, pero "Entregado" resaltado en índigo
// relleno (ya salió a la mesa) — como en React: bg-indigo-600 text-white.

EstadoVista estadoRonda(String estado) => estado == 'entregado'
    ? const EstadoVista('Entregado', Colors.white, AppColors.kBlue, AppColors.kBlue)
    : estadoPedido(estado);

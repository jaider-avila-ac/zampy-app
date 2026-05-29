class InvitacionEstado {
  final String codigoInv;
  final bool invActivo;
  final int completadas;
  final int pendientes;

  const InvitacionEstado({
    required this.codigoInv,
    required this.invActivo,
    required this.completadas,
    required this.pendientes,
  });

  factory InvitacionEstado.fromJson(Map<String, dynamic> j) => InvitacionEstado(
        codigoInv: j['codigoInv'] as String? ?? '',
        invActivo: j['invActivo'] as bool? ?? false,
        completadas: (j['completadas'] as num?)?.toInt() ?? 0,
        pendientes: (j['pendientes'] as num?)?.toInt() ?? 0,
      );

  InvitacionEstado copyWith({bool? invActivo}) => InvitacionEstado(
        codigoInv: codigoInv,
        invActivo: invActivo ?? this.invActivo,
        completadas: completadas,
        pendientes: pendientes,
      );
}

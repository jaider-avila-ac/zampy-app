/// A qué mesa y cuenta va la orden que arma el mesero en el menú público (?mesa=…&mesaNombre=…&orden=…&nuevaCuenta=1),
/// igual que en React. [cuentaCodigo] null y sin [nuevaCuenta] = la cuenta principal de la mesa.
class DestinoOrden {
  const DestinoOrden({required this.mesaCodigo, required this.mesaNombre, this.cuentaCodigo, this.nuevaCuenta = false});

  final String mesaCodigo;
  final String mesaNombre;
  final String? cuentaCodigo;
  final bool nuevaCuenta;

  /// null si la URL no es de un mesero tomando orden.
  static DestinoOrden? deQuery(Map<String, String> q) {
    final mesa = q['mesa'];
    if (mesa == null || mesa.isEmpty) return null;
    final orden = q['orden'];
    return DestinoOrden(
      mesaCodigo: mesa,
      mesaNombre: (q['mesaNombre'] ?? '').trim().isEmpty ? 'la mesa' : q['mesaNombre']!,
      cuentaCodigo: orden == null || orden.isEmpty ? null : orden,
      nuevaCuenta: q['nuevaCuenta'] == '1',
    );
  }

  /// Tras enviar una ronda, las siguientes van a la cuenta que se acaba de usar (nunca otra cuenta nueva).
  DestinoOrden conCuenta(String codigo) =>
      DestinoOrden(mesaCodigo: mesaCodigo, mesaNombre: mesaNombre, cuentaCodigo: codigo);
}

String urlTomarOrden(String slug, DestinoOrden d) => Uri(path: '/menu/$slug', queryParameters: {
      'mesa': d.mesaCodigo,
      'mesaNombre': d.mesaNombre,
      'orden': ?d.cuentaCodigo,
      if (d.nuevaCuenta) 'nuevaCuenta': '1',
    }).toString();

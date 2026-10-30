import 'api_client.dart';

// Equivalente a src/services/colaboracionService.js en React.
// La api identifica menús y usuarios por su código público (nunca ids numéricos).

Map<String, dynamic>? _asMap(dynamic data) =>
    data is Map ? Map<String, dynamic>.from(data) : null;

class Colaborador {
  final String codigo;
  final String? nombre;
  final String? apellido;
  final String? avatar;
  final String rol;

  const Colaborador({
    required this.codigo,
    this.nombre,
    this.apellido,
    this.avatar,
    this.rol = 'editor',
  });

  factory Colaborador.fromJson(Map<String, dynamic> j) => Colaborador(
    codigo: (j['codigo'] ?? '').toString(),
    nombre: j['nombre'] as String?,
    apellido: j['apellido'] as String?,
    avatar: j['avatar'] as String?,
    // Fallback a 'editor' para colaboradores previos sin rol guardado.
    rol: (j['rol'] as String?) ?? 'editor',
  );

  String get nombreCompleto => [
    nombre,
    apellido,
  ].where((s) => s != null && s.isNotEmpty).join(' ');
}

class ColaboracionService {
  ColaboracionService._();

  static const roles = ['editor', 'mesero', 'repartidor'];

  // Invita por código de 6 caracteres. Queda PENDIENTE hasta que el invitado
  // la acepte desde su notificación. Devuelve InvitacionColaboracionResponse.
  static Future<Map<String, dynamic>> invitar(
    String menuCodigo,
    String codigo, {
    String? rol,
  }) async {
    final data = await ApiClient.instance.post(
      '/api/v1/menus/$menuCodigo/colaboradores',
      body: {'codigo': codigo, 'rol': ?rol},
    );
    return _asMap(data) ?? {};
  }

  static Future<void> aceptarColaboracion(String menuCodigo) async {
    await ApiClient.instance.post(
      '/api/v1/menus/$menuCodigo/colaboradores/aceptar',
    );
  }

  static Future<void> rechazarColaboracion(String menuCodigo) async {
    await ApiClient.instance.post(
      '/api/v1/menus/$menuCodigo/colaboradores/rechazar',
    );
  }

  static Future<void> cambiarRol(
    String menuCodigo,
    String usuarioCodigo,
    String rol,
  ) async {
    await ApiClient.instance.patch(
      '/api/v1/menus/$menuCodigo/colaboradores/$usuarioCodigo/rol',
      body: {'rol': rol},
    );
  }

  // Solo dueño.
  static Future<List<Colaborador>> listar(String menuCodigo) async {
    final data = await ApiClient.instance.get(
      '/api/v1/menus/$menuCodigo/colaboradores',
    );
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((e) => Colaborador.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // Solo dueño.
  static Future<void> eliminar(String menuCodigo, String usuarioCodigo) async {
    await ApiClient.instance.delete(
      '/api/v1/menus/$menuCodigo/colaboradores/$usuarioCodigo',
    );
  }

  // Inicia la solicitud de transferencia; devuelve TransferenciaResponse
  // (estado PENDIENTE mientras el destinatario no acepte).
  static Future<Map<String, dynamic>> transferir(
    String menuCodigo,
    String codigo,
  ) async {
    final data = await ApiClient.instance.post(
      '/api/v1/menus/$menuCodigo/transferir',
      body: {'codigo': codigo},
    );
    return _asMap(data) ?? {};
  }

  static Future<void> aceptarTransferencia(String menuCodigo) async {
    await ApiClient.instance.post(
      '/api/v1/menus/$menuCodigo/transferencia/aceptar',
    );
  }

  static Future<void> rechazarTransferencia(String menuCodigo) async {
    await ApiClient.instance.post(
      '/api/v1/menus/$menuCodigo/transferencia/rechazar',
    );
  }

  // GET /api/v1/user/me — incluye ubicación y codigoInv
  static Future<Map<String, dynamic>?> getMe() async {
    try {
      return _asMap(await ApiClient.instance.get('/api/v1/user/me'));
    } catch (_) {
      return null;
    }
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart';

// Equivalente a src/services/geographyService.js en React
// GET /api/v1/public/geografia/...

class GeoPais {
  final String codigo;
  final String nombre;
  final String indicativo;

  const GeoPais({
    required this.codigo,
    required this.nombre,
    required this.indicativo,
  });

  factory GeoPais.fromJson(Map<String, dynamic> j) => GeoPais(
    codigo: (j['codigo'] ?? j['isoCode'] ?? '').toString(),
    nombre: j['nombre'] as String? ?? '',
    indicativo: j['indicativo'] as String? ?? '',
  );
}

class GeoDivision {
  final String codigo;
  final String nombre;
  final String tipo;

  const GeoDivision({
    required this.codigo,
    required this.nombre,
    required this.tipo,
  });

  factory GeoDivision.fromJson(Map<String, dynamic> j) => GeoDivision(
    codigo: (j['codigo'] ?? '').toString(),
    nombre: j['nombre'] as String? ?? '',
    tipo: j['tipo'] as String? ?? '',
  );
}

class GeoMunicipio {
  final String codigo;
  final String nombre;

  const GeoMunicipio({required this.codigo, required this.nombre});

  factory GeoMunicipio.fromJson(Map<String, dynamic> j) => GeoMunicipio(
    codigo: (j['codigo'] ?? '').toString(),
    nombre: j['nombre'] as String? ?? '',
  );
}

class GeoCountry {
  final String isoCode;
  final String nombre;

  const GeoCountry({required this.isoCode, required this.nombre});

  factory GeoCountry.fromJson(Map<String, dynamic> j) => GeoCountry(
    isoCode: (j['codigo'] ?? j['isoCode'] ?? '').toString(),
    nombre: j['nombre'] as String? ?? '',
  );
}

class GeoState {
  final String codigo;
  final String nombre;

  const GeoState({required this.codigo, required this.nombre});

  factory GeoState.fromJson(Map<String, dynamic> j) => GeoState(
    codigo: (j['codigo'] ?? '').toString(),
    nombre: j['nombre'] as String? ?? '',
  );
}

final _cache = <String, dynamic>{};

Future<T> _geoFetch<T>(String url, T Function(dynamic) parser) async {
  if (_cache.containsKey(url)) return _cache[url] as T;
  final res = await http
      .get(Uri.parse(url))
      .timeout(const Duration(seconds: 15));
  if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
  final parsed = parser(jsonDecode(res.body));
  _cache[url] = parsed;
  return parsed;
}

String etiquetaDivision(String? tipo) {
  const tipos = {
    'departamento': 'Departamento',
    'estado': 'Estado',
    'provincia': 'Provincia',
    'region': 'Región',
    'division': 'División',
  };
  return tipos[tipo] ?? 'Departamento / Estado';
}

class GeographyService {
  GeographyService._();

  static Future<List<GeoPais>> getPaisesCatalogo() => _geoFetch(
    '$kApiBase/api/v1/public/geografia/paises',
    (d) => (d as List)
        .map((e) => GeoPais.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  static Future<List<GeoDivision>> getDivisiones(
    String paisCodigo,
  ) => _geoFetch(
    '$kApiBase/api/v1/public/geografia/divisiones?pais=${Uri.encodeComponent(paisCodigo)}',
    (d) => (d as List)
        .map((e) => GeoDivision.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  static Future<List<GeoMunicipio>> buscarMunicipios(
    String divisionCodigo, {
    String q = '',
    int limite = 50,
  }) => _geoFetch(
    '$kApiBase/api/v1/public/geografia/municipios'
    '?division=${Uri.encodeComponent(divisionCodigo)}'
    '&q=${Uri.encodeComponent(q)}'
    '&limite=$limite',
    (d) => (d as List)
        .map((e) => GeoMunicipio.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  // Compatibilidad con pantallas que todavía usan el modelo anterior.
  static Future<List<GeoCountry>> getPaises() async {
    final paises = await getPaisesCatalogo();
    return paises
        .map((p) => GeoCountry(isoCode: p.codigo, nombre: p.nombre))
        .toList();
  }

  static Future<List<GeoState>> getEstados(String paisIso2) async {
    final divisiones = await getDivisiones(paisIso2);
    return divisiones
        .map((d) => GeoState(codigo: d.codigo, nombre: d.nombre))
        .toList();
  }

  static Future<List<String>> getCiudades(
    String paisIso2,
    String estadoCodigo,
  ) async {
    final municipios = await buscarMunicipios(estadoCodigo);
    return municipios.map((m) => m.nombre).toList();
  }
}

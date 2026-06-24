import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api.dart';

// Equivalente a src/services/geographyService.js
// GET /api/v1/public/geografia/...

class GeoCountry {
  final String isoCode;
  final String nombre;
  const GeoCountry({required this.isoCode, required this.nombre});
  factory GeoCountry.fromJson(Map<String, dynamic> j) =>
      GeoCountry(isoCode: j['isoCode'] as String, nombre: j['nombre'] as String);
}

class GeoState {
  final String codigo;
  final String nombre;
  const GeoState({required this.codigo, required this.nombre});
  factory GeoState.fromJson(Map<String, dynamic> j) =>
      GeoState(codigo: j['codigo'] as String, nombre: j['nombre'] as String);
}

// Cache equivalente al Map de React
final _cache = <String, dynamic>{};

Future<T> _geoFetch<T>(String url, T Function(dynamic) parser) async {
  if (_cache.containsKey(url)) return _cache[url] as T;
  final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
  if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
  final data = jsonDecode(res.body);
  final parsed = parser(data);
  _cache[url] = parsed;
  return parsed;
}

class GeographyService {
  GeographyService._();

  static Future<List<GeoCountry>> getPaises() =>
      _geoFetch('$kApiBase/api/v1/public/geografia/paises',
          (d) => (d as List).map((e) => GeoCountry.fromJson(e as Map<String, dynamic>)).toList());

  static Future<List<GeoState>> getEstados(String paisIso2) =>
      _geoFetch('$kApiBase/api/v1/public/geografia/estados?pais=${Uri.encodeComponent(paisIso2)}',
          (d) => (d as List).map((e) => GeoState.fromJson(e as Map<String, dynamic>)).toList());

  static Future<List<String>> getCiudades(String paisIso2, String estadoCodigo) =>
      _geoFetch(
          '$kApiBase/api/v1/public/geografia/ciudades?pais=${Uri.encodeComponent(paisIso2)}&estado=${Uri.encodeComponent(estadoCodigo)}',
          (d) => (d as List).map((e) {
                if (e is String) return e;
                return (e as Map<String, dynamic>)['nombre'] as String? ?? '';
              }).toList());
}

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api.dart';
import 'device_info_service.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  final String? code;

  const ApiException(this.message, {this.status, this.code});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const _timeout = Duration(seconds: 20);

  String? Function()? tokenProvider;
  Future<bool> Function()? refreshHandler;
  Future<void> Function()? onAuthExpired;

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) => request('GET', path, query: query, auth: auth);

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, String>? query,
    bool auth = true,
  }) => request('POST', path, body: body, query: query, auth: auth);

  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, String>? query,
    bool auth = true,
  }) => request('PUT', path, body: body, query: query, auth: auth);

  Future<dynamic> patch(
    String path, {
    Object? body,
    Map<String, String>? query,
    bool auth = true,
  }) => request('PATCH', path, body: body, query: query, auth: auth);

  Future<dynamic> delete(
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers,
    bool auth = true,
  }) => request(
    'DELETE',
    path,
    body: body,
    query: query,
    headers: headers,
    auth: auth,
  );

  Future<dynamic> request(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? headers,
    bool auth = true,
  }) async {
    var response = await _send(
      method,
      path,
      body: body,
      query: query,
      extraHeaders: headers,
      auth: auth,
    );

    if (response.statusCode == 401 && auth) {
      final refreshed = await refreshHandler?.call() ?? false;
      if (refreshed) {
        response = await _send(
          method,
          path,
          body: body,
          query: query,
          extraHeaders: headers,
          auth: auth,
        );
      } else {
        await onAuthExpired?.call();
      }
    }

    return _decode(response);
  }

  Future<http.Response> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
    Map<String, String>? extraHeaders,
    required bool auth,
  }) async {
    final base = Uri.parse('$kApiBase$path');
    final uri = query == null || query.isEmpty
        ? base
        : base.replace(queryParameters: {...base.queryParameters, ...query});

    final headers = <String, String>{
      'Accept': 'application/json',
      // Identifica el dispositivo para "Sesiones activas" (el backend solo lo lee al abrir sesión)
      ...DeviceInfoService.headers,
      ...?extraHeaders,
    };
    if (body != null) headers['Content-Type'] = 'application/json';

    final token = auth ? tokenProvider?.call() : null;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      switch (method) {
        case 'GET':
          return await http.get(uri, headers: headers).timeout(_timeout);
        case 'POST':
          return await http
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_timeout);
        case 'PUT':
          return await http
              .put(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_timeout);
        case 'PATCH':
          return await http
              .patch(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_timeout);
        case 'DELETE':
          return await http
              .delete(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_timeout);
        default:
          throw UnsupportedError('Método no soportado: $method');
      }
    } on TimeoutException {
      throw const ApiException('No se pudo conectar. Inténtalo de nuevo.');
    } on http.ClientException {
      throw const ApiException('No se pudo conectar. Inténtalo de nuevo.');
    }
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode == 204) return null;

    dynamic data;
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = response.body;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Error ${response.statusCode}';
      String? code;

      if (data is Map) {
        message = data['message']?.toString() ?? message;
        code = data['code']?.toString();
      } else if (data is String && data.trim().isNotEmpty) {
        message = data;
      }

      throw ApiException(message, status: response.statusCode, code: code);
    }

    return data;
  }
}

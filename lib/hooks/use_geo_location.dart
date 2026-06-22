import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

// Equivalente a src/hooks/useGeoLocation.js en React
// Maneja estado de geolocalización y caché en almacenamiento seguro

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

// Estado guardado: 'granted' | 'denied' | null
Future<String?> getStoredGeoStatus() async {
  return _storage.read(key: 'geo_status');
}

Future<void> setGeoStatus(String status) async {
  await _storage.write(key: 'geo_status', value: status);
}

// Ubicación guardada: {lat, lon, ciudad}
Future<Map<String, dynamic>?> getStoredLocation() async {
  try {
    final raw = await _storage.read(key: 'geo_location');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  } catch {
    return null;
  }
}

Future<void> storeLocation(double lat, double lon, String? ciudad) async {
  await _storage.write(
    key: 'geo_location',
    value: jsonEncode({'lat': lat, 'lon': lon, 'ciudad': ciudad}),
  );
  await setGeoStatus('granted');
}

// Solicitar permiso y posición del dispositivo
// Equivalente a requestBrowserLocation() en useGeoLocation.js
Future<({double lat, double lon})> requestDeviceLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) throw Exception('Servicio de ubicación desactivado');

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) throw Exception('Permiso denegado');
  }
  if (permission == LocationPermission.deniedForever) throw Exception('Permiso denegado permanentemente');

  final pos = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 10)),
  );
  return (lat: pos.latitude, lon: pos.longitude);
}

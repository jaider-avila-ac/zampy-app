import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

// Equivalente a src/hooks/useGeoLocation.js en React

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

const _keyGeoStatus = 'geo_status';
const _keyLocation  = 'geo_location';

Future<String?> getStoredGeoStatus() async {
  try { return await _storage.read(key: _keyGeoStatus); } catch (_) { return null; }
}

Future<void> setGeoStatus(String status) async {
  try { await _storage.write(key: _keyGeoStatus, value: status); } catch (_) {}
}

Future<Map<String, dynamic>?> getStoredLocation() async {
  try {
    final raw = await _storage.read(key: _keyLocation);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) { return null; }
}

Future<void> storeLocation(double lat, double lon, String? ciudad) async {
  try {
    await _storage.write(
      key: _keyLocation,
      value: jsonEncode({'lat': lat, 'lon': lon, 'ciudad': ciudad}),
    );
  } catch (_) {}
}

// Solicita permiso y devuelve la posición o null si es denegado
Future<Position?> requestDeviceLocation() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        await setGeoStatus('denied');
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      await setGeoStatus('denied');
      return null;
    }

    await setGeoStatus('granted');
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
  } catch (_) {
    return null;
  }
}

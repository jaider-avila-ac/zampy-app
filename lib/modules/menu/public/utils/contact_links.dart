import 'package:url_launcher/url_launcher.dart';

import '../models/public_menu_model.dart';

Future<void> _open(Uri uri) async {
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

String _digits(String? value) => (value ?? '').replaceAll(RegExp(r'\D'), '');

Future<void> openWhatsapp(MenuInfo info, {String? text}) async {
  final number = _digits(
    info.whatsapp != null && info.whatsapp!.isNotEmpty
        ? info.whatsapp
        : info.phone,
  );
  if (number.isEmpty) return;
  final encoded = text == null ? '' : '?text=${Uri.encodeComponent(text)}';
  await _open(Uri.parse('https://wa.me/$number$encoded'));
}

Future<void> openPhone(MenuInfo info) async {
  final number = _digits(
    info.phone != null && info.phone!.isNotEmpty ? info.phone : info.whatsapp,
  );
  if (number.isEmpty) return;
  await _open(Uri.parse('tel:$number'));
}

Future<void> openEmail(MenuInfo info) async {
  final email = info.email;
  if (email == null || email.isEmpty) return;
  await _open(Uri.parse('mailto:$email'));
}

Future<void> openMaps(MenuInfo info) async {
  final query = [
    info.address,
    info.ubicacion?.municipio,
    info.ubicacion?.division,
    info.ubicacion?.pais,
  ].where((value) => value != null && value.trim().isNotEmpty).join(', ');
  if (query.isEmpty) return;
  await _open(
    Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    ),
  );
}

Future<void> openInstagram(MenuInfo info) async {
  final raw = info.instagram;
  if (raw == null || raw.isEmpty) return;
  final url = raw.startsWith('http')
      ? raw
      : 'https://instagram.com/${raw.replaceAll('@', '')}';
  await _open(Uri.parse(url));
}

Future<void> openFacebook(MenuInfo info) async {
  final raw = info.facebook;
  if (raw == null || raw.isEmpty) return;
  final url = raw.startsWith('http')
      ? raw
      : 'https://facebook.com/${raw.replaceAll('@', '')}';
  await _open(Uri.parse(url));
}

Future<void> openTiktok(MenuInfo info) async {
  final raw = info.tiktok;
  if (raw == null || raw.isEmpty) return;
  final url = raw.startsWith('http')
      ? raw
      : 'https://tiktok.com/@${raw.replaceAll('@', '')}';
  await _open(Uri.parse(url));
}

Future<void> openWebsite(MenuInfo info) async {
  final raw = info.website;
  if (raw == null || raw.isEmpty) return;
  final url = raw.startsWith('http') ? raw : 'https://$raw';
  await _open(Uri.parse(url));
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/push_service.dart';
import 'modules/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Inicializar notificaciones locales y solicitar permiso POST_NOTIFICATIONS
  await PushService.init();
  runApp(const ZampyApp());
}

class ZampyApp extends StatelessWidget {
  const ZampyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZamPy',
      themeMode: ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF4F46E5),
        brightness: Brightness.light,
      ),
      home: const LoginScreen(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'context/auth_context.dart';
import 'context/notificacion_context.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthContext()..init()),
        ChangeNotifierProvider(create: (_) => NotificacionContext()),
      ],
      child: const ZammpyApp(),
    ),
  );
}

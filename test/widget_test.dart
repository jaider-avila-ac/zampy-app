import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zammpy_app/context/auth_context.dart';
import 'package:zammpy_app/context/notificacion_context.dart';
import 'package:zammpy_app/app.dart';

void main() {
  testWidgets('ZammpyApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthContext()),
          ChangeNotifierProvider(create: (_) => NotificacionContext()),
        ],
        child: const ZammpyApp(),
      ),
    );
  });
}

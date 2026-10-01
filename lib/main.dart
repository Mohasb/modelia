import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:modelia/demo/demo_api.dart';
import 'package:modelia/shared/providers/api_provider.dart';
import 'package:modelia/shared/providers/auth_provider.dart';
import 'package:modelia/shared/providers/theme_provider.dart';
import 'package:modelia/shared/services/api_service.dart';
import 'package:modelia/core/router/app_router.dart';
import 'package:modelia/core/theme/app_theme.dart';

void main() {
  if (kDemo) {
    // Modo demo (--dart-define=DEMO=true): todas las llamadas de package:http pasan por
    // la API simulada. Todo el arranque va dentro de la zona para que Flutter la herede;
    // las imágenes y los modelos 3D usan el cliente real, creado fuera de ella.
    final real = http.Client();
    http.runWithClient(_arrancar, () => DemoClient(real));
  } else {
    _arrancar();
  }
}

Future<void> _arrancar() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDemo) await iniciarSesionDemo();
  runApp(
    ProviderScope(
      overrides: [
        apiServiceProvider.overrideWith((ref) {
          final api = ApiService(
            baseUrl: "https://modeliabackend-production.up.railway.app",
            
            /*defaultTargetPlatform == TargetPlatform.android
                ? 'http://192.168.1.39:8080'
                : 'http://localhost:8080',*/
          );
          api.onSesionExpirada = () {
            ref.read(authProvider.notifier).sesionExpirada();
          };
          return api;
        }),
      ],
      child: const ModeliaApp(),
    ),
  );
}

class ModeliaApp extends ConsumerWidget {
  const ModeliaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeState = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Modelia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(themeState.temaConfig),
      darkTheme: AppTheme.dark(themeState.temaConfig),
      themeMode: themeState.themeMode,
      routerConfig: router,
    );
  }
}

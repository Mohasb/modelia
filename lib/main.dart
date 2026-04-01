import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:modelia/shared/providers/api_provider.dart';
import 'package:modelia/shared/providers/auth_provider.dart';
import 'package:modelia/shared/providers/theme_provider.dart';
import 'package:modelia/shared/services/api_service.dart';
import 'package:modelia/core/router/app_router.dart';
import 'package:modelia/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        apiServiceProvider.overrideWith((ref) {
          final api = ApiService(
            baseUrl: defaultTargetPlatform == TargetPlatform.android
                ? 'http://192.168.1.39:8080'
                : 'http://localhost:8080',
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
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Modelia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

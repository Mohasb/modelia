import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modelia/features/admin/screens/admin_tema_screen.dart';
import 'package:modelia/features/catalogo/screens/catalogo_screen.dart';
import 'package:modelia/features/detalle/screens/ar_viewer_screen.dart';
import 'package:modelia/features/splash/splash_screen.dart';
import 'package:modelia/shared/providers/auth_provider.dart';
import 'package:modelia/core/router/app_shell.dart';
import 'package:modelia/features/catalogo/screens/home_screen.dart';
import 'package:modelia/features/detalle/screens/detalle_producto_screen.dart';
import 'package:modelia/features/carrito/screens/carrito_screen.dart';
import 'package:modelia/features/auth/screens/login_screen.dart';
import 'package:modelia/features/auth/screens/register_screen.dart';
import 'package:modelia/features/checkout/screens/checkout_screen.dart';
import 'package:modelia/features/perfil/screens/perfil_screen.dart';
import 'package:modelia/features/perfil/screens/mis_pedidos_screen.dart';
import 'package:modelia/features/admin/screens/admin_dashboard_screen.dart';
import 'package:modelia/features/admin/screens/admin_productos_screen.dart';
import 'package:modelia/features/admin/screens/admin_pedidos_screen.dart';
import 'package:modelia/features/admin/screens/admin_categorias_screen.dart';
import 'package:modelia/features/admin/screens/admin_usuarios_screen.dart';
import 'package:modelia/tools/icon_capture_screen.dart';
import 'package:modelia/visor-prueba.dart';

// Listenable que solo notifica cuando cambian isLogueado o sesionExpirada
// NO cuando cambia isLoading o error
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(this._ref) {
    _ref.listen<AuthState>(authProvider, (previous, next) {
      final loginCambio = previous?.isLogueado != next.isLogueado;
      final expiraCambio = previous?.sesionExpirada != next.sesionExpirada;
      if (loginCambio || expiraCambio) {
        print(
          '[ROUTER] Notificando cambio - isLogueado: ${next.isLogueado}, sesionExpirada: ${next.sesionExpirada}',
        );
        notifyListeners();
      }
    });
  }

  final Ref _ref;

  AuthState get authState => _ref.read(authProvider);
}

final _authRouterNotifierProvider = Provider((ref) {
  return _AuthRouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(_authRouterNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = notifier.authState;
      final location = state.uri.path;

      if (location == '/splash') return null;

      print(
        '[ROUTER] Redirect - location: $location, isLogueado: ${authState.isLogueado}, sesionExpirada: ${authState.sesionExpirada}',
      );

      if (authState.sesionExpirada &&
          location != '/login' &&
          location != '/register') {
        return '/login';
      }

      final isLogueado = authState.isLogueado;
      final isAdmin = authState.isAdmin;

      final rutasProtegidas = ['/checkout', '/perfil', '/mis-pedidos'];
      final rutasAdmin = ['/admin'];

      if (rutasProtegidas.any((r) => location.startsWith(r)) && !isLogueado) {
        return '/login?redirect=$location';
      }
      if (rutasAdmin.any((r) => location.startsWith(r)) && !isAdmin) {
        return '/';
      }
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/catalogo',
            builder: (context, state) => const CatalogoScreen(),
          ),
          GoRoute(
            path: '/mis-pedidos',
            builder: (context, state) => const MisPedidosScreen(),
          ),
          GoRoute(
            path: '/perfil',
            builder: (context, state) => const PerfilScreen(),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/productos',
            builder: (context, state) => const AdminProductosScreen(),
          ),
          GoRoute(
            path: '/admin/pedidos',
            builder: (context, state) => const AdminPedidosScreen(),
          ),
          GoRoute(
            path: '/admin/categorias',
            builder: (context, state) => const AdminCategoriasScreen(),
          ),
          GoRoute(
            path: '/admin/usuarios',
            builder: (context, state) => const AdminUsuariosScreen(),
          ),
          GoRoute(
            path: '/admin/tema',
            builder: (context, state) => const AdminTemaScreen(),
          ),
          GoRoute(
            path: '/admin/visorPrueba',
            builder: (context, state) => const VisorPruebaScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/icon-capture',
        builder: (context, state) => const IconCaptureScreen(),
      ),
      GoRoute(
        path: '/producto/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return DetalleProductoScreen(productoId: id);
        },
      ),
      GoRoute(
        path: '/producto/:id/ar',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ArViewerScreen(productoId: id);
        },
      ),
      GoRoute(
        path: '/carrito',
        builder: (context, state) => const CarritoScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          return LoginScreen(redirectTo: redirect);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
    ],
  );
});

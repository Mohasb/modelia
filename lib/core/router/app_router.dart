import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modelia/features/detalle/screens/ar_viewer_screen.dart';
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

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.uri.path;

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
      // ── Shell con nav ────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(
            path: '/catalogo',
            builder: (context, state) => const HomeScreen(),
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
        ],
      ),

      // ── Sin shell (pantalla completa) ────────────────────
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

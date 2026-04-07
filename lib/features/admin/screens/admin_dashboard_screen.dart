import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modelia/core/theme/app_theme.dart';
import 'package:modelia/shared/providers/api_provider.dart';

final _statsProvider = FutureProvider((ref) async {
  final api = ref.watch(apiServiceProvider);
  final productos = await api.getProductos();
  final pedidos = await api.getTodosPedidos();
  final usuarios = await api.getTodosUsuarios();
  return {
    'productos': productos.length,
    'pedidos': pedidos.length,
    'usuarios': usuarios.length,
    'pendientes': pedidos.where((p) => p.estado == 'PENDIENTE').length,
  };
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_statsProvider);
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;

    return Scaffold(
      appBar: AppBar(title: const Text('Panel de administración')),
      body: RefreshIndicator(
        color: AppTheme.accentGold,
        onRefresh: () async => ref.invalidate(_statsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats
              statsAsync.when(
                data: (stats) => GridView.count(
                  crossAxisCount: isWindows ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _StatCard(
                      label: 'Productos',
                      valor: '${stats['productos']}',
                      icon: Icons.inventory_2_outlined,
                      color: Colors.blue,
                    ),
                    _StatCard(
                      label: 'Pedidos',
                      valor: '${stats['pedidos']}',
                      icon: Icons.receipt_long_outlined,
                      color: Colors.green,
                    ),
                    _StatCard(
                      label: 'Pendientes',
                      valor: '${stats['pendientes']}',
                      icon: Icons.pending_outlined,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      label: 'Usuarios',
                      valor: '${stats['usuarios']}',
                      icon: Icons.people_outline_rounded,
                      color: AppTheme.accentGold,
                    ),
                  ],
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.accentGold),
                ),
                error: (e, _) => Center(child: Text(e.toString())),
              ),
              const SizedBox(height: 24),

              // Accesos rápidos
              Text(
                'Gestión',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _AccesoAdmin(
                icon: Icons.inventory_2_outlined,
                label: 'Productos',
                descripcion: 'Crear, editar y eliminar productos',
                color: Colors.blue,
                onTap: () => context.go('/admin/productos'),
              ),
              const SizedBox(height: 8),
              _AccesoAdmin(
                icon: Icons.receipt_long_outlined,
                label: 'Pedidos',
                descripcion: 'Ver y gestionar pedidos',
                color: Colors.green,
                onTap: () => context.go('/admin/pedidos'),
              ),
              const SizedBox(height: 8),
              _AccesoAdmin(
                icon: Icons.category_outlined,
                label: 'Categorías',
                descripcion: 'Gestionar categorías de productos',
                color: Colors.purple,
                onTap: () => context.go('/admin/categorias'),
              ),
              const SizedBox(height: 8),
              _AccesoAdmin(
                icon: Icons.people_outline_rounded,
                label: 'Usuarios',
                descripcion: 'Ver y gestionar usuarios',
                color: AppTheme.accentGold,
                onTap: () => context.go('/admin/usuarios'),
              ),
              const SizedBox(height: 8),
              _AccesoAdmin(
                icon: Icons.palette_outlined,
                label: 'Tema y colores',
                descripcion: 'Personalizar colores de la app en tiempo real',
                color: Colors.deepPurple,
                onTap: () => context.go('/admin/tema'),
              ),
              const SizedBox(height: 8),
              _AccesoAdmin(
                icon: Icons.palette_outlined,
                label: 'Visor 3D v2',
                descripcion: 'Visor 3D con animaciones y colores',
                color: Colors.cyan,
                onTap: () => context.go('/admin/visorPrueba'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.valor,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                valor,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccesoAdmin extends StatelessWidget {
  final IconData icon;
  final String label;
  final String descripcion;
  final Color color;
  final VoidCallback onTap;

  const _AccesoAdmin({
    required this.icon,
    required this.label,
    required this.descripcion,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    descripcion,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

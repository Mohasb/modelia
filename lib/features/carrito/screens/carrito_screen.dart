import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:modelia/shared/providers/carrito_provider.dart';
import 'package:modelia/shared/providers/auth_provider.dart';
import 'package:modelia/shared/models/carrito_item.dart';
import 'package:modelia/core/theme/app_theme.dart';

class CarritoScreen extends ConsumerWidget {
  const CarritoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carrito = ref.watch(carritoProvider);
    final total = ref.watch(carritoPrecioTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (carrito.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Vaciar carrito'),
                    content: const Text(
                      '¿Seguro que quieres eliminar todos los productos?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(carritoProvider.notifier).vaciar();
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Vaciar',
                          style: TextStyle(color: AppTheme.accentRed),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: const Text(
                'Vaciar',
                style: TextStyle(color: AppTheme.accentRed),
              ),
            ),
        ],
      ),
      body: carrito.isEmpty
          ? const _CarritoVacio()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: carrito.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _CarritoItemCard(item: carrito[index]),
                  ),
                ),
                _ResumenCarrito(total: total),
              ],
            ),
    );
  }
}

// ── Item del carrito ───────────────────────────────────────

class _CarritoItemCard extends ConsumerWidget {
  final CarritoItem item;
  const _CarritoItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Imagen
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 72,
              height: 72,
              child: item.producto.imagenUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.producto.imagenUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: colorScheme.surface,
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                    )
                  : Container(
                      color: colorScheme.surface,
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.producto.nombre,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.producto.precio.toStringAsFixed(2)} €',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.accentRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                // Selector cantidad
                Row(
                  children: [
                    _BotonCantidad(
                      icon: Icons.remove_rounded,
                      onTap: () => ref
                          .read(carritoProvider.notifier)
                          .reducir(item.producto),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '${item.cantidad}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _BotonCantidad(
                      icon: Icons.add_rounded,
                      onTap: () => ref
                          .read(carritoProvider.notifier)
                          .agregar(item.producto),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Subtotal + eliminar
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.subtotal.toStringAsFixed(2)} €',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () =>
                    ref.read(carritoProvider.notifier).eliminar(item.producto),
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BotonCantidad extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _BotonCantidad({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

// ── Resumen y checkout ─────────────────────────────────────

class _ResumenCarrito extends ConsumerWidget {
  final double total;
  const _ResumenCarrito({required this.total});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final carrito = ref.watch(carritoProvider);
    final totalItems = carrito.fold(0, (sum, i) => sum + i.cantidad);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalItems ${totalItems == 1 ? 'artículo' : 'artículos'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '${total.toStringAsFixed(2)} €',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              if (authState.isLogueado) {
                context.push('/checkout');
              } else {
                context.push('/login?redirect=/checkout');
              }
            },
            child: const Text('Finalizar compra'),
          ),
        ],
      ),
    );
  }
}

// ── Carrito vacío ──────────────────────────────────────────

class _CarritoVacio extends StatelessWidget {
  const _CarritoVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 72,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Tu carrito está vacío',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Añade productos para empezar',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => context.go('/'),
            child: const Text('Ver productos'),
          ),
        ],
      ),
    );
  }
}

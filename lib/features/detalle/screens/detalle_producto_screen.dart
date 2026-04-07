import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:modelia/shared/models/producto.dart';
import 'package:modelia/shared/providers/carrito_provider.dart';
import 'package:modelia/shared/providers/productos_provider.dart';
import 'package:modelia/shared/widgets/boton_ver_3d.dart';
import 'package:modelia/core/theme/app_theme.dart';

class DetalleProductoScreen extends ConsumerWidget {
  final int productoId;
  const DetalleProductoScreen({super.key, required this.productoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productoAsync = ref.watch(productoDetalleProvider(productoId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: productoAsync.when(
        data: (producto) => _DetalleContent(producto: producto),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentGold),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(e.toString()),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalleContent extends ConsumerWidget {
  final Producto producto;
  const _DetalleContent({required this.producto});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Imagen principal ───────────────────────
                Container(
                  height: 300,
                  width: double.infinity,
                  color: colorScheme.surfaceContainerHighest,
                  child: producto.imagenUrl != null
                      ? CachedNetworkImage(
                          imageUrl: producto.imagenUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.accentGold,
                              strokeWidth: 2,
                            ),
                          ),
                          errorWidget: (_, __, ___) => Icon(
                            Icons.image_not_supported_outlined,
                            size: 64,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        )
                      : Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Categoría ──────────────────────────
                      Text(
                        producto.categoriaNombre.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // ── Nombre ─────────────────────────────
                      Text(
                        producto.nombre,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),

                      // ── Precio y stock ─────────────────────
                      Row(
                        children: [
                          Text(
                            '${producto.precio.toStringAsFixed(2)} €',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  color: AppTheme.accentGold,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: producto.stock > 0
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              producto.stock > 0
                                  ? '${producto.stock} en stock'
                                  : 'Sin stock',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: producto.stock > 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Descripción ────────────────────────
                      if (producto.descripcion != null) ...[
                        Text(
                          'Descripción',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          producto.descripcion!,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.6),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Botón Ver en 3D ────────────────────
                      // En Android siempre visible (todos tienen AR)
                      // En Windows visible pero abre visor web
                      BotonVer3D(
                        onTap: () =>
                            context.push('/producto/${producto.id}/ar'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Botón añadir al carrito (fijo abajo) ──────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
          ),
          child: FilledButton.icon(
            onPressed: producto.stock > 0
                ? () {
                    ref.read(carritoProvider.notifier).agregar(producto);
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${producto.nombre} añadido al carrito'),
                        backgroundColor: AppTheme.accentGold,
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.height - 150,
                          left: 16,
                          right: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.shopping_bag_outlined),
            label: Text(producto.stock > 0 ? 'Añadir al carrito' : 'Sin stock'),
          ),
        ),
      ],
    );
  }
}

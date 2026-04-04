import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:modelia/shared/models/producto.dart';
import 'package:modelia/shared/providers/carrito_provider.dart';
import 'package:modelia/core/theme/app_theme.dart';

class ProductoCard extends ConsumerWidget {
  final Producto producto;
  const ProductoCard({super.key, required this.producto});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => context.push('/producto/${producto.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagen fija ────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: producto.imagenUrl != null
                    ? CachedNetworkImage(
                        imageUrl: producto.imagenUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: colorScheme.surface,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.accentRed,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: colorScheme.surface,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                            size: 32,
                          ),
                        ),
                      )
                    : Container(
                        color: colorScheme.surface,
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                          size: 32,
                        ),
                      ),
              ),
            ),

            // ── Info ───────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto.nombre,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${producto.precio.toStringAsFixed(2)} €',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.accentRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: ElevatedButton(
                        onPressed: producto.stock > 0
                            ? () {
                                ref
                                    .read(carritoProvider.notifier)
                                    .agregar(producto);
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${producto.nombre} añadido'),
                                    duration: const Duration(seconds: 2),
                                    backgroundColor: AppTheme.accentRed,
                                    behavior: SnackBarBehavior.floating,
                                    margin: EdgeInsets.only(
                                      bottom:
                                          MediaQuery.of(context).size.height -
                                          185,
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
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          minimumSize: Size.zero,
                        ),
                        child: Text(
                          producto.stock > 0 ? '+ Carrito' : 'Sin stock',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

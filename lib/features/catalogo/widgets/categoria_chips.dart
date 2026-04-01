import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modelia/shared/providers/productos_provider.dart';

class CategoriaChips extends ConsumerWidget {
  const CategoriaChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriasAsync = ref.watch(categoriasProvider);
    final categoriaSeleccionada = ref.watch(categoriaSeleccionadaProvider);

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Chip "Todos"
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Todos'),
              selected: categoriaSeleccionada == null,
              onSelected: (_) {
                ref.read(categoriaSeleccionadaProvider.notifier).state = null;
                ref.invalidate(productosProvider);
              },
            ),
          ),
          // Chips de categorías
          ...categoriasAsync.when(
            data: (categorias) => categorias
                .map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat.nombre),
                      selected: categoriaSeleccionada == cat.id,
                      onSelected: (_) {
                        ref.read(categoriaSeleccionadaProvider.notifier).state =
                            cat.id;
                        ref.invalidate(productosProvider);
                      },
                    ),
                  ),
                )
                .toList(),
            loading: () => List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Container(
                    width: 60,
                    height: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            ),
            error: (_, __) => [],
          ),
        ],
      ),
    );
  }
}

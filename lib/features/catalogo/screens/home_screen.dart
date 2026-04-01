import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modelia/shared/providers/productos_provider.dart';
import 'package:modelia/shared/models/producto.dart';
import 'package:modelia/core/theme/app_theme.dart';
import 'package:modelia/features/catalogo/widgets/producto_card.dart';
import 'package:modelia/features/catalogo/widgets/categoria_chips.dart';
import 'package:modelia/features/catalogo/widgets/banner_destacado.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  bool _buscando = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(productosProvider);
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;

    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.accentRed,
        onRefresh: () async {
          ref.invalidate(productosProvider);
          ref.invalidate(categoriasProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Barra de búsqueda ──────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _SearchBar(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() => _buscando = value.isNotEmpty);
                    ref.read(busquedaProvider.notifier).state = value;
                  },
                  onClear: () {
                    _searchController.clear();
                    setState(() => _buscando = false);
                    ref.read(busquedaProvider.notifier).state = '';
                  },
                ),
              ),
            ),

            // ── Chips de categorías ────────────────────────
            if (!_buscando) const SliverToBoxAdapter(child: CategoriaChips()),

            // ── Banner destacado ───────────────────────────
            if (!_buscando)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: BannerDestacado(),
                ),
              ),

            // ── Título sección ─────────────────────────────
            if (!_buscando)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Productos',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        productosAsync.when(
                          data: (p) => '${p.length} artículos',
                          loading: () => '',
                          error: (_, __) => '',
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Grid de productos ──────────────────────────
            _buscando
                ? _BusquedaResultados()
                : productosAsync.when(
                    data: (productos) => _ProductosGrid(
                      productos: productos,
                      crossAxisCount: isWindows ? 3 : 2,
                    ),
                    loading: () =>
                        const SliverToBoxAdapter(child: _LoadingGrid()),
                    error: (error, _) => SliverToBoxAdapter(
                      child: _ErrorWidget(
                        mensaje: error.toString(),
                        onRetry: () => ref.invalidate(productosProvider),
                      ),
                    ),
                  ),

            // Padding inferior
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ── Search Bar ─────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Buscar productos...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 18),
              )
            : null,
      ),
    );
  }
}

// ── Grid de productos ──────────────────────────────────────

class _ProductosGrid extends StatelessWidget {
  final List<Producto> productos;
  final int crossAxisCount;

  const _ProductosGrid({required this.productos, required this.crossAxisCount});

  @override
  Widget build(BuildContext context) {
    if (productos.isEmpty) {
      return const SliverToBoxAdapter(child: _EmptyState());
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => ProductoCard(producto: productos[index]),
          childCount: productos.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 260,
        ),
      ),
    );
  }
}

// ── Resultados búsqueda ────────────────────────────────────

class _BusquedaResultados extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultadosAsync = ref.watch(productosBusquedaProvider);
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;

    return resultadosAsync.when(
      data: (productos) => _ProductosGrid(
        productos: productos,
        crossAxisCount: isWindows ? 3 : 2,
      ),
      loading: () => const SliverToBoxAdapter(child: _LoadingGrid()),
      error: (e, _) =>
          SliverToBoxAdapter(child: Center(child: Text(e.toString()))),
    );
  }
}

// ── Loading skeleton ───────────────────────────────────────

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        itemCount: 6,
        itemBuilder: (context, _) => _SkeletonCard(),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos disponibles',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error widget ───────────────────────────────────────────

class _ErrorWidget extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No se pudo conectar al servidor',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              mensaje.replaceAll('Exception: ', ''),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

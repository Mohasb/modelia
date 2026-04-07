import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:modelia/shared/providers/productos_provider.dart';
import 'package:modelia/shared/providers/api_provider.dart';
import 'package:modelia/shared/models/producto.dart';
import 'package:modelia/core/theme/app_theme.dart';
import 'package:modelia/features/catalogo/widgets/producto_card.dart';

final _ordenCatalogoProvider = StateProvider<String>((ref) => 'nombre');
final _categoriaFiltroCatalogoProvider = StateProvider<int?>((ref) => null);
final _busquedaCatalogoProvider = StateProvider<String>((ref) => '');

final _productosCatalogoProvider = FutureProvider<List<Producto>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final categoriaId = ref.watch(_categoriaFiltroCatalogoProvider);
  final busqueda = ref.watch(_busquedaCatalogoProvider);
  final orden = ref.watch(_ordenCatalogoProvider);

  List<Producto> productos = await api.getProductos(
    categoriaId: categoriaId,
    nombre: busqueda.isNotEmpty ? busqueda : null,
  );

  switch (orden) {
    case 'precio_asc':
      productos.sort((a, b) => a.precio.compareTo(b.precio));
    case 'precio_desc':
      productos.sort((a, b) => b.precio.compareTo(a.precio));
    case 'nombre':
      productos.sort((a, b) => a.nombre.compareTo(b.nombre));
    case 'novedades':
      productos.sort((a, b) => b.id.compareTo(a.id));
  }

  return productos;
});

class CatalogoScreen extends ConsumerStatefulWidget {
  const CatalogoScreen({super.key});

  @override
  ConsumerState<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends ConsumerState<CatalogoScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productosAsync = ref.watch(_productosCatalogoProvider);
    final orden = ref.watch(_ordenCatalogoProvider);
    final categoriaId = ref.watch(_categoriaFiltroCatalogoProvider);
    final categoriasAsync = ref.watch(categoriasProvider);
    final destacadosAsync = ref.watch(destacadosProvider);
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;

    return Scaffold(
      body: Column(
        children: [
          // ── Banner slider destacados ──────────────────
          destacadosAsync.when(
            data: (destacados) => destacados.isEmpty
                ? const SizedBox.shrink()
                : _SliderDestacados(productos: destacados),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // ── Barra búsqueda ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) {
                ref.read(_busquedaCatalogoProvider.notifier).state = v;
                ref.invalidate(_productosCatalogoProvider);
              },
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          ref.read(_busquedaCatalogoProvider.notifier).state =
                              '';
                          ref.invalidate(_productosCatalogoProvider);
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                      )
                    : null,
              ),
            ),
          ),

          // ── Chips categorías + ordenación ─────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: const Text('Todos'),
                            selected: categoriaId == null,
                            onSelected: (_) {
                              ref
                                      .read(
                                        _categoriaFiltroCatalogoProvider
                                            .notifier,
                                      )
                                      .state =
                                  null;
                              ref.invalidate(_productosCatalogoProvider);
                            },
                          ),
                        ),
                        ...categoriasAsync.when(
                          data: (cats) => cats
                              .map(
                                (c) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    label: Text(c.nombre),
                                    selected: categoriaId == c.id,
                                    onSelected: (_) {
                                      ref
                                              .read(
                                                _categoriaFiltroCatalogoProvider
                                                    .notifier,
                                              )
                                              .state =
                                          c.id;
                                      ref.invalidate(
                                        _productosCatalogoProvider,
                                      );
                                    },
                                  ),
                                ),
                              )
                              .toList(),
                          loading: () => [],
                          error: (_, __) => [],
                        ),
                      ],
                    ),
                  ),
                ),
                // Botón ordenación
                PopupMenuButton<String>(
                  initialValue: orden,
                  onSelected: (v) {
                    ref.read(_ordenCatalogoProvider.notifier).state = v;
                    ref.invalidate(_productosCatalogoProvider);
                  },
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sort_rounded, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        _labelOrden(orden),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.accentGold,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'nombre', child: Text('Nombre A-Z')),
                    PopupMenuItem(
                      value: 'precio_asc',
                      child: Text('Precio: menor a mayor'),
                    ),
                    PopupMenuItem(
                      value: 'precio_desc',
                      child: Text('Precio: mayor a menor'),
                    ),
                    PopupMenuItem(value: 'novedades', child: Text('Novedades')),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 0.5),

          // ── Grid productos ────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.accentGold,
              onRefresh: () async {
                ref.invalidate(_productosCatalogoProvider);
                ref.invalidate(destacadosProvider);
              },
              child: productosAsync.when(
                data: (productos) => productos.isEmpty
                    ? const Center(child: Text('No hay productos'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWindows ? 3 : 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 260,
                        ),
                        itemCount: productos.length,
                        itemBuilder: (context, index) =>
                            ProductoCard(producto: productos[index]),
                      ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.accentGold),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48),
                      const SizedBox(height: 16),
                      Text(e.toString().replaceAll('Exception: ', '')),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () =>
                            ref.invalidate(_productosCatalogoProvider),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _labelOrden(String orden) {
    switch (orden) {
      case 'precio_asc':
        return 'Precio ↑';
      case 'precio_desc':
        return 'Precio ↓';
      case 'novedades':
        return 'Nuevo';
      default:
        return 'A-Z';
    }
  }
}

// ── Slider de destacados ───────────────────────────────────

class _SliderDestacados extends StatefulWidget {
  final List<Producto> productos;
  const _SliderDestacados({required this.productos});

  @override
  State<_SliderDestacados> createState() => _SliderDestacadosState();
}

class _SliderDestacadosState extends State<_SliderDestacados> {
  late PageController _pageController;
  int _paginaActual = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
    _arrancarAutoScroll();
  }

  void _arrancarAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final siguiente = (_paginaActual + 1) % widget.productos.length;
      _pageController.animateToPage(
        siguiente,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _arrancarAutoScroll();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _paginaActual = i),
            itemCount: widget.productos.length,
            itemBuilder: (context, index) {
              final p = widget.productos[index];
              return GestureDetector(
                onTap: () => context.push('/producto/${p.id}'),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (p.imagenUrl != null)
                        CachedNetworkImage(
                          imageUrl: p.imagenUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              const Icon(Icons.image_not_supported_outlined),
                        )
                      else
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1D1D1F), Color(0xFF3A3A3C)],
                            ),
                          ),
                        ),
                      // Gradiente
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.65),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Info
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentGold,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Text(
                                      'DESTACADO',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    p.nombre,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${p.precio.toStringAsFixed(2)} €',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Indicadores
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.productos.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _paginaActual == i ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _paginaActual == i
                    ? AppTheme.accentGold
                    : AppTheme.accentGold.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

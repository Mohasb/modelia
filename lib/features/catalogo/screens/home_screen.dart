import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:modelia/features/detalle/screens/visor_windows.dart'
    if (dart.library.html) 'package:modelia/features/detalle/screens/visor_stub.dart';
import 'package:modelia/shared/providers/productos_provider.dart';
import 'package:modelia/shared/models/producto.dart';
import 'package:modelia/shared/providers/carrito_provider.dart';
import 'package:modelia/core/theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destacadosAsync = ref.watch(destacadosProvider);

    return Scaffold(
      body: destacadosAsync.when(
        data: (destacados) => destacados.isEmpty
            ? const _SinDestacados()
            : _VistaDestacados(productos: destacados),
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
                onPressed: () => ref.invalidate(destacadosProvider),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VistaDestacados extends StatefulWidget {
  final List<Producto> productos;
  const _VistaDestacados({required this.productos});

  @override
  State<_VistaDestacados> createState() => _VistaDestacadosState();
}

class _VistaDestacadosState extends State<_VistaDestacados> {
  late PageController _pageController;
  int _paginaActual = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      final pagina = _pageController.page?.round() ?? 0;
      if (pagina != _paginaActual) {
        setState(() => _paginaActual = pagina);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: widget.productos.length,
          itemBuilder: (context, index) => _PaginaProducto(
            producto: widget.productos[index],
            esVisible: index == _paginaActual,
            hayMasProductos: index < widget.productos.length - 1,
            onSiguientePagina: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
          ),
        ),

        Positioned(
          right: 12,
          top: 0,
          bottom: 0,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                widget.productos.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  width: 6,
                  height: _paginaActual == i ? 20 : 6,
                  decoration: BoxDecoration(
                    color: _paginaActual == i
                        ? AppTheme.accentGold
                        : AppTheme.accentGold.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FlechaParpadeo extends StatefulWidget {
  const _FlechaParpadeo();

  @override
  State<_FlechaParpadeo> createState() => _FlechaParpadeoState();
}

class _FlechaParpadeoState extends State<_FlechaParpadeo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);

    _opacityAnim = Tween<double>(
      begin: 0.2,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnim,
      builder: (_, __) => Opacity(
        opacity: _opacityAnim.value,
        child: const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 42,
          color: AppTheme.accentGold,
        ),
      ),
    );
  }
}

class _BounceHint extends StatefulWidget {
  final VoidCallback? onTap;
  const _BounceHint({this.onTap});

  @override
  State<_BounceHint> createState() => _BounceHintState();
}

class _BounceHintState extends State<_BounceHint>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _offsetAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 18), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 18, end: 0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0, end: 12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 12, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _offsetAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, _offsetAnim.value),
          child: child,
        ),
        child: const _FlechaParpadeo(),
      ),
    );
  }
}

class _PaginaProducto extends ConsumerStatefulWidget {
  final Producto producto;
  final bool esVisible;
  final bool hayMasProductos;
  final VoidCallback? onSiguientePagina;

  const _PaginaProducto({
    required this.producto,
    required this.esVisible,
    required this.hayMasProductos,
    this.onSiguientePagina,
  });

  @override
  ConsumerState<_PaginaProducto> createState() => _PaginaProductoState();
}

class _PaginaProductoState extends ConsumerState<_PaginaProducto> {
  bool _mostrarModelo = false;

  @override
  void initState() {
    super.initState();
    if (widget.esVisible) _activarModelo();
  }

  @override
  void didUpdateWidget(_PaginaProducto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.esVisible && !_mostrarModelo) _activarModelo();
    if (!widget.esVisible && _mostrarModelo) {
      setState(() => _mostrarModelo = false);
    }
  }

  void _activarModelo() {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _mostrarModelo = true);
    });
  }

  void _agregarCarrito() {
    ref.read(carritoProvider.notifier).agregar(widget.producto);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.producto.nombre} añadido'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.accentGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;
    final colorScheme = Theme.of(context).colorScheme;
    final tieneModelo = p.modeloGlbUrl != null && p.modeloGlbUrl!.isNotEmpty;
    final esAndroid = defaultTargetPlatform == TargetPlatform.android;
    final esWindows = defaultTargetPlatform == TargetPlatform.windows;
    final soportaModelo = esAndroid || esWindows;

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return isLandscape
        ? _buildLandscape(
            context,
            p,
            colorScheme,
            tieneModelo,
            soportaModelo,
            esAndroid,
          )
        : _buildPortrait(
            context,
            p,
            colorScheme,
            tieneModelo,
            soportaModelo,
            esAndroid,
          );
  }

  Widget _buildPortrait(
    BuildContext context,
    Producto p,
    ColorScheme colorScheme,
    bool tieneModelo,
    bool soportaModelo,
    bool esAndroid,
  ) {
    final screenH = MediaQuery.of(context).size.height;
    const alturaFoto = 64.0;
    final alturaModelo = screenH * 0.50 - alturaFoto;

    return Column(
      children: [
        if (tieneModelo && soportaModelo)
          _bandaFoto(p, colorScheme, alturaFoto),

        if (tieneModelo && soportaModelo)
          _areaModelo(context, p, colorScheme, alturaModelo, esAndroid),

        if (!tieneModelo || !soportaModelo)
          _imagenSinModelo(p, colorScheme, alturaFoto + alturaModelo),

        Expanded(child: _infoYBotones(context, p, colorScheme)),
      ],
    );
  }

  Widget _buildLandscape(
    BuildContext context,
    Producto p,
    ColorScheme colorScheme,
    bool tieneModelo,
    bool soportaModelo,
    bool esAndroid,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: colorScheme.surfaceContainerHighest),

              if (tieneModelo && soportaModelo)
                _mostrarModelo
                    ? (esAndroid
                          ? ModelViewer(
                              src: p.modeloGlbUrl!,
                              alt: p.nombre,
                              ar: true,
                              arModes: const ['scene-viewer', 'webxr'],
                              autoRotate: true,
                              cameraControls: true,
                              backgroundColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color.fromARGB(255, 10, 10, 10)
                                  : const Color.fromARGB(255, 245, 245, 247),
                            )
                          : VisorWindows(modelUrl: p.modeloGlbUrl!))
                    : Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accentGold.withValues(alpha: 0.5),
                          strokeWidth: 2,
                        ),
                      )
              else if (p.imagenUrl != null)
                CachedNetworkImage(
                  imageUrl: p.imagenUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: colorScheme.surfaceContainerHighest),
                  errorWidget: (_, __, ___) => Icon(
                    Icons.image_not_supported_outlined,
                    size: 48,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                )
              else
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                ),

              Positioned(
                top: 8,
                left: 8,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'DESTACADO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              if (tieneModelo && soportaModelo)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.view_in_ar_rounded,
                          color: AppTheme.accentGold,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Ver en realidad aumentada →',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.accentGold,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        Expanded(
          flex: 4,
          child: _infoYBotones(context, p, colorScheme, landscape: true),
        ),
      ],
    );
  }

  Widget _bandaFoto(Producto p, ColorScheme colorScheme, double alturaFoto) {
    return SizedBox(
      height: alturaFoto,
      width: double.infinity,
      child: Container(
        color: colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'DESTACADO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const Spacer(),
            if (p.imagenUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CachedNetworkImage(
                    imageUrl: p.imagenUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color: colorScheme.surface,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 20,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _areaModelo(
    BuildContext context,
    Producto p,
    ColorScheme colorScheme,
    double alturaModelo,
    bool esAndroid,
  ) {
    return SizedBox(
      height: alturaModelo,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: colorScheme.surfaceContainerHighest),
          if (_mostrarModelo)
            esAndroid
                ? ModelViewer(
                    src: p.modeloGlbUrl!,
                    alt: p.nombre,
                    ar: true,
                    arModes: const ['scene-viewer', 'webxr'],
                    autoRotate: true,
                    cameraControls: true,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? const Color.fromARGB(255, 10, 10, 10)
                        : const Color.fromARGB(255, 245, 245, 247),
                  )
                : VisorWindows(modelUrl: p.modeloGlbUrl!)
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: AppTheme.accentGold.withValues(alpha: 0.5),
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cargando modelo 3D...',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.view_in_ar_rounded,
                    color: AppTheme.accentGold,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ver en realidad aumentada →',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagenSinModelo(Producto p, ColorScheme colorScheme, double altura) {
    return SizedBox(
      height: altura,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (p.imagenUrl != null)
            CachedNetworkImage(
              imageUrl: p.imagenUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: colorScheme.surfaceContainerHighest),
              errorWidget: (_, __, ___) => Icon(
                Icons.image_not_supported_outlined,
                size: 48,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            )
          else
            Container(
              color: colorScheme.surfaceContainerHighest,
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.6, 1.0],
                    colors: [Colors.transparent, colorScheme.surface],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'DESTACADO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoYBotones(
    BuildContext context,
    Producto p,
    ColorScheme colorScheme, {
    bool landscape = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        landscape ? 16 : 20,
        10,
        landscape ? 16 : 20,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            p.categoriaNombre.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.accentGold,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  p.nombre,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${p.precio.toStringAsFixed(2)} €',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: p.stock > 0
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      p.stock > 0 ? '${p.stock} en stock' : 'Sin stock',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: p.stock > 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!landscape &&
              p.descripcion != null &&
              p.descripcion!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              p.descripcion!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.55),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/producto/${p.id}'),
                  icon: const Icon(Icons.info_outline_rounded, size: 14),
                  label: const Text('Detalle'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: p.stock > 0 ? _agregarCarrito : null,
                  icon: const Icon(Icons.shopping_bag_outlined, size: 14),
                  label: const Text('Añadir'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
          if (widget.hayMasProductos)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Center(
                child: _BounceHint(onTap: widget.onSiguientePagina),
              ),
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _SinDestacados extends StatelessWidget {
  const _SinDestacados();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_outline_rounded,
              size: 56,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos destacados',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'El administrador puede destacar\nproductos desde el panel',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

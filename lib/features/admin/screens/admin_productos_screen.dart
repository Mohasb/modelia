import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:modelia/core/theme/app_theme.dart';
import 'package:modelia/shared/models/producto.dart';
import 'package:modelia/shared/providers/api_provider.dart';
import 'package:modelia/shared/providers/productos_provider.dart';

final _productosAdminProvider = FutureProvider<List<Producto>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getProductos();
});

class AdminProductosScreen extends ConsumerWidget {
  const AdminProductosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productosAsync = ref.watch(_productosAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_productosAdminProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(context, ref, null),
        backgroundColor: AppTheme.accentRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo producto'),
      ),
      body: productosAsync.when(
        data: (productos) => productos.isEmpty
            ? const Center(child: Text('No hay productos'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: productos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _ProductoAdminCard(
                  producto: productos[index],
                  onEditar: () =>
                      _mostrarFormulario(context, ref, productos[index]),
                  onEliminar: () =>
                      _confirmarEliminar(context, ref, productos[index]),
                ),
              ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentRed),
        ),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Future<void> _mostrarFormulario(
    BuildContext context,
    WidgetRef ref,
    Producto? producto,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FormularioProducto(
        producto: producto,
        onGuardado: () => ref.invalidate(_productosAdminProvider),
      ),
    );
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    WidgetRef ref,
    Producto producto,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${producto.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.accentRed),
            ),
          ),
        ],
      ),
    );

    if (confirmado == true && context.mounted) {
      try {
        await ref.read(apiServiceProvider).borrarProducto(producto.id);
        ref.invalidate(_productosAdminProvider);
        ref.invalidate(productosProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
      }
    }
  }
}

class _ProductoAdminCard extends StatelessWidget {
  final Producto producto;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _ProductoAdminCard({
    required this.producto,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: producto.imagenUrl != null
                  ? CachedNetworkImage(
                      imageUrl: producto.imagenUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: colorScheme.surface,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 20,
                        ),
                      ),
                    )
                  : Container(
                      color: colorScheme.surface,
                      child: const Icon(Icons.inventory_2_outlined, size: 20),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${producto.precio.toStringAsFixed(2)} € · Stock: ${producto.stock}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                Text(
                  producto.categoriaNombre,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.accentRed,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEditar,
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
          IconButton(
            onPressed: onEliminar,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormularioProducto extends ConsumerStatefulWidget {
  final Producto? producto;
  final VoidCallback onGuardado;

  const _FormularioProducto({this.producto, required this.onGuardado});

  @override
  ConsumerState<_FormularioProducto> createState() =>
      _FormularioProductoState();
}

class _FormularioProductoState extends ConsumerState<_FormularioProducto> {
  late TextEditingController _nombre;
  late TextEditingController _descripcion;
  late TextEditingController _precio;
  late TextEditingController _stock;
  late TextEditingController _imagenUrl;
  late TextEditingController _modeloUrl;
  int? _categoriaId;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _nombre = TextEditingController(text: p?.nombre ?? '');
    _descripcion = TextEditingController(text: p?.descripcion ?? '');
    _precio = TextEditingController(
      text: p != null ? p.precio.toStringAsFixed(2) : '',
    );
    _stock = TextEditingController(text: p != null ? '${p.stock}' : '');
    _imagenUrl = TextEditingController(text: p?.imagenUrl ?? '');
    _modeloUrl = TextEditingController(text: p?.modeloGlbUrl ?? '');
    _categoriaId = p?.categoriaId;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _descripcion.dispose();
    _precio.dispose();
    _stock.dispose();
    _imagenUrl.dispose();
    _modeloUrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombre.text.isEmpty || _precio.text.isEmpty || _categoriaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nombre, precio y categoría son obligatorios'),
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final datos = {
        'nombre': _nombre.text.trim(),
        'descripcion': _descripcion.text.trim().isEmpty
            ? null
            : _descripcion.text.trim(),
        'precio': double.parse(_precio.text.replaceAll(',', '.')),
        'stock': int.parse(_stock.text.isEmpty ? '0' : _stock.text),
        'imagenUrl': _imagenUrl.text.trim().isEmpty
            ? null
            : _imagenUrl.text.trim(),
        'modeloGlbUrl': _modeloUrl.text.trim().isEmpty
            ? null
            : _modeloUrl.text.trim(),
        'categoriaId': _categoriaId,
      };

      final api = ref.read(apiServiceProvider);
      if (widget.producto == null) {
        await api.crearProducto(datos);
      } else {
        await api.editarProducto(widget.producto!.id, datos);
      }

      widget.onGuardado();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriasAsync = ref.watch(categoriasProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.producto == null
                      ? 'Nuevo producto'
                      : 'Editar producto',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descripcion,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _precio,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Precio *',
                      suffixText: '€',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Categoría
            categoriasAsync.when(
              data: (categorias) => DropdownButtonFormField<int>(
                initialValue: _categoriaId,
                decoration: const InputDecoration(labelText: 'Categoría *'),
                items: categorias
                    .map(
                      (c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.nombre)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _categoriaId = v),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error al cargar categorías'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _imagenUrl,
              decoration: const InputDecoration(
                labelText: 'URL de imagen',
                hintText: 'https://...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _modeloUrl,
              decoration: const InputDecoration(
                labelText: 'URL modelo 3D (.glb)',
                hintText: 'https://... o http://IP:8080/modelos3d/...',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      widget.producto == null
                          ? 'Crear producto'
                          : 'Guardar cambios',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

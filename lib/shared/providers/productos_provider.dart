import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/producto.dart';
import '../models/categoria.dart';
import 'api_provider.dart';

final categoriasProvider = FutureProvider<List<Categoria>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getCategorias();
});

final categoriaSeleccionadaProvider = StateProvider<int?>((ref) => null);

final productosProvider = FutureProvider<List<Producto>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final categoriaId = ref.watch(categoriaSeleccionadaProvider);
  return api.getProductos(categoriaId: categoriaId);
});

final busquedaProvider = StateProvider<String>((ref) => '');

final productosBusquedaProvider = FutureProvider<List<Producto>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final busqueda = ref.watch(busquedaProvider);
  if (busqueda.isEmpty) return [];
  return api.getProductos(nombre: busqueda);
});

final productoDetalleProvider = FutureProvider.family<Producto, int>((
  ref,
  id,
) async {
  final api = ref.watch(apiServiceProvider);
  return api.getProductoById(id);
});

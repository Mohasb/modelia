import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/carrito_item.dart';
import '../models/producto.dart';

class CarritoNotifier extends StateNotifier<List<CarritoItem>> {
  CarritoNotifier() : super([]);

  void agregar(Producto producto) {
    final index = state.indexWhere((item) => item.producto.id == producto.id);
    if (index >= 0) {
      // Ya existe, incrementar cantidad
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            state[i].copyWith(cantidad: state[i].cantidad + 1)
          else
            state[i],
      ];
    } else {
      state = [...state, CarritoItem(producto: producto, cantidad: 1)];
    }
  }

  void reducir(Producto producto) {
    final index = state.indexWhere((item) => item.producto.id == producto.id);
    if (index < 0) return;
    if (state[index].cantidad <= 1) {
      eliminar(producto);
    } else {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            state[i].copyWith(cantidad: state[i].cantidad - 1)
          else
            state[i],
      ];
    }
  }

  void eliminar(Producto producto) {
    state = state.where((item) => item.producto.id != producto.id).toList();
  }

  void vaciar() {
    state = [];
  }

  int get totalItems => state.fold(0, (sum, item) => sum + item.cantidad);

  double get totalPrecio => state.fold(0.0, (sum, item) => sum + item.subtotal);

  List<Map<String, dynamic>> toRequestItems() => state
      .map(
        (item) => {'productoId': item.producto.id, 'cantidad': item.cantidad},
      )
      .toList();
}

final carritoProvider =
    StateNotifierProvider<CarritoNotifier, List<CarritoItem>>(
      (ref) => CarritoNotifier(),
    );

// Provider conveniente para el total de items (para el badge del carrito)
final carritoTotalItemsProvider = Provider<int>((ref) {
  final carrito = ref.watch(carritoProvider.notifier);
  ref.watch(carritoProvider);
  return carrito.totalItems;
});

// Provider para el precio total
final carritoPrecioTotalProvider = Provider<double>((ref) {
  final carrito = ref.watch(carritoProvider.notifier);
  ref.watch(carritoProvider);
  return carrito.totalPrecio;
});

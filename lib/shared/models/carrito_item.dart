import 'producto.dart';

class CarritoItem {
  final Producto producto;
  final int cantidad;

  const CarritoItem({required this.producto, required this.cantidad});

  double get subtotal => producto.precio * cantidad;

  CarritoItem copyWith({int? cantidad}) =>
      CarritoItem(producto: producto, cantidad: cantidad ?? this.cantidad);

  Map<String, dynamic> toJson() => {
    'productoId': producto.id,
    'cantidad': cantidad,
  };
}

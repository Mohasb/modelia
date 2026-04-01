class PedidoItem {
  final int id;
  final int productoId;
  final String nombreProducto;
  final int cantidad;
  final double precioUnitario;

  const PedidoItem({
    required this.id,
    required this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => precioUnitario * cantidad;

  factory PedidoItem.fromJson(Map<String, dynamic> json) => PedidoItem(
    id: json['id'],
    productoId: json['producto']?['id'] ?? 0,
    nombreProducto: json['nombreProducto'],
    cantidad: json['cantidad'],
    precioUnitario: (json['precioUnitario'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'productoId': productoId,
    'nombreProducto': nombreProducto,
    'cantidad': cantidad,
    'precioUnitario': precioUnitario,
  };
}

import 'pedido_item.dart';

class Pedido {
  final int id;
  final String estado;
  final double total;
  final String direccionEnvio;
  final String? notas;
  final DateTime createdAt;
  final List<PedidoItem> items;

  const Pedido({
    required this.id,
    required this.estado,
    required this.total,
    required this.direccionEnvio,
    this.notas,
    required this.createdAt,
    required this.items,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
    id: json['id'],
    estado: json['estado'],
    total: (json['total'] as num).toDouble(),
    direccionEnvio: json['direccionEnvio'],
    notas: json['notas'],
    createdAt: DateTime.parse(json['createdAt']),
    items:
        (json['items'] as List<dynamic>?)
            ?.map((i) => PedidoItem.fromJson(i))
            .toList() ??
        [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'estado': estado,
    'total': total,
    'direccionEnvio': direccionEnvio,
    'notas': notas,
    'createdAt': createdAt.toIso8601String(),
    'items': items.map((i) => i.toJson()).toList(),
  };
}

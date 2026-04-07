class Producto {
  final int id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final int stock;
  final String? imagenUrl;
  final String? modeloGlbUrl;
  final bool tieneAr;
  final int categoriaId;
  final String categoriaNombre;
  final bool destacado;

  const Producto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.stock,
    this.imagenUrl,
    this.modeloGlbUrl,
    required this.tieneAr,
    required this.categoriaId,
    required this.categoriaNombre,
    this.destacado = false,
  });

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
    id: json['id'],
    nombre: json['nombre'],
    descripcion: json['descripcion'],
    precio: (json['precio'] as num).toDouble(),
    stock: json['stock'],
    imagenUrl: json['imagenUrl'],
    modeloGlbUrl: json['modeloGlbUrl'],
    tieneAr: json['tieneAr'] ?? false,
    categoriaId: json['categoriaId'],
    categoriaNombre: json['categoriaNombre'] ?? '',
    destacado: json['destacado'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
    'precio': precio,
    'stock': stock,
    'imagenUrl': imagenUrl,
    'modeloGlbUrl': modeloGlbUrl,
    'tieneAr': tieneAr,
    'categoriaId': categoriaId,
    'categoriaNombre': categoriaNombre,
    'destacado': destacado,
  };
}

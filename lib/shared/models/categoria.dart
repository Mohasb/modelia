class Categoria {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? imagenUrl;
  final bool activo;

  const Categoria({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.imagenUrl,
    this.activo = true,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
    id: json['id'],
    nombre: json['nombre'],
    descripcion: json['descripcion'],
    imagenUrl: json['imagenUrl'],
    activo: json['activo'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'descripcion': descripcion,
    'imagenUrl': imagenUrl,
    'activo': activo,
  };
}

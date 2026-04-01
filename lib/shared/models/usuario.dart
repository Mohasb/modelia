class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final bool activo;
  final String? direccion;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.activo,
    this.direccion,
  });

  bool get esAdmin => rol == 'ADMIN';

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    id: json['id'],
    nombre: json['nombre'],
    email: json['email'],
    rol: json['rol'],
    activo: json['activo'] ?? true,
    direccion: json['direccion'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'email': email,
    'rol': rol,
    'activo': activo,
    'direccion': direccion,
  };
}

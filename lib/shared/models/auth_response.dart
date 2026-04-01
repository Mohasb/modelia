class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String tipo;
  final int id;
  final String nombre;
  final String email;
  final String rol;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tipo,
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
  });

  bool get esAdmin => rol == 'ADMIN';

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken: json['accessToken'],
    refreshToken: json['refreshToken'],
    tipo: json['tipo'],
    id: json['id'],
    nombre: json['nombre'],
    email: json['email'],
    rol: json['rol'],
  );
}

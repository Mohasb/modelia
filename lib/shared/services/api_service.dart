import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response.dart';
import '../models/categoria.dart';
import '../models/producto.dart';
import '../models/pedido.dart';
import '../models/usuario.dart';

class ApiService {
  final String baseUrl;
  VoidCallback? onSesionExpirada;
  bool _cerrando = false;

  ApiService({required this.baseUrl});

  Map<String, String> get _headersPublic => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Map<String, String>> get _headersAuth async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    print(
      '[API] Token: ${token.isEmpty ? "VACÍO" : "${token.substring(0, 20)}..."}',
    );
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> guardarTokens(AuthResponse auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', auth.accessToken);
    await prefs.setString('refresh_token', auth.refreshToken);
    await prefs.setString('usuario_email', auth.email);
    await prefs.setString('usuario_nombre', auth.nombre);
    await prefs.setString('usuario_rol', auth.rol);
    await prefs.setInt('usuario_id', auth.id);
    print('[API] Tokens guardados para usuario_id: ${auth.id}');
  }

  Future<void> borrarTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('usuario_email');
    await prefs.remove('usuario_nombre');
    await prefs.remove('usuario_rol');
    await prefs.remove('usuario_id');
    print('[API] Tokens borrados');
  }

  Future<bool> estaLogueado() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') != null;
  }

  Future<bool> _renovarToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token') ?? '';
      if (refreshToken.isEmpty) {
        print('[API] No hay refresh token');
        return false;
      }
      print('[API] Intentando renovar token...');
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/refresh'),
        headers: _headersPublic,
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await prefs.setString('access_token', data['accessToken']);
        print('[API] Token renovado correctamente');
        return true;
      }
      print('[API] Renovación fallida: ${response.statusCode}');
      return false;
    } catch (e) {
      print('[API] Error renovando token: $e');
      return false;
    }
  }

  Future<http.Response> _ejecutar(
    Future<http.Response> Function(Map<String, String> headers) peticion,
  ) async {
    var headers = await _headersAuth;
    var response = await peticion(headers);
    print('[API] Respuesta: ${response.statusCode} - ${response.request?.url}');

    if (response.statusCode == 403 && !_cerrando) {
      print('[API] 403 detectado, intentando renovar token...');
      final renovado = await _renovarToken();
      if (renovado) {
        headers = await _headersAuth;
        response = await peticion(headers);
        print('[API] Reintento tras renovación: ${response.statusCode}');
      } else if (!_cerrando) {
        print('[API] No se pudo renovar - sesión expirada');
        onSesionExpirada?.call();
      }
    }
    return response;
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 400) {
      print('[API] Error ${response.statusCode}: ${response.body}');
      try {
        final body = jsonDecode(response.body);
        throw Exception(
          body['mensaje'] ?? body['message'] ?? 'Error ${response.statusCode}',
        );
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Error ${response.statusCode}');
      }
    }
  }

  // ── Auth ──────────────────────────────────────────────────

  Future<AuthResponse> login(String email, String password) async {
    print('[API] POST /api/auth/login - email: $email');
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _headersPublic,
      body: jsonEncode({'email': email, 'password': password}),
    );
    print('[API] Login respuesta: ${response.statusCode} - ${response.body}');
    _checkResponse(response);
    return AuthResponse.fromJson(jsonDecode(response.body));
  }

  Future<String> register(String nombre, String email, String password) async {
    print('[API] POST /api/auth/register - email: $email');
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: _headersPublic,
      body: jsonEncode({
        'nombre': nombre,
        'email': email,
        'password': password,
      }),
    );
    print(
      '[API] Register respuesta: ${response.statusCode} - ${response.body}',
    );
    _checkResponse(response);
    return jsonDecode(response.body)['mensaje'];
  }

  Future<void> logout() async {
    print('[API] Logout iniciado');
    _cerrando = true;
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token') ?? '';
    await http
        .post(
          Uri.parse('$baseUrl/api/auth/logout'),
          headers: _headersPublic,
          body: jsonEncode({'refreshToken': refreshToken}),
        )
        .catchError((_) {});
    await borrarTokens();
    _cerrando = false;
    print('[API] Logout completado');
  }

  // ── Categorias ────────────────────────────────────────────

  Future<List<Categoria>> getCategorias() async {
    print('[API] GET /api/categorias');
    final response = await http.get(
      Uri.parse('$baseUrl/api/categorias'),
      headers: _headersPublic,
    );
    _checkResponse(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((j) => Categoria.fromJson(j)).toList();
  }

  // ── Productos ─────────────────────────────────────────────

  Future<List<Producto>> getProductos({
    int? categoriaId,
    String? nombre,
  }) async {
    final params = <String, String>{};
    if (categoriaId != null) params['categoriaId'] = categoriaId.toString();
    if (nombre != null && nombre.isNotEmpty) params['nombre'] = nombre;
    final uri = Uri.parse(
      '$baseUrl/api/productos',
    ).replace(queryParameters: params.isNotEmpty ? params : null);
    print('[API] GET $uri');
    final response = await http.get(uri, headers: _headersPublic);
    _checkResponse(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((j) => Producto.fromJson(j)).toList();
  }

  Future<Producto> getProductoById(int id) async {
    print('[API] GET /api/productos/$id');
    final response = await http.get(
      Uri.parse('$baseUrl/api/productos/$id'),
      headers: _headersPublic,
    );
    _checkResponse(response);
    return Producto.fromJson(jsonDecode(response.body));
  }

  // ── Pedidos ───────────────────────────────────────────────

  Future<Pedido> crearPedido(List<Map<String, dynamic>> items) async {
    print('[API] POST /api/pedidos - items: ${items.length}');
    final response = await _ejecutar(
      (headers) => http.post(
        Uri.parse('$baseUrl/api/pedidos'),
        headers: headers,
        body: jsonEncode({'items': items}),
      ),
    );
    print(
      '[API] Crear pedido respuesta: ${response.statusCode} - ${response.body}',
    );
    _checkResponse(response);
    return Pedido.fromJson(jsonDecode(response.body));
  }

  Future<List<Pedido>> getMisPedidos() async {
    print('[API] GET /api/pedidos/mis-pedidos');
    final response = await _ejecutar(
      (headers) => http.get(
        Uri.parse('$baseUrl/api/pedidos/mis-pedidos'),
        headers: headers,
      ),
    );
    print(
      '[API] Mis pedidos: ${response.statusCode} - ${response.body.substring(0, response.body.length.clamp(0, 200))}',
    );
    _checkResponse(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((j) => Pedido.fromJson(j)).toList();
  }

  // ── Perfil ────────────────────────────────────────────────

  Future<Usuario> getPerfil() async {
    print('[API] GET /api/usuario/perfil');
    final response = await _ejecutar(
      (headers) =>
          http.get(Uri.parse('$baseUrl/api/usuario/perfil'), headers: headers),
    );
    print('[API] Perfil: ${response.statusCode} - ${response.body}');
    _checkResponse(response);
    return Usuario.fromJson(jsonDecode(response.body));
  }

  Future<Usuario> updatePerfil(String nombre, String? direccion) async {
    print('[API] PUT /api/usuario/perfil');
    final response = await _ejecutar(
      (headers) => http.put(
        Uri.parse('$baseUrl/api/usuario/perfil'),
        headers: headers,
        body: jsonEncode({'nombre': nombre, 'direccion': direccion}),
      ),
    );
    _checkResponse(response);
    return Usuario.fromJson(jsonDecode(response.body));
  }

  // ── Admin: Productos ──────────────────────────────────────

  Future<Producto> crearProducto(Map<String, dynamic> datos) async {
    print('[API] POST /api/admin/productos');
    final response = await _ejecutar(
      (headers) => http.post(
        Uri.parse('$baseUrl/api/admin/productos'),
        headers: headers,
        body: jsonEncode(datos),
      ),
    );
    _checkResponse(response);
    return Producto.fromJson(jsonDecode(response.body));
  }

  Future<Producto> editarProducto(int id, Map<String, dynamic> datos) async {
    print('[API] PUT /api/admin/productos/$id');
    final response = await _ejecutar(
      (headers) => http.put(
        Uri.parse('$baseUrl/api/admin/productos/$id'),
        headers: headers,
        body: jsonEncode(datos),
      ),
    );
    _checkResponse(response);
    return Producto.fromJson(jsonDecode(response.body));
  }

  Future<void> borrarProducto(int id) async {
    print('[API] DELETE /api/admin/productos/$id');
    final response = await _ejecutar(
      (headers) => http.delete(
        Uri.parse('$baseUrl/api/admin/productos/$id'),
        headers: headers,
      ),
    );
    _checkResponse(response);
  }

  // ── Admin: Categorias ─────────────────────────────────────

  Future<Categoria> crearCategoria(String nombre, String? descripcion) async {
    print('[API] POST /api/admin/categorias');
    final response = await _ejecutar(
      (headers) => http.post(
        Uri.parse('$baseUrl/api/admin/categorias'),
        headers: headers,
        body: jsonEncode({'nombre': nombre, 'descripcion': descripcion}),
      ),
    );
    _checkResponse(response);
    return Categoria.fromJson(jsonDecode(response.body));
  }

  // ── Admin: Pedidos ────────────────────────────────────────

  Future<List<Pedido>> getTodosPedidos() async {
    print('[API] GET /api/admin/pedidos');
    final response = await _ejecutar(
      (headers) =>
          http.get(Uri.parse('$baseUrl/api/admin/pedidos'), headers: headers),
    );
    _checkResponse(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((j) => Pedido.fromJson(j)).toList();
  }

  Future<Pedido> cambiarEstadoPedido(int id, String estado) async {
    print('[API] PUT /api/admin/pedidos/$id/estado -> $estado');
    final response = await _ejecutar(
      (headers) => http.put(
        Uri.parse('$baseUrl/api/admin/pedidos/$id/estado'),
        headers: headers,
        body: jsonEncode({'estado': estado}),
      ),
    );
    _checkResponse(response);
    return Pedido.fromJson(jsonDecode(response.body));
  }

  // ── Admin: Usuarios ───────────────────────────────────────

  Future<List<Usuario>> getTodosUsuarios() async {
    print('[API] GET /api/admin/usuarios');
    final response = await _ejecutar(
      (headers) =>
          http.get(Uri.parse('$baseUrl/api/admin/usuarios'), headers: headers),
    );
    _checkResponse(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((j) => Usuario.fromJson(j)).toList();
  }

  Future<Usuario> toggleActivoUsuario(int id) async {
    print('[API] PUT /api/admin/usuarios/$id/toggle-activo');
    final response = await _ejecutar(
      (headers) => http.put(
        Uri.parse('$baseUrl/api/admin/usuarios/$id/toggle-activo'),
        headers: headers,
      ),
    );
    _checkResponse(response);
    return Usuario.fromJson(jsonDecode(response.body));
  }

  Future<Usuario> cambiarRolUsuario(int id, String rol) async {
    print('[API] PUT /api/admin/usuarios/$id/rol -> $rol');
    final response = await _ejecutar(
      (headers) => http.put(
        Uri.parse('$baseUrl/api/admin/usuarios/$id/rol'),
        headers: headers,
        body: jsonEncode({'rol': rol}),
      ),
    );
    _checkResponse(response);
    return Usuario.fromJson(jsonDecode(response.body));
  }
}

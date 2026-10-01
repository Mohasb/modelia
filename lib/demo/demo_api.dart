// Modo demo: sustituye al backend (ModeliaBackend) cuando se compila con
// --dart-define=DEMO=true. Responde a las mismas rutas /api/... con el mismo formato
// (ProductoResponse, PedidoResponse, PerfilResponse, JwtResponse, MensajeResponse)
// y las mismas reglas que los servicios de Spring Boot. Los datos viven en memoria:
// cada visita empieza de cero. Las peticiones que no son de la API pasan al cliente real.
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'demo_data.dart';

const bool kDemo = bool.fromEnvironment('DEMO');

/// Usuario con el que arranca la demo (rol CLIENTE).
const demoEmail = 'demo@example.com';
const demoPassword = 'Demo1234';

/// Administrador de la demo (botón en el login): panel, productos, pedidos y editor de temas.
const demoAdminEmail = 'admin@example.com';
const demoAdminPassword = 'Admin1234';

class _Usuario {
  _Usuario(this.id, this.nombre, this.email, this.password, this.rol,
      {this.direccion, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime(2026, 3, 1, 10);
  final int id;
  String nombre;
  final String email;
  String password;
  String rol;
  String? direccion;
  bool activo = true;
  final DateTime createdAt;
}

class _Pedido {
  _Pedido(this.id, this.usuarioId, this.estado, this.direccionEnvio, this.items,
      {this.notas, required this.createdAt});
  final int id;
  final int usuarioId;
  String estado;
  final String direccionEnvio;
  final String? notas;
  final DateTime createdAt;
  final List<Map<String, dynamic>> items; // id, productoId, nombreProducto, cantidad, precioUnitario
  double get total =>
      items.fold(0, (t, i) => t + (i['precioUnitario'] as double) * (i['cantidad'] as int));
}

/// Base de datos en memoria de la demo.
class _DemoDb {
  _DemoDb() {
    categorias = (jsonDecode(demoCategoriasJson) as List).cast<Map<String, dynamic>>();
    productos = (jsonDecode(demoProductosJson) as List).cast<Map<String, dynamic>>();
    usuarios = [
      _Usuario(1, 'Admin Demo', demoAdminEmail, demoAdminPassword, 'ADMIN'),
      _Usuario(2, 'Usuario Demo', demoEmail, demoPassword, 'CLIENTE',
          direccion: 'Calle Mayor 1, 03001 Alicante'),
      _Usuario(3, 'Laura Ejemplo', 'laura@example.com', 'Demo1234', 'CLIENTE'),
      _Usuario(4, 'Carlos Prueba', 'carlos@example.com', 'Demo1234', 'CLIENTE'),
    ];
    final ahora = DateTime.now();
    Map<String, dynamic> item(int id, int productoId, int cantidad) {
      final p = producto(productoId)!;
      return {
        'id': id,
        'productoId': productoId,
        'nombreProducto': p['nombre'],
        'cantidad': cantidad,
        'precioUnitario': (p['precio'] as num).toDouble(),
      };
    }

    pedidos = [
      _Pedido(1, 2, 'ENTREGADO', 'Calle Mayor 1, 03001 Alicante', [item(1, 3, 1), item(2, 2, 2)],
          createdAt: ahora.subtract(const Duration(days: 20))),
      _Pedido(2, 2, 'ENVIADO', 'Calle Mayor 1, 03001 Alicante', [item(3, 4, 1)],
          createdAt: ahora.subtract(const Duration(days: 2))),
      _Pedido(3, 3, 'PENDIENTE', 'Avenida del Puerto 12, Valencia', [item(4, 1, 1)],
          createdAt: ahora.subtract(const Duration(hours: 5))),
      _Pedido(4, 4, 'PROCESANDO', 'Plaza Nueva 3, Sevilla', [item(5, 2, 1), item(6, 4, 2)],
          createdAt: ahora.subtract(const Duration(days: 1))),
    ];
  }

  late List<Map<String, dynamic>> categorias;
  late List<Map<String, dynamic>> productos;
  late List<_Usuario> usuarios;
  late List<_Pedido> pedidos;

  Map<String, dynamic>? producto(int id) =>
      productos.where((p) => p['id'] == id).firstOrNull;
  Map<String, dynamic>? categoria(int id) =>
      categorias.where((c) => c['id'] == id).firstOrNull;
  _Usuario? usuario(int id) => usuarios.where((u) => u.id == id).firstOrNull;
  int nextId(Iterable<int> ids) => ids.fold(0, max) + 1;
}

/// Sesión del usuario demo (lo que guardaría AuthService tras un login).
Future<void> iniciarSesionDemo() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('access_token', 'demo.2');
  await prefs.setString('refresh_token', 'demo-refresh.2');
  await prefs.setString('usuario_email', demoEmail);
  await prefs.setString('usuario_nombre', 'Usuario Demo');
  await prefs.setString('usuario_rol', 'CLIENTE');
  await prefs.setInt('usuario_id', 2);
}

class DemoClient extends http.BaseClient {
  DemoClient(this._real);

  /// Cliente real para todo lo que no sea la API (imágenes, modelos 3D…).
  final http.Client _real;
  final _db = _DemoDb();
  final _rnd = Random();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!request.url.path.startsWith('/api/')) return _real.send(request);
    await Future.delayed(Duration(milliseconds: 150 + _rnd.nextInt(250)));
    final body = request is http.Request && request.body.isNotEmpty
        ? jsonDecode(request.body)
        : null;
    final r = _route(request, body);
    final bytes = r.body == null ? <int>[] : utf8.encode(jsonEncode(r.body));
    return http.StreamedResponse(Stream.value(bytes), r.status,
        request: request,
        headers: {'content-type': 'application/json; charset=utf-8'});
  }

  // ---------- Respuestas con el formato del backend ----------
  _R _ok(Object? body, [int status = 200]) => _R(status, body);
  _R _error(String mensaje, [int status = 400]) => _R(status, {'mensaje': mensaje});

  // Modelos 3D muy pesados (19-63 MB): la demo usa copias optimizadas (texturas a
  // 2048 px en JPEG y geometría Draco) que se publican junto a la web, en demo-models/.
  static const _modelosLigeros = {
    'electronica/cafetera/cafetera.glb': 'cafetera.glb',
    'calzado/trekking/trekking.glb': 'trekking.glb',
    'electronica/roland/roland.glb': 'roland.glb',
    'hogar/silla/silla.glb': 'silla.glb',
    'electronica/sony/sony.glb': 'sony.glb',
    'electronica/maxell/maxel.glb': 'maxel.glb',
  };
  String? _glbDemo(String? url) {
    if (url == null) return null;
    for (final e in _modelosLigeros.entries) {
      if (url.endsWith(e.key)) return 'demo-models/${e.value}';
    }
    return url;
  }

  Map<String, dynamic> _productoResponse(Map<String, dynamic> p) {
    final glb = _glbDemo(p['modeloGlbUrl'] as String?);
    return {
      'id': p['id'],
      'nombre': p['nombre'],
      'descripcion': p['descripcion'],
      'precio': p['precio'],
      'stock': p['stock'],
      'imagenUrl': p['imagenUrl'],
      'modeloGlbUrl': glb,
      'tieneAr': glb != null && glb.trim().isNotEmpty,
      'categoriaId': p['categoriaId'],
      'categoriaNombre': _db.categoria(p['categoriaId'] as int)?['nombre'],
      'destacado': p['destacado'],
    };
  }

  Map<String, dynamic> _pedidoResponse(_Pedido p) => {
        'id': p.id,
        'estado': p.estado,
        'total': p.total,
        'direccionEnvio': p.direccionEnvio,
        'notas': p.notas,
        'createdAt': p.createdAt.toIso8601String().split('.').first,
        'items': [
          for (final i in p.items)
            {
              ...i,
              'subtotal': (i['precioUnitario'] as double) * (i['cantidad'] as int),
            }
        ],
      };

  Map<String, dynamic> _perfilResponse(_Usuario u) => {
        'id': u.id,
        'nombre': u.nombre,
        'email': u.email,
        'rol': u.rol,
        'direccion': u.direccion,
        'createdAt': u.createdAt.toIso8601String().split('.').first,
        'activo': u.activo,
      };

  Map<String, dynamic> _jwt(_Usuario u) => {
        'accessToken': 'demo.${u.id}',
        'refreshToken': 'demo-refresh.${u.id}',
        'tipo': 'Bearer',
        'id': u.id,
        'nombre': u.nombre,
        'email': u.email,
        'rol': u.rol,
      };

  /// Usuario del token «Bearer demo.<id>» (null si no hay sesión → 403, como Spring Security).
  _Usuario? _actual(http.BaseRequest req) {
    final t = req.headers['Authorization'] ?? req.headers['authorization'] ?? '';
    final m = RegExp(r'demo\.(\d+)$').firstMatch(t);
    return m == null ? null : _db.usuario(int.parse(m.group(1)!));
  }

  // ---------- Rutas ----------
  _R _route(http.BaseRequest req, dynamic body) {
    final m = req.method;
    final seg = req.url.pathSegments.skip(1).toList(); // sin «api»
    final q = req.url.queryParameters;
    int? idAt(int i) => seg.length > i ? int.tryParse(seg[i]) : null;
    final admin = seg.isNotEmpty && seg[0] == 'admin';
    final yo = _actual(req);

    // Autenticación
    if (seg.length == 2 && seg[0] == 'auth' && m == 'POST') {
      switch (seg[1]) {
        case 'login':
          final u = _db.usuarios
              .where((u) => u.email.toLowerCase() == '${body['email']}'.toLowerCase())
              .firstOrNull;
          if (u == null || u.password != body['password']) {
            return _error('Email o password incorrectos', 401);
          }
          return _ok(_jwt(u));
        case 'register':
          final email = '${body['email']}'.trim();
          if (_db.usuarios.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
            return _error('El email ya está registrado');
          }
          _db.usuarios.add(_Usuario(_db.nextId(_db.usuarios.map((u) => u.id)),
              '${body['nombre']}', email, '${body['password']}', 'CLIENTE',
              createdAt: DateTime.now()));
          return _ok({'mensaje': 'Usuario registrado correctamente'}, 201);
        case 'refresh':
          final id = int.tryParse('${body['refreshToken']}'.split('.').last);
          final u = id == null ? null : _db.usuario(id);
          return u == null ? _error('Refresh token no válido') : _ok(_jwt(u));
        case 'logout':
          return _ok({'mensaje': 'Sesion cerrada correctamente'});
      }
    }

    // Públicas: categorías y productos
    if (seg.isNotEmpty && seg[0] == 'categorias' && m == 'GET') {
      if (seg.length == 1) return _ok(_db.categorias.where((c) => c['activo'] == true).toList());
      final c = _db.categoria(idAt(1) ?? -1);
      return c == null ? _error('Categoría no encontrada') : _ok(c);
    }
    if (seg.isNotEmpty && seg[0] == 'productos' && m == 'GET') {
      if (seg.length == 1) {
        final catId = int.tryParse(q['categoriaId'] ?? '');
        final nombre = (q['nombre'] ?? '').trim().toLowerCase();
        final lista = _db.productos.where((p) {
          if (p['activo'] != true) return false;
          if (catId != null) return p['categoriaId'] == catId;
          if (nombre.isNotEmpty) return '${p['nombre']}'.toLowerCase().contains(nombre);
          return true;
        });
        return _ok(lista.map(_productoResponse).toList());
      }
      if (seg[1] == 'destacados') {
        final lista = _db.productos.where((p) => p['destacado'] == true).toList()
          ..sort((a, b) => '${b['createdAt']}'.compareTo('${a['createdAt']}'));
        return _ok(lista.map(_productoResponse).toList());
      }
      final p = _db.producto(idAt(1) ?? -1);
      return p == null ? _error('Producto no encontrado') : _ok(_productoResponse(p));
    }

    // A partir de aquí hace falta sesión
    if (yo == null) return _R(403, null);

    // Pedidos del cliente
    if (seg.isNotEmpty && seg[0] == 'pedidos') {
      if (m == 'GET' && seg.length == 2 && seg[1] == 'mis-pedidos') {
        final lista = _db.pedidos.where((p) => p.usuarioId == yo.id).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return _ok(lista.map(_pedidoResponse).toList());
      }
      if (m == 'POST' && seg.length == 1) return _crearPedido(yo, body);
    }

    // Perfil
    if (seg.length == 2 && seg[0] == 'usuario' && seg[1] == 'perfil') {
      if (m == 'PUT') {
        yo.nombre = '${body['nombre'] ?? yo.nombre}';
        yo.direccion = body['direccion'] as String?;
      }
      return _ok(_perfilResponse(yo));
    }

    // Administración (como el backend real, exige rol ADMIN)
    if (admin) {
      if (yo.rol != 'ADMIN') return _R(403, null);
      return _admin(m, seg.skip(1).toList(), body);
    }
    return _error('Ruta no disponible en la demo', 404);
  }

  _R _crearPedido(_Usuario yo, dynamic body) {
    final items = <Map<String, dynamic>>[];
    for (final it in (body['items'] as List? ?? [])) {
      final p = _db.producto(it['productoId'] as int);
      if (p == null) return _error('Producto no encontrado: ${it['productoId']}');
      final cantidad = it['cantidad'] as int;
      if ((p['stock'] as int) < cantidad) return _error('Stock insuficiente para: ${p['nombre']}');
      p['stock'] = (p['stock'] as int) - cantidad;
      items.add({
        'id': _db.nextId(_db.pedidos.expand((x) => x.items).map((i) => i['id'] as int)) + items.length,
        'productoId': p['id'],
        'nombreProducto': p['nombre'],
        'cantidad': cantidad,
        'precioUnitario': (p['precio'] as num).toDouble(),
      });
    }
    if (items.isEmpty) return _error('items: must not be empty');
    final dir = '${body['direccionEnvio'] ?? ''}'.trim();
    final pedido = _Pedido(_db.nextId(_db.pedidos.map((p) => p.id)), yo.id, 'PENDIENTE',
        dir.isEmpty ? 'Direccion pendiente de confirmar' : dir, items,
        notas: body['notas'] as String?, createdAt: DateTime.now());
    _db.pedidos.add(pedido);
    return _ok(_pedidoResponse(pedido), 201);
  }

  _R _admin(String m, List<String> seg, dynamic body) {
    final id = seg.length > 1 ? int.tryParse(seg[1]) : null;
    switch (seg.first) {
      case 'productos':
        if (m == 'POST' && seg.length == 1) {
          final p = <String, dynamic>{
            'id': _db.nextId(_db.productos.map((p) => p['id'] as int)),
            'activo': true,
            'destacado': false,
            'createdAt': DateTime.now().toIso8601String().split('.').first,
          };
          _guardarProducto(p, body);
          _db.productos.add(p);
          return _ok(_productoResponse(p), 201);
        }
        final p = _db.producto(id ?? -1);
        if (p == null) return _error('Producto no encontrado');
        if (m == 'PUT' && seg.length == 2) {
          _guardarProducto(p, body);
          return _ok(_productoResponse(p));
        }
        if (m == 'DELETE') {
          p['activo'] = false; // borrado lógico, como ProductoService.delete
          return _R(204, null);
        }
        if (m == 'PUT' && seg.length == 3 && seg[2] == 'destacado') {
          p['destacado'] = !(p['destacado'] as bool);
          return _ok(_productoResponse(p));
        }
      case 'categorias':
        if (m == 'POST') {
          final c = {
            'id': _db.nextId(_db.categorias.map((c) => c['id'] as int)),
            'nombre': body['nombre'],
            'descripcion': body['descripcion'],
            'imagenUrl': body['imagenUrl'],
            'activo': body['activo'] ?? true,
          };
          _db.categorias.add(c);
          return _ok(c, 201);
        }
        if (m == 'DELETE') {
          final c = _db.categoria(id ?? -1);
          if (c == null) return _error('Categoría no encontrada');
          c['activo'] = false;
          return _R(204, null);
        }
      case 'pedidos':
        if (m == 'GET') return _ok(_db.pedidos.map(_pedidoResponse).toList());
        if (m == 'PUT' && seg.length == 3 && seg[2] == 'estado') {
          final p = _db.pedidos.where((p) => p.id == id).firstOrNull;
          if (p == null) return _error('Pedido no encontrado');
          const estados = ['PENDIENTE', 'PROCESANDO', 'ENVIADO', 'ENTREGADO', 'CANCELADO'];
          final e = '${body['estado']}';
          if (!estados.contains(e)) return _error('No enum constant com.mhh.modelia.entity.Pedido.Estado.$e');
          p.estado = e;
          return _ok(_pedidoResponse(p));
        }
      case 'usuarios':
        if (m == 'GET') return _ok(_db.usuarios.map(_perfilResponse).toList());
        final u = _db.usuario(id ?? -1);
        if (u == null) return _error('Usuario no encontrado');
        if (seg.length == 3 && seg[2] == 'toggle-activo') u.activo = !u.activo;
        if (seg.length == 3 && seg[2] == 'rol') u.rol = '${body['estado']}';
        return _ok(_perfilResponse(u));
    }
    return _error('Ruta no disponible en la demo', 404);
  }

  void _guardarProducto(Map<String, dynamic> p, dynamic b) {
    p
      ..['nombre'] = b['nombre']
      ..['descripcion'] = b['descripcion']
      ..['precio'] = (b['precio'] as num).toDouble()
      ..['stock'] = b['stock'] ?? 0
      ..['stockMinimo'] = b['stockMinimo'] ?? 5
      ..['imagenUrl'] = b['imagenUrl']
      ..['modeloGlbUrl'] = b['modeloGlbUrl']
      ..['categoriaId'] = b['categoriaId'];
  }
}

class _R {
  _R(this.status, this.body);
  final int status;
  final Object? body;
}

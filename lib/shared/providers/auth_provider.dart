import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'api_provider.dart';

class AuthState {
  final bool isLogueado;
  final bool isAdmin;
  final bool isLoading;
  final String? error;
  final String? nombre;
  final String? email;
  final int? id;
  final bool sesionExpirada;
  final int version; // incrementa en cada login/logout

  const AuthState({
    this.isLogueado = false,
    this.isAdmin = false,
    this.isLoading = false,
    this.error,
    this.nombre,
    this.email,
    this.id,
    this.sesionExpirada = false,
    this.version = 0,
  });

  AuthState copyWith({
    bool? isLogueado,
    bool? isAdmin,
    bool? isLoading,
    String? error,
    String? nombre,
    String? email,
    int? id,
    bool? sesionExpirada,
    int? version,
  }) => AuthState(
    isLogueado: isLogueado ?? this.isLogueado,
    isAdmin: isAdmin ?? this.isAdmin,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    nombre: nombre ?? this.nombre,
    email: email ?? this.email,
    id: id ?? this.id,
    sesionExpirada: sesionExpirada ?? this.sesionExpirada,
    version: version ?? this.version,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;

  AuthNotifier(this._api) : super(const AuthState()) {
    _cargarSesionGuardada();
  }

  Future<void> _cargarSesionGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      final id = prefs.getInt('usuario_id');
      print('[AUTH] Sesión guardada encontrada - usuario_id: $id');
      state = AuthState(
        isLogueado: true,
        isAdmin: prefs.getString('usuario_rol') == 'ADMIN',
        nombre: prefs.getString('usuario_nombre'),
        email: prefs.getString('usuario_email'),
        id: id,
        version: 1,
      );
    } else {
      print('[AUTH] No hay sesión guardada');
    }
  }

  Future<void> login(String email, String password) async {
    print('[AUTH] Intentando login con: $email');
    state = AuthState(isLoading: true, version: state.version);
    try {
      final auth = await _api.login(email, password);
      await _api.guardarTokens(auth);
      print('[AUTH] Login exitoso - usuario_id: ${auth.id}, rol: ${auth.rol}');
      state = AuthState(
        isLogueado: true,
        isAdmin: auth.esAdmin,
        nombre: auth.nombre,
        email: auth.email,
        id: auth.id,
        version: state.version + 1, // fuerza recalculo de providers
      );
    } catch (e) {
      print('[AUTH] Login fallido: $e');
      state = AuthState(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
        version: state.version,
      );
    }
  }

  Future<void> register(String nombre, String email, String password) async {
    print('[AUTH] Registrando: $email');
    state = AuthState(isLoading: true, version: state.version);
    try {
      await _api.register(nombre, email, password);
      await login(email, password);
    } catch (e) {
      print('[AUTH] Register fallido: $e');
      state = AuthState(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
        version: state.version,
      );
    }
  }

  Future<void> logout() async {
    print('[AUTH] Logout - limpiando sesión');
    await _api.logout();
    state = AuthState(version: state.version + 1); // fuerza recalculo
  }

  void sesionExpirada() {
    print('[AUTH] Sesión expirada - redirigiendo a login');
    _api.borrarTokens();
    state = AuthState(sesionExpirada: true, version: state.version + 1);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AuthNotifier(api);
});

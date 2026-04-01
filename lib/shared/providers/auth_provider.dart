import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modelia/shared/providers/pedidos_provider.dart';
import 'package:modelia/shared/providers/perfil_provider.dart';
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

  const AuthState({
    this.isLogueado = false,
    this.isAdmin = false,
    this.isLoading = false,
    this.error,
    this.nombre,
    this.email,
    this.id,
    this.sesionExpirada = false,
  });

  AuthState copyWith({
    bool? isLogueado,
    bool? isAdmin,
    bool? isLoading,
    Object? error = _sentinel, // valor centinela
    String? nombre,
    String? email,
    int? id,
    bool? sesionExpirada,
  }) => AuthState(
    isLogueado: isLogueado ?? this.isLogueado,
    isAdmin: isAdmin ?? this.isAdmin,
    isLoading: isLoading ?? this.isLoading,
    error: error == _sentinel ? this.error : error as String?,
    nombre: nombre ?? this.nombre,
    email: email ?? this.email,
    id: id ?? this.id,
    sesionExpirada: sesionExpirada ?? this.sesionExpirada,
  );

  static const Object _sentinel = Object();
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  final Ref _ref;

  AuthNotifier(this._api, this._ref) : super(const AuthState()) {
    _cargarSesionGuardada();
  }

  Future<void> _cargarSesionGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      state = AuthState(
        isLogueado: true,
        isAdmin: prefs.getString('usuario_rol') == 'ADMIN',
        nombre: prefs.getString('usuario_nombre'),
        email: prefs.getString('usuario_email'),
        id: prefs.getInt('usuario_id'),
      );
    }
  }

  Future<void> login(String email, String password) async {
    // Limpiar error previo explícitamente antes de intentar
    state = AuthState(
      isLoading: true,
      nombre: state.nombre,
      email: state.email,
      id: state.id,
    );
    try {
      final auth = await _api.login(email, password);
      await _api.guardarTokens(auth);
      _ref.invalidate(perfilProvider);
      _ref.invalidate(misPedidosProvider);
      state = AuthState(
        isLogueado: true,
        isAdmin: auth.esAdmin,
        nombre: auth.nombre,
        email: auth.email,
        id: auth.id,
      );
    } catch (e) {
      // Mantener los campos del formulario, solo actualizar error
      state = AuthState(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> register(String nombre, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _api.register(nombre, email, password);
      await login(email, password);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    await _api.logout();
    // Invalidar caché de perfil al salir
    _ref.invalidate(perfilProvider);
    _ref.invalidate(misPedidosProvider);
    state = const AuthState(sesionExpirada: false);
  }

  // Llamado desde ApiService cuando el refresh token falla
  void sesionExpirada() {
    _api.borrarTokens();
    _ref.invalidate(perfilProvider);
    _ref.invalidate(misPedidosProvider);
    state = const AuthState(sesionExpirada: true);
  }

  void clearError() {
    state = state.copyWith(error: null, sesionExpirada: false);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AuthNotifier(api, ref);
});

// perfil_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modelia/shared/models/usuario.dart';
import 'package:modelia/shared/providers/api_provider.dart';
import 'package:modelia/shared/providers/auth_provider.dart';

final perfilProvider = FutureProvider<Usuario>((ref) async {
  final authState = ref.watch(authProvider);
  print(
    '[PERFIL] Provider recalculando - isLogueado: ${authState.isLogueado}, id: ${authState.id}, version: ${authState.version}',
  );

  if (!authState.isLogueado || authState.id == null) {
    print('[PERFIL] No autenticado');
    throw Exception('No autenticado');
  }

  print('[PERFIL] Cargando perfil para usuario_id: ${authState.id}');
  final api = ref.watch(apiServiceProvider);
  final usuario = await api.getPerfil();
  print('[PERFIL] Perfil cargado: ${usuario.nombre} (id: ${usuario.id})');
  return usuario;
});

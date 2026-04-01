// pedidos_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modelia/shared/models/pedido.dart';
import 'package:modelia/shared/providers/api_provider.dart';
import 'package:modelia/shared/providers/auth_provider.dart';

final misPedidosProvider = FutureProvider<List<Pedido>>((ref) async {
  final authState = ref.watch(authProvider);
  print(
    '[PEDIDOS] Provider recalculando - isLogueado: ${authState.isLogueado}, id: ${authState.id}, version: ${authState.version}',
  );

  if (!authState.isLogueado || authState.id == null) {
    print('[PEDIDOS] No autenticado, devolviendo lista vacía');
    return [];
  }

  print('[PEDIDOS] Cargando pedidos para usuario_id: ${authState.id}');
  final api = ref.watch(apiServiceProvider);
  final pedidos = await api.getMisPedidos();
  print(
    '[PEDIDOS] Cargados ${pedidos.length} pedidos para usuario_id: ${authState.id}',
  );
  return pedidos;
});

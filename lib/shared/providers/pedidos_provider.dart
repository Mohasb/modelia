import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modelia/shared/models/pedido.dart';
import 'package:modelia/shared/providers/api_provider.dart';

final misPedidosProvider = FutureProvider<List<Pedido>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getMisPedidos();
});
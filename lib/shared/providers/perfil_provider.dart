import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modelia/shared/models/usuario.dart';
import 'package:modelia/shared/providers/api_provider.dart';

final perfilProvider = FutureProvider<Usuario>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getPerfil();
});

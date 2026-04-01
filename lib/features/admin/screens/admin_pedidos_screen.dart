import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modelia/core/theme/app_theme.dart';
import 'package:modelia/shared/models/pedido.dart';
import 'package:modelia/shared/providers/api_provider.dart';
import 'package:modelia/core/utils/constants.dart';

final _pedidosAdminProvider = FutureProvider<List<Pedido>>((ref) async {
  return ref.watch(apiServiceProvider).getTodosPedidos();
});

class AdminPedidosScreen extends ConsumerWidget {
  const AdminPedidosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pedidosAsync = ref.watch(_pedidosAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_pedidosAdminProvider),
          ),
        ],
      ),
      body: pedidosAsync.when(
        data: (pedidos) => pedidos.isEmpty
            ? const Center(child: Text('No hay pedidos'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: pedidos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _PedidoAdminCard(pedido: pedidos[index]),
              ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentRed),
        ),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _PedidoAdminCard extends ConsumerWidget {
  final Pedido pedido;
  const _PedidoAdminCard({required this.pedido});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final colorEstado = Color(
      AppConstants.coloresEstado[pedido.estado] ?? 0xFF888888,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pedido #${pedido.id}',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorEstado.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pedido.estado,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorEstado,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${pedido.total.toStringAsFixed(2)} € · ${pedido.items.length} producto(s)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 10),

          // Cambiar estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  [
                        'PENDIENTE',
                        'PROCESANDO',
                        'ENVIADO',
                        'ENTREGADO',
                        'CANCELADO',
                      ]
                      .map(
                        (estado) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: pedido.estado == estado
                                ? null
                                : () async {
                                    try {
                                      await ref
                                          .read(apiServiceProvider)
                                          .cambiarEstadoPedido(
                                            pedido.id,
                                            estado,
                                          );
                                      ref.invalidate(_pedidosAdminProvider);
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString()),
                                            backgroundColor: AppTheme.accentRed,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: pedido.estado == estado
                                    ? colorEstado
                                    : colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: pedido.estado == estado
                                      ? colorEstado
                                      : colorScheme.onSurface.withOpacity(0.15),
                                ),
                              ),
                              child: Text(
                                estado,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: pedido.estado == estado
                                      ? Colors.white
                                      : colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modelia/core/theme/app_theme.dart';
import 'package:modelia/shared/models/usuario.dart';
import 'package:modelia/shared/providers/api_provider.dart';

final _usuariosAdminProvider = FutureProvider<List<Usuario>>((ref) async {
  return ref.watch(apiServiceProvider).getTodosUsuarios();
});

class AdminUsuariosScreen extends ConsumerWidget {
  const AdminUsuariosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuariosAsync = ref.watch(_usuariosAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_usuariosAdminProvider),
          ),
        ],
      ),
      body: usuariosAsync.when(
        data: (usuarios) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: usuarios.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _UsuarioAdminCard(usuario: usuarios[index]),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentRed),
        ),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _UsuarioAdminCard extends ConsumerWidget {
  final Usuario usuario;
  const _UsuarioAdminCard({required this.usuario});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final esAdmin = usuario.rol == 'ADMIN';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: esAdmin ? AppTheme.accentRed : colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                usuario.nombre[0].toUpperCase(),
                style: TextStyle(
                  color: esAdmin ? Colors.white : colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usuario.nombre,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  usuario.email,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: esAdmin
                            ? AppTheme.accentRed.withValues(alpha: 0.1)
                            : colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        usuario.rol,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: esAdmin
                              ? AppTheme.accentRed
                              : colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: usuario.activo
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        usuario.activo ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: usuario.activo ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Acciones
          PopupMenuButton<String>(
            onSelected: (accion) async {
              try {
                final api = ref.read(apiServiceProvider);
                if (accion == 'toggle') {
                  await api.toggleActivoUsuario(usuario.id);
                } else if (accion == 'admin') {
                  await api.cambiarRolUsuario(
                    usuario.id,
                    esAdmin ? 'CLIENTE' : 'ADMIN',
                  );
                }
                ref.invalidate(_usuariosAdminProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: AppTheme.accentRed,
                    ),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(
                  children: [
                    Icon(
                      usuario.activo
                          ? Icons.block_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(usuario.activo ? 'Desactivar' : 'Activar'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'admin',
                child: Row(
                  children: [
                    Icon(
                      esAdmin
                          ? Icons.person_outline_rounded
                          : Icons.admin_panel_settings_outlined,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(esAdmin ? 'Quitar admin' : 'Hacer admin'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

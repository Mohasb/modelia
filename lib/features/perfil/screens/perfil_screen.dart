import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:modelia/shared/providers/auth_provider.dart';
import 'package:modelia/shared/providers/api_provider.dart';
import 'package:modelia/core/theme/app_theme.dart';
import 'package:modelia/shared/providers/perfil_provider.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final perfilAsync = ref.watch(perfilProvider);

    if (!authState.isLogueado) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              const Text('Inicia sesión para ver tu perfil'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.push('/login'),
                child: const Text('Iniciar sesión'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 22),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: perfilAsync.when(
        data: (usuario) => _PerfilContent(usuario: usuario),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentRed),
        ),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }
}

class _PerfilContent extends ConsumerStatefulWidget {
  final dynamic usuario;
  const _PerfilContent({required this.usuario});

  @override
  ConsumerState<_PerfilContent> createState() => _PerfilContentState();
}

class _PerfilContentState extends ConsumerState<_PerfilContent> {
  late TextEditingController _nombreController;
  late TextEditingController _direccionController;
  bool _editando = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.usuario.nombre);
    _direccionController = TextEditingController(
      text: widget.usuario.direccion ?? '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.updatePerfil(
        _nombreController.text.trim(),
        _direccionController.text.trim().isEmpty
            ? null
            : _direccionController.text.trim(),
      );
      ref.invalidate(perfilProvider);
      setState(() {
        _editando = false;
        _guardando = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Perfil actualizado'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppTheme.accentRed,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (widget.usuario.nombre as String)[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.usuario.nombre,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: widget.usuario.rol == 'ADMIN'
                        ? AppTheme.accentRed.withValues(alpha: 0.1)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.usuario.rol == 'ADMIN' ? 'Administrador' : 'Cliente',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: widget.usuario.rol == 'ADMIN'
                          ? AppTheme.accentRed
                          : colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Datos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Datos personales',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (!_editando)
                      GestureDetector(
                        onTap: () => setState(() => _editando = true),
                        child: const Text(
                          'Editar',
                          style: TextStyle(
                            color: AppTheme.accentRed,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Email (solo lectura)
                _CampoInfo(
                  label: 'Email',
                  valor: widget.usuario.email,
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 12),

                // Nombre
                if (_editando)
                  TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                  )
                else
                  _CampoInfo(
                    label: 'Nombre',
                    valor: widget.usuario.nombre,
                    icon: Icons.person_outline_rounded,
                  ),
                const SizedBox(height: 12),

                // Dirección
                if (_editando)
                  TextField(
                    controller: _direccionController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección de envío',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                    ),
                  )
                else
                  _CampoInfo(
                    label: 'Dirección',
                    valor: widget.usuario.direccion ?? 'No especificada',
                    icon: Icons.location_on_outlined,
                  ),

                if (_editando) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _editando = false),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _guardando ? null : _guardar,
                          child: _guardando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Accesos rápidos
          _AccesoRapido(
            icon: Icons.receipt_long_outlined,
            label: 'Mis pedidos',
            onTap: () => context.go('/mis-pedidos'),
          ),
          const SizedBox(height: 8),
          if ((widget.usuario.rol as String) == 'ADMIN')
            _AccesoRapido(
              icon: Icons.admin_panel_settings_outlined,
              label: 'Panel de administración',
              color: AppTheme.accentRed,
              onTap: () => context.go('/admin'),
            ),
        ],
      ),
    );
  }
}

class _CampoInfo extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icon;

  const _CampoInfo({
    required this.label,
    required this.valor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
            Text(
              valor,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccesoRapido extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _AccesoRapido({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color ?? colorScheme.onSurface),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

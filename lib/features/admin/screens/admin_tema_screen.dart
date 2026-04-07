import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import 'package:modelia/features/admin/screens/preview_tema.dart';
import 'package:modelia/shared/providers/theme_provider.dart';
import 'package:modelia/shared/models/tema_config.dart';
import 'package:modelia/core/theme/app_theme.dart';

// Provider local para el estado temporal de edición
final _temaEditadoProvider = StateProvider<TemaConfig>((ref) {
  return ref.read(themeProvider).temaConfig;
});

class AdminTemaScreen extends ConsumerStatefulWidget {
  const AdminTemaScreen({super.key});

  @override
  ConsumerState<AdminTemaScreen> createState() => _AdminTemaScreenState();
}

class _AdminTemaScreenState extends ConsumerState<AdminTemaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nombreController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = ref.read(themeProvider).temaConfig;
      ref.read(_temaEditadoProvider.notifier).state = config;
      _nombreController = TextEditingController(text: config.appNombre);
    });
    _nombreController = TextEditingController(text: 'Modelia');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreController.dispose();
    super.dispose();
  }

  void _aplicar() {
    final configEditado = ref.read(_temaEditadoProvider);
    ref.read(themeProvider.notifier).aplicarConfig(configEditado);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tema aplicado correctamente'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _resetear() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resetear tema'),
        content: const Text('¿Restaurar todos los colores por defecto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(_temaEditadoProvider.notifier).state =
                  const TemaConfig();
            },
            child: const Text(
              'Resetear',
              style: TextStyle(color: AppTheme.accentGold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final configEditado = ref.watch(_temaEditadoProvider);
    final isDarkPreview = ref.watch(themeProvider).themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalizar tema'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          TextButton(
            onPressed: _resetear,
            child: const Text(
              'Resetear',
              style: TextStyle(color: AppTheme.accentGold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Preview interactiva
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: PreviewTema(
              config: configEditado,
              isDarkInicial: isDarkPreview,
            ),
          ),
          const SizedBox(height: 16),

          // Selectores de color
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En el SingleChildScrollView, antes de _SeccionColores:
                  _SeccionTexto(
                    titulo: 'Nombre de la app',
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: TextField(
                          controller: _nombreController,
                          onChanged: (valor) {
                            final config = ref.read(_temaEditadoProvider);
                            ref
                                .read(_temaEditadoProvider.notifier)
                                .state = config.copyWith(
                              appNombre: valor.isEmpty ? 'Modelia' : valor,
                            );
                          },
                          decoration: const InputDecoration(
                            labelText: 'Nombre visible en la app',
                            hintText: 'Ej: Mi Tienda, ShopAR...',
                            prefixIcon: Icon(Icons.title_rounded, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SeccionColores(
                    titulo: 'Color de acento',
                    children: [
                      _ColorTile(
                        label: 'Color principal',
                        campo: 'accentColor',
                        color: configEditado.accentColor,
                        descripcion: 'Botones, chips activos, precios',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SeccionColores(
                    titulo: 'Modo claro',
                    children: [
                      _ColorTile(
                        label: 'Fondo',
                        campo: 'lightBg',
                        color: configEditado.lightBg,
                        descripcion: 'Fondo principal',
                      ),
                      _ColorTile(
                        label: 'Superficie',
                        campo: 'lightSurface',
                        color: configEditado.lightSurface,
                        descripcion: 'Inputs y chips',
                      ),
                      _ColorTile(
                        label: 'Tarjetas',
                        campo: 'lightCard',
                        color: configEditado.lightCard,
                        descripcion: 'Cards de productos',
                      ),
                      _ColorTile(
                        label: 'Texto',
                        campo: 'textDark',
                        color: configEditado.textDark,
                        descripcion: 'Texto en modo claro',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SeccionColores(
                    titulo: 'Modo oscuro',
                    children: [
                      _ColorTile(
                        label: 'Fondo',
                        campo: 'darkBg',
                        color: configEditado.darkBg,
                        descripcion: 'Fondo en modo oscuro',
                      ),
                      _ColorTile(
                        label: 'Superficie',
                        campo: 'darkSurface',
                        color: configEditado.darkSurface,
                        descripcion: 'Cards en modo oscuro',
                      ),
                      _ColorTile(
                        label: 'Tarjetas',
                        campo: 'darkCard',
                        color: configEditado.darkCard,
                        descripcion: 'Elementos secundarios oscuro',
                      ),
                      _ColorTile(
                        label: 'Texto',
                        campo: 'textLight',
                        color: configEditado.textLight,
                        descripcion: 'Texto en modo oscuro',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Botón aplicar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.08),
                  width: 0.5,
                ),
              ),
            ),
            child: FilledButton.icon(
              onPressed: _aplicar,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Aplicar cambios a la app'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionTexto extends StatelessWidget {
  final String titulo;
  final List<Widget> children;

  const _SeccionTexto({required this.titulo, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SeccionColores extends StatelessWidget {
  final String titulo;
  final List<Widget> children;
  const _SeccionColores({required this.titulo, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ── Tile de color ──────────────────────────────────────────

class _ColorTile extends ConsumerWidget {
  final String label;
  final String campo;
  final Color color;
  final String descripcion;

  const _ColorTile({
    required this.label,
    required this.campo,
    required this.color,
    required this.descripcion,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      leading: GestureDetector(
        onTap: () => _abrirPicker(context, ref),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.15),
            ),
          ),
        ),
      ),
      title: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        descripcion,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      trailing: Text(
        '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      onTap: () => _abrirPicker(context, ref),
    );
  }

  void _abrirPicker(BuildContext context, WidgetRef ref) {
    Color colorTemp = color;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cambiar: $label'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: color,
            onColorChanged: (c) => colorTemp = c,
            enableAlpha: false,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              // Solo actualiza el estado temporal, NO el tema real
              final config = ref.read(_temaEditadoProvider);
              ref.read(_temaEditadoProvider.notifier).state = _aplicarCampo(
                config,
                campo,
                colorTemp,
              );
              Navigator.pop(ctx);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  TemaConfig _aplicarCampo(TemaConfig config, String campo, Color color) {
    switch (campo) {
      case 'accentColor':
        return config.copyWith(accentColor: color);
      case 'lightBg':
        return config.copyWith(lightBg: color);
      case 'lightSurface':
        return config.copyWith(lightSurface: color);
      case 'lightCard':
        return config.copyWith(lightCard: color);
      case 'darkBg':
        return config.copyWith(darkBg: color);
      case 'darkSurface':
        return config.copyWith(darkSurface: color);
      case 'darkCard':
        return config.copyWith(darkCard: color);
      case 'textDark':
        return config.copyWith(textDark: color);
      case 'textLight':
        return config.copyWith(textLight: color);
      default:
        return config;
    }
  }
}

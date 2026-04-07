import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:modelia/shared/providers/productos_provider.dart';
import 'package:modelia/core/theme/app_theme.dart';

import 'package:modelia/features/detalle/screens/visor_windows.dart'
    if (dart.library.js) 'package:modelia/features/detalle/screens/visor_stub.dart';

class ArViewerScreen extends ConsumerWidget {
  final int productoId;
  const ArViewerScreen({super.key, required this.productoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productoAsync = ref.watch(productoDetalleProvider(productoId));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Ver en 3D', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: productoAsync.when(
        data: (producto) {
          final modelUrl = producto.modeloGlbUrl;
          if (modelUrl == null || modelUrl.isEmpty) {
            return const _SinModelo();
          }
          if (defaultTargetPlatform == TargetPlatform.android) {
            return _VisorAndroid(modelUrl: modelUrl, nombre: producto.nombre);
          }
          return VisorWindows(modelUrl: modelUrl);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentGold),
        ),
        error: (e, _) => Center(
          child: Text(
            e.toString(),
            style: const TextStyle(color: Colors.white54),
          ),
        ),
      ),
    );
  }
}

class _VisorAndroid extends StatelessWidget {
  final String modelUrl;
  final String nombre;
  const _VisorAndroid({required this.modelUrl, required this.nombre});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // El ModelViewer ocupa toda la pantalla
        // El botón AR nativo aparece automáticamente dentro del visor
        Expanded(
          child: ModelViewer(
            src: modelUrl,
            alt: nombre,
            ar: true,
            arModes: const ['scene-viewer', 'webxr'],
            autoRotate: true,
            cameraControls: true,
            shadowIntensity: 1,
          ),
        ),
        // Panel inferior solo con texto informativo
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          color: Theme.of(context).colorScheme.surface,
          child: Text(
            'Rota y explora el modelo en 3D · Pulsa el botón AR del visor',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _SinModelo extends StatelessWidget {
  const _SinModelo();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.threed_rotation_rounded, size: 64, color: Colors.white38),
          SizedBox(height: 16),
          Text(
            'Modelo 3D no disponible',
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

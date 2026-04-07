import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:modelia/core/theme/app_theme.dart';

class VisorPruebaScreen extends StatefulWidget {
  const VisorPruebaScreen({super.key});

  @override
  State<VisorPruebaScreen> createState() => _VisorPruebaScreenState();
}

class _VisorPruebaScreenState extends State<VisorPruebaScreen> {
  late WebViewController _controller;
  bool _cargado = false;

  // Animaciones disponibles — se rellenan desde el modelo
  List<String> _animaciones = [];
  String? _animacionSeleccionada;

  // Colores predefinidos para probar
  final List<_ColorOpcion> _colores = [
    _ColorOpcion('Original', null),
    _ColorOpcion('Rojo', [1.0, 0.0, 0.0, 1.0]),
    _ColorOpcion('Azul', [0.0, 0.3, 1.0, 1.0]),
    _ColorOpcion('Verde', [0.0, 0.8, 0.2, 1.0]),
    _ColorOpcion('Amarillo', [1.0, 0.9, 0.0, 1.0]),
    _ColorOpcion('Naranja', [1.0, 0.4, 0.0, 1.0]),
    _ColorOpcion('Negro', [0.05, 0.05, 0.05, 1.0]),
    _ColorOpcion('Blanco', [1.0, 1.0, 1.0, 1.0]),
  ];
  _ColorOpcion? _colorSeleccionado;

  // Índice de material a modificar
  int _materialIndex = 0;
  int _totalMateriales = 1;

  static const String _modelUrl =
      'https://modelviewer.dev/shared-assets/models/RobotExpressive.glb';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (msg) {
          final data = msg.message;
          print('[VISOR] Mensaje JS: $data');

          if (data.startsWith('ANIMATIONS:')) {
            final raw = data.replaceFirst('ANIMATIONS:', '');
            if (raw.isNotEmpty) {
              final lista = raw
                  .split(',')
                  .where((s) => s.trim().isNotEmpty)
                  .toList();
              if (mounted) {
                setState(() {
                  _animaciones = lista;
                  if (lista.isNotEmpty) {
                    _animacionSeleccionada = lista.first;
                  }
                });
              }
            }
          } else if (data.startsWith('MATERIALS:')) {
            final raw = data.replaceFirst('MATERIALS:', '');
            final total = int.tryParse(raw) ?? 1;
            if (mounted) setState(() => _totalMateriales = total);
          } else if (data == 'LOADED') {
            if (mounted) setState(() => _cargado = true);
            _consultarAnimaciones();
            _consultarMateriales();
          }
        },
      )
      ..loadHtmlString(_buildHtml());
  }

  String _buildHtml() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <script type="module" 
    src="https://ajax.googleapis.com/ajax/libs/model-viewer/3.3.0/model-viewer.min.js">
  </script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: transparent; width: 100%; height: 100vh; }
    model-viewer { width: 100%; height: 100%; background-color: transparent; }
  </style>
</head>
<body>
  <model-viewer
    id="mv"
    src="$_modelUrl"
    camera-controls
    auto-rotate
    ar
    ar-modes="scene-viewer webxr"
    shadow-intensity="1"
  ></model-viewer>

  <script>
    const mv = document.getElementById('mv');

    mv.addEventListener('load', () => {
      FlutterBridge.postMessage('LOADED');
    });

    function getAnimations() {
      const anims = mv.availableAnimations || [];
      FlutterBridge.postMessage('ANIMATIONS:' + anims.join(','));
    }

    function getMaterials() {
      const mats = mv.model ? mv.model.materials.length : 1;
      FlutterBridge.postMessage('MATERIALS:' + mats);
    }

    function playAnimation(name) {
      mv.animationName = name;
      mv.play({ repetitions: Infinity });
    }

    function stopAnimation() {
      mv.pause();
    }

    function setColor(matIndex, r, g, b) {
      try {
        const mat = mv.model.materials[matIndex];
        mat.pbrMetallicRoughness.setBaseColorFactor([r, g, b, 1.0]);
      } catch(e) {
        console.error('Error setColor:', e);
      }
    }

    function resetColor(matIndex) {
      try {
        const mat = mv.model.materials[matIndex];
        mat.pbrMetallicRoughness.setBaseColorFactor([1.0, 1.0, 1.0, 1.0]);
      } catch(e) {
        console.error('Error resetColor:', e);
      }
    }
  </script>
</body>
</html>
''';
  }

  void _consultarAnimaciones() {
    _controller.runJavaScript('getAnimations()');
  }

  void _consultarMateriales() {
    _controller.runJavaScript('getMaterials()');
  }

  void _reproducirAnimacion(String nombre) {
    _controller.runJavaScript("playAnimation('$nombre')");
    setState(() => _animacionSeleccionada = nombre);
  }

  void _detenerAnimacion() {
    _controller.runJavaScript('stopAnimation()');
    setState(() => _animacionSeleccionada = null);
  }

  void _aplicarColor(_ColorOpcion opcion) {
    setState(() => _colorSeleccionado = opcion);
    if (opcion.rgba == null) {
      _controller.runJavaScript('resetColor($_materialIndex)');
    } else {
      final r = opcion.rgba![0];
      final g = opcion.rgba![1];
      final b = opcion.rgba![2];
      _controller.runJavaScript('setColor($_materialIndex, $r, $g, $b)');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visor 3D — Pruebas'),
        actions: [
          if (_cargado)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text('Modelo cargado', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Visor 3D ─────────────────────────────────
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (!_cargado)
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: AppTheme.accentGold),
                        SizedBox(height: 12),
                        Text('Cargando modelo...'),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Controles ─────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Animaciones ──────────────────────
                  Text(
                    'Animaciones',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_animaciones.isEmpty)
                    Text(
                      _cargado
                          ? 'Este modelo no tiene animaciones'
                          : 'Cargando...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _animacionSeleccionada,
                            decoration: const InputDecoration(
                              labelText: 'Seleccionar animación',
                              isDense: true,
                            ),
                            items: _animaciones
                                .map(
                                  (a) => DropdownMenuItem(
                                    value: a,
                                    child: Text(
                                      a,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) _reproducirAnimacion(v);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          onPressed: _detenerAnimacion,
                          icon: const Icon(Icons.stop_rounded),
                          tooltip: 'Detener',
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // ── Material a modificar ─────────────
                  if (_totalMateriales > 1) ...[
                    Text(
                      'Material (${_materialIndex + 1}/$_totalMateriales)',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _materialIndex > 0
                              ? () => setState(() => _materialIndex--)
                              : null,
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Expanded(
                          child: Text(
                            'Material ${_materialIndex + 1}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        IconButton(
                          onPressed: _materialIndex < _totalMateriales - 1
                              ? () => setState(() => _materialIndex++)
                              : null,
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // ── Colores ──────────────────────────
                  Text(
                    'Color del material',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<_ColorOpcion>(
                    value: _colorSeleccionado ?? _colores.first,
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar color',
                      isDense: true,
                    ),
                    items: _colores
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Row(
                              children: [
                                if (c.rgba != null)
                                  Container(
                                    width: 16,
                                    height: 16,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(
                                        (c.rgba![0] * 255).toInt(),
                                        (c.rgba![1] * 255).toInt(),
                                        (c.rgba![2] * 255).toInt(),
                                        1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 16,
                                    height: 16,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade400,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Icon(
                                      Icons.refresh_rounded,
                                      size: 12,
                                    ),
                                  ),
                                Text(c.nombre),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _aplicarColor(v);
                    },
                  ),

                  const SizedBox(height: 8),

                  // Info materiales
                  if (_cargado)
                    Text(
                      '$_totalMateriales material${_totalMateriales != 1 ? 'es' : ''} detectado${_totalMateriales != 1 ? 's' : ''} en el modelo',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorOpcion {
  final String nombre;
  final List<double>? rgba;
  const _ColorOpcion(this.nombre, this.rgba);
}

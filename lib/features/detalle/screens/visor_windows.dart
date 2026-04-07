import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:modelia/core/theme/app_theme.dart';

class VisorWindows extends StatefulWidget {
  final String modelUrl;
  const VisorWindows({super.key, required this.modelUrl});

  @override
  State<VisorWindows> createState() => _VisorWindowsState();
}

class _VisorWindowsState extends State<VisorWindows> {
  final _controller = WebviewController();
  bool _inicializado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    try {
      await _controller.initialize();

      // Copiar el HTML a un fichero temporal y cargarlo
      final htmlContent = await rootBundle.loadString(
        'assets/model_viewer.html',
      );
      final tempDir = await getTemporaryDirectory();
      final htmlFile = File('${tempDir.path}/model_viewer.html');
      await htmlFile.writeAsString(htmlContent);

      // Cargar el HTML con la URL del modelo como parámetro
      final encodedUrl = Uri.encodeComponent(widget.modelUrl);
      await _controller.loadUrl('file:///${htmlFile.path}?src=$encodedUrl');

      if (mounted) setState(() => _inicializado = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white38, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar el visor',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white24, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_inicializado) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.accentGold),
            SizedBox(height: 16),
            Text('Cargando modelo...', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    return Webview(_controller);
  }
}

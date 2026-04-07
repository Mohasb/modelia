import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:modelia/shared/widgets/logo_bolsa.dart';
import 'package:path_provider/path_provider.dart';

class IconCaptureScreen extends StatefulWidget {
  const IconCaptureScreen({super.key});

  @override
  State<IconCaptureScreen> createState() => _IconCaptureScreenState();
}

class _IconCaptureScreenState extends State<IconCaptureScreen> {
  final GlobalKey _key = GlobalKey();
  String _estado = 'Listo para capturar';

  Future<void> _capturar() async {
    setState(() => _estado = 'Capturando...');
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      final boundary =
          _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 4.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();

      // Guardar en Documents
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/modelia_icon.png');
      await file.writeAsBytes(bytes);

      print('[ICONO] Guardado en: ${file.path}');
      setState(
        () => _estado =
            '✓ Guardado en:\n${file.path}\n\n'
            '${image.width}x${image.height}px',
      );
    } catch (e) {
      setState(() => _estado = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(title: const Text('Capturar icono')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Widget que se va a capturar — exactamente 256x256
            RepaintBoundary(
              key: _key,
              child: const SizedBox(
                width: 256,
                height: 256,
                child: LogoBolsa(
                  size: 256,
                  isDark: false, // fondo blanco para el icono
                  mostrarFondo: true,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _estado,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _capturar,
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Capturar como PNG'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ejecuta en Windows para hacer\n'
              'screenshot con Snipping Tool',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

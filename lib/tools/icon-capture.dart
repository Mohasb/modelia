import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final boundary = _key.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        setState(() => _estado = 'Error: boundary null');
        return;
      }

      // pixelRatio 4 = 1024x1024 sobre un widget de 256x256
      final image = await boundary.toImage(pixelRatio: 4.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/modelia_icon.png');
      await file.writeAsBytes(bytes);

      setState(() => _estado =
          '✓ Guardado en:\n${file.path}\n\n${image.width}x${image.height}px');
    } catch (e) {
      setState(() => _estado = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capturar icono')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Widget que se captura — 256x256 con padding
            RepaintBoundary(
              key: _key,
              child: Container(
                width: 256,
                height: 256,
                color: const Color(0xFF0A0A0A),
                padding: const EdgeInsets.all(40),
                child: Image.asset(
                  'assets/icons/icon.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _estado,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _capturar,
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Capturar como PNG'),
            ),
            const SizedBox(height: 12),
            const Text(
              'El fichero se guarda en Documentos',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
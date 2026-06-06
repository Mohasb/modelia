// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class VisorWeb extends StatefulWidget {
  final String modelUrl;
  const VisorWeb({super.key, required this.modelUrl});

  @override
  State<VisorWeb> createState() => _VisorWebState();
}

class _VisorWebState extends State<VisorWeb> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _viewId = 'model-viewer-${widget.modelUrl.hashCode}';

    ui.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final script = web.document.createElement('script') as web.HTMLScriptElement;
      script.type = 'module';
      script.src = 'https://ajax.googleapis.com/ajax/libs/model-viewer/3.5.0/model-viewer.min.js';
      web.document.head!.appendChild(script);

      final mv = web.document.createElement('model-viewer') as web.HTMLElement;
      mv.setAttribute('src', widget.modelUrl);
      mv.setAttribute('auto-rotate', '');
      mv.setAttribute('camera-controls', '');
      mv.setAttribute('shadow-intensity', '1');
      mv.style.width = '100%';
      mv.style.height = '100%';
      mv.style.backgroundColor = '#1a1a1a';
      return mv;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
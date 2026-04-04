import 'package:flutter/material.dart';
import 'package:modelia/core/theme/logo_config.dart';

class LogoBolsa extends StatelessWidget {
  final double size;
  final bool isDark;
  final bool mostrarFondo;

  const LogoBolsa({
    super.key,
    this.size = 200,
    this.isDark = true,
    this.mostrarFondo = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BolsaPainter(isDark: isDark, mostrarFondo: mostrarFondo),
      ),
    );
  }
}

class _BolsaPainter extends CustomPainter {
  final bool isDark;
  final bool mostrarFondo;

  const _BolsaPainter({required this.isDark, required this.mostrarFondo});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final fondoExterior = isDark
        ? LogoConfig.fondoExteriorDark
        : LogoConfig.fondoExteriorLight;
    final fondoInterior = isDark
        ? LogoConfig.fondoInteriorDark
        : LogoConfig.fondoInteriorLight;

    if (mostrarFondo) {
      canvas.drawCircle(Offset(cx, cy), r, Paint()..color = fondoExterior);
      canvas.drawCircle(
        Offset(cx, cy),
        r * 0.96,
        Paint()..color = fondoInterior,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        r * 0.98,
        Paint()
          ..color = LogoConfig.anilloExterior.withOpacity(
            LogoConfig.anilloExteriorOpacity,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );
    }

    _dibujarBolsa(canvas, cx, cy, r, 1.0);
  }

  void _dibujarBolsa(
    Canvas canvas,
    double cx,
    double cy,
    double r,
    double progreso,
  ) {
    // Dimensiones de la bolsa centradas en cy
    final cuerpoW = r * 1.0;
    final cuerpoH = r * 0.82;
    // Altura del asa
    final asaH = r * 0.44;
    // Altura total = asa + cuerpo
    final alturaTotal = asaH + cuerpoH;
    // cuerpoY calculado para que todo quede centrado verticalmente
    final cuerpoY = cy - alturaTotal / 2 + asaH;
    final cuerpoX = cx - cuerpoW / 2;
    final radio = r * 0.16;

    // ── Asa ─────────────────────────────────────────────
    final asaW = r * 0.58;
    final asaTop = cuerpoY - asaH;
    final asaPath = Path()
      ..moveTo(cx - asaW / 2, cuerpoY)
      ..cubicTo(
        cx - asaW / 2,
        asaTop,
        cx + asaW / 2,
        asaTop,
        cx + asaW / 2,
        cuerpoY,
      );

    // Borde negro visible
    canvas.drawPath(
      asaPath,
      Paint()
        ..color = LogoConfig.bolsaCuerpo.withOpacity(0.9 * progreso)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12 + 7
        ..strokeCap = StrokeCap.round,
    );

    // Asa interior
    canvas.drawPath(
      asaPath,
      Paint()
        ..color = (isDark ? LogoConfig.bolsaAsaDark : LogoConfig.bolsaAsa)
            .withOpacity(progreso)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.12
        ..strokeCap = StrokeCap.round,
    );

    // ── Cuerpo ────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cuerpoX, cuerpoY, cuerpoW, cuerpoH),
        Radius.circular(radio),
      ),
      Paint()..color = LogoConfig.bolsaCuerpo.withOpacity(progreso),
    );

    // ── Cuerpo ───────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cuerpoX, cuerpoY, cuerpoW, cuerpoH),
        Radius.circular(radio),
      ),
      Paint()..color = LogoConfig.bolsaCuerpo.withOpacity(progreso),
    );

    // ── Brillo lateral izquierdo ─────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cuerpoX + r * 0.05,
          cuerpoY + r * 0.05,
          cuerpoW * 0.26,
          cuerpoH * 0.82,
        ),
        Radius.circular(radio * 0.8),
      ),
      Paint()
        ..color = Colors.white.withOpacity(
          LogoConfig.bolsaBrilloOpacity * progreso,
        ),
    );

    // ── Franja inferior ──────────────────────────────────
    final franjaH = cuerpoH * 0.28;
    final franjaY = cuerpoY + cuerpoH - franjaH;
    canvas.drawPath(
      Path()..addRRect(
        RRect.fromLTRBAndCorners(
          cuerpoX,
          franjaY,
          cuerpoX + cuerpoW,
          cuerpoY + cuerpoH,
          bottomLeft: Radius.circular(radio),
          bottomRight: Radius.circular(radio),
        ),
      ),
      Paint()..color = const Color(0xFF000000).withOpacity(0.18 * progreso),
    );

    // ── Punto central — centrado en el cuerpo ─────────────
    final puntoCY = cuerpoY + cuerpoH * 0.46;
    canvas.drawCircle(
      Offset(cx, puntoCY),
      r * 0.12,
      Paint()..color = const Color(0xFF000000).withOpacity(0.2 * progreso),
    );
    canvas.drawCircle(
      Offset(cx, puntoCY),
      r * 0.06,
      Paint()
        ..color = Colors.white.withOpacity(
          LogoConfig.bolsaPuntoOpacity * progreso,
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _BolsaPainter old) =>
      isDark != old.isDark || mostrarFondo != old.mostrarFondo;
}

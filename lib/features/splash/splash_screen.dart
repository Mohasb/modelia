import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modelia/core/theme/logo_config.dart';
import 'package:modelia/shared/providers/theme_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _parteControllers;
  late List<Animation<double>> _parteAnims;
  late AnimationController _glowController;
  late AnimationController _textoController;
  late AnimationController _exitController;
  late Animation<double> _glowAnim;
  late Animation<double> _textoAnim;
  late Animation<double> _exitAnim;

  // Partes: fondo, asa, cuerpo, brillo, franja, punto
  static const int _numPartes = 6;
  bool _isDark = true;

  @override
  void initState() {
    super.initState();
    _cargarTema();

    _parteControllers = List.generate(
      _numPartes,
      (i) => AnimationController(
        duration: const Duration(milliseconds: 280),
        vsync: this,
      ),
    );

    _parteAnims = _parteControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _glowAnim = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );

    _textoController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _textoAnim = CurvedAnimation(
      parent: _textoController,
      curve: Curves.easeOut,
    );

    _exitController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _exitAnim = CurvedAnimation(parent: _exitController, curve: Curves.easeIn);

    _arrancarSecuencia();
  }

  Future<void> _cargarTema() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? false;
    if (mounted) setState(() => _isDark = isDark);
  }

  Future<void> _arrancarSecuencia() async {
    await Future.delayed(const Duration(milliseconds: 300));

    for (int i = 0; i < _numPartes; i++) {
      _parteControllers[i].forward();
      await Future.delayed(const Duration(milliseconds: 140));
    }

    await Future.delayed(const Duration(milliseconds: 100));
    _glowController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _textoController.forward();

    await Future.delayed(const Duration(milliseconds: 900));

    _exitController.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    context.go('/');
  }

  @override
  void dispose() {
    for (final c in _parteControllers) c.dispose();
    _glowController.dispose();
    _textoController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appNombre = ref.watch(themeProvider).temaConfig.appNombre;

    final fondoColor = _isDark
        ? LogoConfig.fondoExteriorDark
        : LogoConfig.fondoExteriorLight;
    final textoColor = _isDark ? Colors.white : const Color(0xFF1D1D1F);

    return AnimatedBuilder(
      animation: _exitController,
      builder: (context, child) =>
          Opacity(opacity: 1.0 - _exitAnim.value, child: child),
      child: Scaffold(
        backgroundColor: fondoColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Logo animado ────────────────────────────
              SizedBox(
                width: 220,
                height: 220,
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    ..._parteControllers,
                    _glowController,
                  ]),
                  builder: (context, _) => Stack(
                    alignment: Alignment.center,
                    children: [
                      // Halo glow
                      Opacity(
                        opacity: _glowAnim.value * 0.3,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: LogoConfig.bolsaCuerpo.withOpacity(0.2),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: _glowAnim.value * 0.45,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: LogoConfig.bolsaCuerpo.withOpacity(0.12),
                          ),
                        ),
                      ),

                      // Bolsa animada parte a parte
                      CustomPaint(
                        size: const Size(220, 220),
                        painter: _BolsaSplashPainter(
                          parteValues: _parteAnims.map((a) => a.value).toList(),
                          glowValue: _glowAnim.value,
                          isDark: _isDark,
                        ),
                      ),

                      // Flash central
                      Opacity(
                        opacity:
                            _glowAnim.value * (1 - _glowAnim.value) * 4 * 0.4,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── Texto animado ───────────────────────────
              AnimatedBuilder(
                animation: _textoController,
                builder: (context, _) => Opacity(
                  opacity: _textoAnim.value,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - _textoAnim.value)),
                    child: Column(
                      children: [
                        Text(
                          appNombre,
                          style: TextStyle(
                            color: textoColor,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'TIENDA 3D · AR',
                          style: TextStyle(
                            color: LogoConfig.bolsaCuerpo,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Painter bolsa animada parte a parte ───────────────────

class _BolsaSplashPainter extends CustomPainter {
  final List<double> parteValues;
  final double glowValue;
  final bool isDark;

  const _BolsaSplashPainter({
    required this.parteValues,
    required this.glowValue,
    required this.isDark,
  });

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

    final f = parteValues;

    // Parte 0 — Fondo circular
    if (f[0] > 0) {
      canvas.drawCircle(
        Offset(cx, cy),
        r * f[0],
        Paint()..color = fondoExterior,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        r * 0.96 * f[0],
        Paint()..color = fondoInterior,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        r * 0.98,
        Paint()
          ..color = LogoConfig.anilloExterior.withOpacity(
            LogoConfig.anilloExteriorOpacity * f[0],
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    final cuerpoW = r * 1.04;
    final cuerpoH = r * 0.9;
    final cuerpoX = cx - cuerpoW / 2;
    final cuerpoY = cy - r * 0.08;
    final radio = r * 0.18;

    // Parte 1 — Asa
    if (f[1] > 0) {
      final asaW = r * 0.62;
      final asaH = r * 0.5;
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
      canvas.drawPath(
        asaPath,
        Paint()
          ..color = LogoConfig.bolsaAsa.withOpacity(f[1])
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.11
          ..strokeCap = StrokeCap.round,
      );
    }

    // Parte 2 — Cuerpo
    if (f[2] > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cuerpoX, cuerpoY, cuerpoW, cuerpoH),
          Radius.circular(radio),
        ),
        Paint()..color = LogoConfig.bolsaCuerpo.withOpacity(f[2]),
      );
    }

    // Parte 3 — Brillo lateral
    if (f[3] > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            cuerpoX + r * 0.05,
            cuerpoY + r * 0.05,
            cuerpoW * 0.28,
            cuerpoH * 0.85,
          ),
          Radius.circular(radio * 0.8),
        ),
        Paint()
          ..color = LogoConfig.bolsaBrillo.withOpacity(
            LogoConfig.bolsaBrilloOpacity * f[3],
          ),
      );
    }

    // Parte 4 — Franja inferior
    if (f[4] > 0) {
      final franjaH = cuerpoH * 0.3;
      final franjaY = cuerpoY + cuerpoH - franjaH;
      final franjaPath = Path()
        ..addRRect(
          RRect.fromLTRBAndCorners(
            cuerpoX,
            franjaY,
            cuerpoX + cuerpoW,
            cuerpoY + cuerpoH,
            bottomLeft: Radius.circular(radio),
            bottomRight: Radius.circular(radio),
          ),
        );
      canvas.drawPath(
        franjaPath,
        Paint()..color = const Color(0xFF000000).withOpacity(0.18 * f[4]),
      );
    }

    // Parte 5 — Punto central
    if (f[5] > 0) {
      final puntoY = cuerpoY + cuerpoH * 0.42;
      canvas.drawCircle(
        Offset(cx, puntoY),
        r * 0.13,
        Paint()..color = const Color(0xFF000000).withOpacity(0.18 * f[5]),
      );
      canvas.drawCircle(
        Offset(cx, puntoY),
        r * 0.065,
        Paint()
          ..color = LogoConfig.bolsaPunto.withOpacity(
            LogoConfig.bolsaPuntoOpacity * f[5],
          ),
      );
    }

    // Glow final
    if (glowValue > 0) {
      canvas.drawCircle(
        Offset(cx, cy),
        r * 0.5,
        Paint()
          ..color = LogoConfig.bolsaCuerpo.withOpacity(0.06 * glowValue)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BolsaSplashPainter old) =>
      parteValues != old.parteValues ||
      glowValue != old.glowValue ||
      isDark != old.isDark;
}

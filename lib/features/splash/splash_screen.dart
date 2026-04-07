import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modelia/shared/providers/theme_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Logo: escala + fade in
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  // Destello dorado
  late AnimationController _glowController;
  late Animation<double> _glowOpacity;
  late Animation<double> _glowScale;

  // Texto: sube desde abajo + fade in
  late AnimationController _textoController;
  late Animation<double> _textoOpacity;
  late Animation<double> _textoOffset;

  // Línea separadora
  late AnimationController _lineaController;
  late Animation<double> _lineaAncho;

  // Fade out salida
  late AnimationController _exitController;
  late Animation<double> _exitOpacity;

  bool _isDark = true;

  @override
  void initState() {
    super.initState();
    _cargarTema();

    // Logo
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // Glow
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _glowOpacity =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.6), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0), weight: 70),
        ]).animate(
          CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
        );
    _glowScale = Tween<double>(
      begin: 0.8,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeOut));

    // Línea
    _lineaController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _lineaAncho = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _lineaController, curve: Curves.easeOut));

    // Texto
    _textoController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _textoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textoController, curve: Curves.easeOut));
    _textoOffset = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(parent: _textoController, curve: Curves.easeOutCubic),
    );

    // Exit
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _exitOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));

    _arrancarSecuencia();
  }

  Future<void> _cargarTema() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? true;
    if (mounted) setState(() => _isDark = isDark);
  }

  Future<void> _arrancarSecuencia() async {
    // 1. Logo aparece con escala + fade
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();

    // 2. Destello dorado al completarse
    await Future.delayed(const Duration(milliseconds: 800));
    _glowController.forward();

    // 3. Línea separadora se expande
    await Future.delayed(const Duration(milliseconds: 300));
    _lineaController.forward();

    // 4. Texto sube desde abajo
    await Future.delayed(const Duration(milliseconds: 200));
    _textoController.forward();

    // 5. Esperar y salir con fade
    await Future.delayed(const Duration(milliseconds: 1000));
    _exitController.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    context.go('/');
  }

  @override
  void dispose() {
    _logoController.dispose();
    _glowController.dispose();
    _lineaController.dispose();
    _textoController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appNombre = ref.watch(themeProvider).temaConfig.appNombre;
    final fondo = _isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFFFFFF);
    const dorado = Color(0xFFD4A017);

    return AnimatedBuilder(
      animation: _exitController,
      builder: (context, child) =>
          Opacity(opacity: _exitOpacity.value, child: child),
      child: Scaffold(
        backgroundColor: fondo,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Logo con glow ──────────────────────────
              AnimatedBuilder(
                animation: Listenable.merge([_logoController, _glowController]),
                builder: (context, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Halo dorado — destello
                      Opacity(
                        opacity: _glowOpacity.value,
                        child: Transform.scale(
                          scale: _glowScale.value,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dorado.withOpacity(0.15),
                            ),
                          ),
                        ),
                      ),

                      // Halo interior más brillante
                      Opacity(
                        opacity: _glowOpacity.value * 1.5 > 1
                            ? 1
                            : _glowOpacity.value * 1.5,
                        child: Transform.scale(
                          scale: _glowScale.value * 0.6,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dorado.withOpacity(0.25),
                            ),
                          ),
                        ),
                      ),

                      // Logo
                      Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Image.asset(
                            'assets/splash/logo.png',
                            width: 180,
                            height: 180,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // ── Línea separadora dorada ────────────────
              AnimatedBuilder(
                animation: _lineaController,
                builder: (context, _) => Container(
                  width: 120 * _lineaAncho.value,
                  height: 1,
                  color: dorado.withOpacity(0.5),
                ),
              ),

              const SizedBox(height: 24),

              // ── Texto ──────────────────────────────────
              AnimatedBuilder(
                animation: _textoController,
                builder: (context, _) => Opacity(
                  opacity: _textoOpacity.value,
                  child: Transform.translate(
                    offset: Offset(0, _textoOffset.value),
                    child: Column(
                      children: [
                        Text(
                          appNombre,
                          style: const TextStyle(
                            color: dorado,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'TIENDA 3D · AR',
                          style: TextStyle(
                            color: _isDark
                                ? const Color(0xFF8B6914)
                                : const Color(0xFF6B4A0A),
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

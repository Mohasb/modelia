import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:modelia/shared/models/tema_config.dart';

class ThemeState {
  final ThemeMode themeMode;
  final TemaConfig temaConfig;

  const ThemeState({
    this.themeMode = ThemeMode.light,
    this.temaConfig = const TemaConfig(),
  });

  ThemeState copyWith({ThemeMode? themeMode, TemaConfig? temaConfig}) =>
      ThemeState(
        themeMode: themeMode ?? this.themeMode,
        temaConfig: temaConfig ?? this.temaConfig,
      );
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _cargar();
  }

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('dark_mode') ?? false;
    final temaJson = prefs.getString('tema_config');
    TemaConfig config = const TemaConfig();
    if (temaJson != null) {
      try {
        config = TemaConfig.fromJson(jsonDecode(temaJson));
      } catch (_) {}
    }
    state = ThemeState(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      temaConfig: config,
    );
  }

  Future<void> toggleDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = state.themeMode == ThemeMode.dark;
    await prefs.setBool('dark_mode', !isDark);
    state = state.copyWith(
      themeMode: isDark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  bool get isDark => state.themeMode == ThemeMode.dark;

  Future<void> actualizarColor(String campo, Color color) async {
    TemaConfig nuevo;
    switch (campo) {
      case 'accentColor':
        nuevo = state.temaConfig.copyWith(accentColor: color);
      case 'lightBg':
        nuevo = state.temaConfig.copyWith(lightBg: color);
      case 'lightSurface':
        nuevo = state.temaConfig.copyWith(lightSurface: color);
      case 'lightCard':
        nuevo = state.temaConfig.copyWith(lightCard: color);
      case 'darkBg':
        nuevo = state.temaConfig.copyWith(darkBg: color);
      case 'darkSurface':
        nuevo = state.temaConfig.copyWith(darkSurface: color);
      case 'darkCard':
        nuevo = state.temaConfig.copyWith(darkCard: color);
      case 'textDark':
        nuevo = state.temaConfig.copyWith(textDark: color);
      case 'textLight':
        nuevo = state.temaConfig.copyWith(textLight: color);
      default:
        return;
    }
    state = state.copyWith(temaConfig: nuevo);
    await _guardar();
  }

  Future<void> resetearTema() async {
    state = state.copyWith(temaConfig: const TemaConfig());
    await _guardar();
  }

  Future<void> _guardar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tema_config', jsonEncode(state.temaConfig.toJson()));
  }

  Future<void> aplicarConfig(TemaConfig config) async {
    state = state.copyWith(temaConfig: config);
    await _guardar();
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(),
);

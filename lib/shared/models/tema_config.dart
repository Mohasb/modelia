import 'package:flutter/material.dart';

class TemaConfig {
  final Color accentColor;
  final Color lightBg;
  final Color lightSurface;
  final Color lightCard;
  final Color darkBg;
  final Color darkSurface;
  final Color darkCard;
  final Color textDark;
  final Color textLight;
  final String appNombre;

  const TemaConfig({
    this.accentColor = const Color(0xFFD4A017),
    this.lightBg = const Color(0xFFFFFFFF),
    this.lightSurface = const Color(0xFFF5F5F7),
    this.lightCard = const Color(0xFFF5F5F7),
    this.darkBg = const Color(0xFF0A0A0A),
    this.darkSurface = const Color(0xFF1C1C1E),
    this.darkCard = const Color(0xFF2C2C2E),
    this.textDark = const Color(0xFF1D1D1F),
    this.textLight = const Color(0xFFF5F5F7),
    this.appNombre = "Modelia",
  });

  TemaConfig copyWith({
    Color? accentColor,
    Color? lightBg,
    Color? lightSurface,
    Color? lightCard,
    Color? darkBg,
    Color? darkSurface,
    Color? darkCard,
    Color? textDark,
    Color? textLight,
    String? appNombre,
  }) => TemaConfig(
    accentColor: accentColor ?? this.accentColor,
    lightBg: lightBg ?? this.lightBg,
    lightSurface: lightSurface ?? this.lightSurface,
    lightCard: lightCard ?? this.lightCard,
    darkBg: darkBg ?? this.darkBg,
    darkSurface: darkSurface ?? this.darkSurface,
    darkCard: darkCard ?? this.darkCard,
    textDark: textDark ?? this.textDark,
    textLight: textLight ?? this.textLight,
    appNombre: appNombre ?? this.appNombre,
  );

  Map<String, dynamic> toJson() => {
    'accentColor': accentColor.value,
    'lightBg': lightBg.value,
    'lightSurface': lightSurface.value,
    'lightCard': lightCard.value,
    'darkBg': darkBg.value,
    'darkSurface': darkSurface.value,
    'darkCard': darkCard.value,
    'textDark': textDark.value,
    'textLight': textLight.value,
    'appNombre': appNombre,
  };

  factory TemaConfig.fromJson(Map<String, dynamic> json) => TemaConfig(
    accentColor: Color(json['accentColor'] ?? 0xFFD4A017),
    lightBg: Color(json['lightBg'] ?? 0xFFFFFFFF),
    lightSurface: Color(json['lightSurface'] ?? 0xFFF5F5F7),
    lightCard: Color(json['lightCard'] ?? 0xFFF5F5F7),
    darkBg: Color(json['darkBg'] ?? 0xFF0A0A0A),
    darkSurface: Color(json['darkSurface'] ?? 0xFF1C1C1E),
    darkCard: Color(json['darkCard'] ?? 0xFF2C2C2E),
    textDark: Color(json['textDark'] ?? 0xFF1D1D1F),
    textLight: Color(json['textLight'] ?? 0xFFF5F5F7),
    appNombre: json['appNombre'] ?? 'Modelia',
  );

  // Resetear a valores por defecto
  static const TemaConfig porDefecto = TemaConfig();
}

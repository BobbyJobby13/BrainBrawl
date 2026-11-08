import 'package:flutter/material.dart';

/// Single source of truth for Brain Brawl colours, gradients and spacing.
///
/// The app is a dark "arena" UI: near-black plum background, a pink to violet
/// brand gradient and a cyan accent used sparingly for highlights.
class Palette {
  Palette._();

  // Surfaces
  static const Color background = Color(0xFF0A0711);
  static const Color surface = Color(0xFF15101F);
  static const Color surfaceRaised = Color(0xFF1B1426);
  static const Color border = Color(0x1FFFFFFF);

  // Brand
  static const Color pink = Color(0xFFF5629B);
  static const Color magenta = Color(0xFFE23E8B);
  static const Color violet = Color(0xFF8B5CF6);
  static const Color cyan = Color(0xFF45E5E0);

  // Text
  static const Color textPrimary = Color(0xFFF7F2FB);
  static const Color textSecondary = Color(0xFFA79BB5);
  static const Color textFaint = Color(0xFF7D7189);

  // Feedback
  static const Color success = Color(0xFF54E5A0);
  static const Color danger = Color(0xFFFF7A8A);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [pink, violet],
  );

  static const LinearGradient headlineGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [textPrimary, Color(0xFFFFC2DA), pink],
  );

  /// Accents assigned to teams in the host console, in order.
  static const List<Color> teamAccents = <Color>[
    pink,
    cyan,
    violet,
    Color(0xFFFFC46B),
    Color(0xFF7CE38B),
    Color(0xFFB98BFF),
  ];

  static const double radius = 16;
}

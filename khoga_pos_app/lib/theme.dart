import 'package:flutter/material.dart';

/// Khoga Café brand palette (shared with the HQ web admin design system).
const Color kBrown = Color(0xFF3D2314);
const Color kBrownDark = Color(0xFF1A0F09);
const Color kGold = Color(0xFFC89D7C);
const Color kBg = Color(0xFFFCFAF7);
const Color kBorder = Color(0xFFEADDD3);
const Color kMuted = Color(0xFF8C766C);
const Color kDanger = Color(0xFFB3261E);

final ThemeData khogaTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: kBg,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kBrown,
    primary: kBrown,
    secondary: kGold,
    error: kDanger,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kGold, width: 2),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kBrown,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  ),
);

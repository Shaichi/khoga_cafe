import 'package:flutter/material.dart';

/// Khoga Café brand palette (shared with the HQ web admin design system).
const Color kBrown = Color(0xFF3D2314);
const Color kBrownDark = Color(0xFF1A0F09);
const Color kGold = Color(0xFFC89D7C);
const Color kBg = Colors.white;
const Color kBorder = Color(0xFFEADDD3);
const Color kMuted = Color(0xFF8C766C);
const Color kDanger = Color(0xFFB3261E);
const Color kSuccess = Color(0xFF2E7D32);
const Color kWarning = Color(0xFFF57F17);
const Color kBgAlt = Color(0xFFFAF6F0);

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
    fillColor: const Color(0xFFFAFAFA),
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kGold, width: 2),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kBrown,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(50),
      elevation: 0,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
);

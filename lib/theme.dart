import 'package:flutter/material.dart';

// BullDozer site palette (src/styles/global.css)
const kBg = Color(0xFF0E0F11);
const kBgElev = Color(0xFF16181B);
const kBgCard = Color(0xFF1C1F23);
const kBorder = Color(0xFF2A2E33);
const kText = Color(0xFFE7E9EC);
const kTextDim = Color(0xFF9AA1A9);
const kAmber = Color(0xFFFFB000);
const kOrange = Color(0xFFFF7A00);
const kUp = Color(0xFF34D399);
const kDown = Color(0xFFF87171);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: kBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kAmber,
      brightness: Brightness.dark,
      surface: kBg,
      primary: kAmber,
    ),
  );
  return base.copyWith(
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kBgElev,
      indicatorColor: kAmber.withValues(alpha: 0.18),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? kAmber : kTextDim)),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected) ? kAmber : kTextDim)),
    ),
    cardTheme: const CardThemeData(
      color: kBgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: kBorder, width: 0.5),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: kBgCard,
      selectedColor: kAmber,
      side: const BorderSide(color: kBorder, width: 0.5),
      labelStyle: const TextStyle(fontSize: 12, color: kText),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kBgElev,
      foregroundColor: kText,
      elevation: 0,
    ),
    textTheme: base.textTheme.apply(bodyColor: kText, displayColor: kText),
  );
}

const pageTitleStyle = TextStyle(
    fontSize: 24, fontWeight: FontWeight.w700, color: kText, letterSpacing: -0.5);

// Shared brand elements (same amber "B" mark + two-tone wordmark as the icon).
Widget brandMark(double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kAmber, kOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      alignment: Alignment.center,
      child: Text('B',
          style: TextStyle(
              fontSize: size * 0.65,
              fontWeight: FontWeight.w900,
              height: 1.0,
              color: const Color(0xFF1A1300))),
    );

const brandWordmark = Text.rich(
  TextSpan(children: [
    TextSpan(
        text: 'Bull',
        style: TextStyle(color: kText, fontWeight: FontWeight.w800)),
    TextSpan(
        text: 'Dozer',
        style: TextStyle(color: kAmber, fontWeight: FontWeight.w800)),
  ]),
  style: TextStyle(fontSize: 25, letterSpacing: -0.5),
);

const brandTagline = Text.rich(
  TextSpan(children: [
    TextSpan(text: 'Bulldoze the noise. ', style: TextStyle(color: kText)),
    TextSpan(text: 'Mine the signal.', style: TextStyle(color: kAmber)),
  ]),
  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
);

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Light/dark theme, same palettes as the site (src/styles/global.css and its
/// html[data-theme='light'] block). Toggled by the sun button (header + menu),
/// persisted on disk. The k-colors are getters so every rebuild picks up the
/// active palette — the app root listens to [themeNotifier].
final themeNotifier = ValueNotifier<bool>(false); // true = light

bool get isLight => themeNotifier.value;

// BullDozer site palette (dark / light)
Color get kBg => isLight ? const Color(0xFFF7F6F2) : const Color(0xFF0E0F11);
Color get kBgElev => isLight ? const Color(0xFFEEECE6) : const Color(0xFF16181B);
Color get kBgCard => isLight ? const Color(0xFFFFFFFF) : const Color(0xFF1C1F23);
Color get kBorder => isLight ? const Color(0xFFDCD8CF) : const Color(0xFF2A2E33);
Color get kText => isLight ? const Color(0xFF1D1F23) : const Color(0xFFE7E9EC);
Color get kTextDim => isLight ? const Color(0xFF5F6670) : const Color(0xFF9AA1A9);
Color get kAmber => isLight ? const Color(0xFFC07F00) : const Color(0xFFFFB000);
Color get kOrange => isLight ? const Color(0xFFD95F00) : const Color(0xFFFF7A00);
Color get kUp => isLight ? const Color(0xFF0E8A5F) : const Color(0xFF34D399);
Color get kDown => isLight ? const Color(0xFFD43D3D) : const Color(0xFFF87171);

Future<File?> _themeFile() async {
  if (kIsWeb) return null;
  try {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/bd_theme.json');
  } catch (_) {
    return null;
  }
}

Future<void> loadTheme() async {
  final f = await _themeFile();
  if (f == null || !await f.exists()) return;
  try {
    themeNotifier.value = jsonDecode(await f.readAsString()) == 'light';
  } catch (_) {}
}

void toggleTheme() {
  themeNotifier.value = !themeNotifier.value;
  _themeFile().then((f) =>
      f?.writeAsString(jsonEncode(isLight ? 'light' : 'dark')).ignore());
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: isLight ? Brightness.light : Brightness.dark,
    scaffoldBackgroundColor: kBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kAmber,
      brightness: isLight ? Brightness.light : Brightness.dark,
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
    cardTheme: CardThemeData(
      color: kBgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: kBorder, width: 0.5),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: kBgCard,
      selectedColor: kAmber,
      side: BorderSide(color: kBorder, width: 0.5),
      labelStyle: TextStyle(fontSize: 12, color: kText),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: kBgElev,
      foregroundColor: kText,
      elevation: 0,
    ),
    textTheme: base.textTheme.apply(bodyColor: kText, displayColor: kText),
  );
}

TextStyle get pageTitleStyle => TextStyle(
    fontSize: 24, fontWeight: FontWeight.w700, color: kText, letterSpacing: -0.5);

// Shared brand elements (same amber "B" mark + two-tone wordmark as the icon).
Widget brandMark(double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
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

Widget get brandWordmark => Text.rich(
      TextSpan(children: [
        TextSpan(
            text: 'Bull',
            style: TextStyle(color: kText, fontWeight: FontWeight.w800)),
        TextSpan(
            text: 'Dozer',
            style: TextStyle(color: kAmber, fontWeight: FontWeight.w800)),
      ]),
      style: const TextStyle(fontSize: 25, letterSpacing: -0.5),
    );

Widget get brandTagline => Text.rich(
      TextSpan(children: [
        TextSpan(text: 'Bulldoze the noise. ', style: TextStyle(color: kText)),
        TextSpan(text: 'Mine the signal.', style: TextStyle(color: kAmber)),
      ]),
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    );

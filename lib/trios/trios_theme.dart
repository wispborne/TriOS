import 'package:flutter/material.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:google_fonts/google_fonts.dart';

import '../trios/app_state.dart';

const Color vanillaErrorColor = Color.fromARGB(255, 252, 99, 0);
const Color vanillaWarningColor = Color.fromARGB(255, 253, 212, 24);

class TriOSTheme with ChangeNotifier {
  static double cornerRadius = 8;

  static bool _isDark = true;
  static bool _isMaterial3 = false;
  static const String _key = "currentTheme";
  static const String _keyMaterial = "isMaterial";

  // static final backgroundShader = FutureProvider<FragmentProgram>((ref) async {
  //   return FragmentProgram.fromAsset("assets/shaders/grain.frag");
  // });

  TriOSTheme() {
    if (sharedPrefs.containsKey(_key)) {
      _isDark = sharedPrefs.getBool(_key) ?? true;
      _isMaterial3 = sharedPrefs.getBool(_keyMaterial) ?? false;
    }
  }

  ThemeMode currentTheme() {
    return _isDark ? ThemeMode.dark : ThemeMode.light;
  }

  bool isMaterial3() {
    return _isMaterial3;
  }

  void switchThemes(BuildContext context) {
    _isDark = !_isDark;
    sharedPrefs.setBool(_key, _isDark);
    // AdaptiveTheme.of(context).setThemeMode(_isDark ? AdaptiveThemeMode.dark : AdaptiveThemeMode.light);
    print("Changed theme. Dark: $_isDark");
    notifyListeners();
  }

  void switchMaterial() {
    _isMaterial3 = !_isMaterial3;
    sharedPrefs.setBool(_keyMaterial, _isMaterial3);
    print("Changed material. Material: $_isMaterial3");
    notifyListeners();
  }

  static ThemeData getDarkTheme(Swatch swatch, bool material3) {
    final seedColor = swatch.primary;

    var darkThemeBase = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark), useMaterial3: material3);

    return customizeTheme(darkThemeBase, swatch).copyWith();
  }

  static ThemeData getLightTheme(Swatch swatch, bool material3) {
    final seedColor = swatch.primary;

    var lightThemeBase = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light),
      useMaterial3: material3,
    );

    return customizeTheme(
        lightThemeBase,
        swatch
          ..background = lightThemeBase.colorScheme.onInverseSurface
          ..card = lightThemeBase.colorScheme.onInverseSurface)
        .copyWith(
        colorScheme: lightThemeBase.colorScheme
            .copyWith(primary: swatch.primary, secondary: swatch.secondary, tertiary: swatch.tertiary),
        textTheme: lightThemeBase.textTheme
            .copyWith(bodyMedium: lightThemeBase.textTheme.bodyMedium?.copyWith(fontSize: 16)),
        iconTheme: lightThemeBase.iconTheme.copyWith(color: lightThemeBase.colorScheme.onSurface),
        tabBarTheme: lightThemeBase.tabBarTheme.copyWith(
            labelColor: lightThemeBase.colorScheme.onSurface,
            unselectedLabelColor: lightThemeBase.colorScheme.onSurface),
        snackBarTheme: const SnackBarThemeData());
  }

  static ThemeData customizeTheme(ThemeData themeBase, Swatch swatch) {
    // Choose font here
    final textTheme = GoogleFonts.ibmPlexSansTextTheme(themeBase.textTheme);

    return themeBase.copyWith(
        colorScheme: themeBase.colorScheme.copyWith(
          primary: swatch.primary,
          secondary: swatch.secondary,
          tertiary: swatch.tertiary,
        ),
        scaffoldBackgroundColor: swatch.background,
        dialogBackgroundColor: swatch.background,
        cardColor: swatch.card,
        cardTheme: themeBase.cardTheme.copyWith(color: swatch.card, elevation: 4, surfaceTintColor: Colors.transparent),
        appBarTheme: themeBase.appBarTheme.copyWith(backgroundColor: swatch.card),
        floatingActionButtonTheme: themeBase.floatingActionButtonTheme
            .copyWith(backgroundColor: swatch.primary, foregroundColor: themeBase.colorScheme.surface),
        checkboxTheme: themeBase.checkboxTheme.copyWith(checkColor: MaterialStateProperty.all(Colors.transparent)),
        textTheme: textTheme.copyWith(bodyMedium: textTheme.bodyMedium?.copyWith(fontSize: 16)));
  }
}

enum SnackBarType {
  info,
  warn,
  error,
}

showSnackBar({
  required BuildContext context,
  required Widget content,
  bool? clearPreviousSnackBars = true,
  SnackBarType? type,
  Color? backgroundColor,
  double? elevation,
  EdgeInsetsGeometry? margin,
  EdgeInsetsGeometry? padding,
  double? width,
  ShapeBorder? shape,
  HitTestBehavior? hitTestBehavior,
  SnackBarBehavior? behavior,
  SnackBarAction? action,
  double? actionOverflowThreshold,
  bool? showCloseIcon,
  Color? closeIconColor,
  Duration duration = const Duration(milliseconds: 4000),
  Animation<double>? animation,
  void Function()? onVisible,
  DismissDirection? dismissDirection,
  Clip clipBehavior = Clip.hardEdge,
}) {
  if (clearPreviousSnackBars == true) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: type != null
        ? DefaultTextStyle.merge(
        child: content, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
        : content,
    backgroundColor: switch (type) {
      SnackBarType.info => Colors.blue,
      SnackBarType.warn => vanillaWarningColor,
      SnackBarType.error => vanillaErrorColor,
      null =>
      Theme
          .of(context)
          .snackBarTheme
          .backgroundColor
    },
    elevation: elevation,
    margin: margin,
    padding: padding,
    width: width,
    shape: shape,
    hitTestBehavior: hitTestBehavior,
    behavior: behavior,
    action: action,
    actionOverflowThreshold: actionOverflowThreshold,
    showCloseIcon: showCloseIcon,
    closeIconColor: closeIconColor,
    duration: duration,
    animation: animation,
    onVisible: onVisible,
    dismissDirection: dismissDirection,
    clipBehavior: clipBehavior,
  ));
}

/// For use with ColorFiltered
const ColorFilter greyscale = ColorFilter.matrix(<double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

class Swatch {
  Color primary;
  Color secondary;
  Color tertiary;
  Color background;
  Color card;

  Swatch(this.primary, this.secondary, this.tertiary, this.background, this.card);
}

class StarsectorSwatch extends Swatch {
  StarsectorSwatch()
      : super(
    const Color.fromRGBO(73, 252, 255, 1),
    const Color.fromRGBO(59, 203, 232, 1),
    const Color.fromRGBO(0, 255, 255, 1),
    const Color.fromRGBO(14, 22, 43, 1),
    const Color.fromRGBO(32, 41, 65, 1.0),
  );
}

class HalloweenSwatch extends Swatch {
  HalloweenSwatch()
      : super(
    HexColor("#FF0000"),
    HexColor("#FF4D00").lighter(10),
    HexColor("#FF4D00").lighter(20),
    HexColor("#272121"),
    HexColor("#272121").lighter(3),
  );
}

class XmasSwatch extends Swatch {
  XmasSwatch()
      : super(
    HexColor("#f23942").darker(10),
    HexColor("#70BA7F").lighter(10),
    HexColor("#b47c4b").lighter(30),
    const Color.fromRGBO(26, 46, 31, 1.0).darker(5),
    HexColor("#171e13").lighter(8),
  );
}

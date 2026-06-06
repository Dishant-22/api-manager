import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => FlexThemeData.light(
        scheme: FlexScheme.deepBlue,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 9,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          useM2StyleDividerInM3: true,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
          tabBarIndicatorSize: TabBarIndicatorSize.tab,
          tabBarIndicatorWeight: 2.5,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          inputDecoratorRadius: 8.0,
          inputDecoratorUnfocusedBorderIsColored: false,
          elevatedButtonRadius: 8.0,
          filledButtonRadius: 8.0,
          outlinedButtonRadius: 8.0,
          textButtonRadius: 8.0,
          cardRadius: 8.0,
          dialogRadius: 12.0,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        fontFamily: 'Roboto',
      );

  static ThemeData get darkTheme => FlexThemeData.dark(
        scheme: FlexScheme.deepBlue,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 15,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 20,
          useM2StyleDividerInM3: true,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
          tabBarIndicatorSize: TabBarIndicatorSize.tab,
          tabBarIndicatorWeight: 2.5,
          inputDecoratorBorderType: FlexInputBorderType.outline,
          inputDecoratorRadius: 8.0,
          inputDecoratorUnfocusedBorderIsColored: false,
          elevatedButtonRadius: 8.0,
          filledButtonRadius: 8.0,
          outlinedButtonRadius: 8.0,
          textButtonRadius: 8.0,
          cardRadius: 8.0,
          dialogRadius: 12.0,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        fontFamily: 'Roboto',
      );

  static const TextStyle monoStyle = TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 13,
    height: 1.5,
  );

  static TextStyle monoStyleWith({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) =>
      monoStyle.copyWith(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      );
}

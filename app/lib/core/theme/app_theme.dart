import 'package:flutter/material.dart';
import '../config/app_config.dart';
import 'app_tokens.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData get light => _build(
    ColorScheme.fromSeed(
      seedColor: AppConfig.primaryColor,
      primary: AppConfig.primaryColor,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFE6E8FF),
      onPrimaryContainer: const Color(0xFF1E1B4B),
      secondary: AppConfig.secondaryColor,
      onSecondary: const Color(0xFF1F1300),
      secondaryContainer: const Color(0xFFFEF3C7),
      onSecondaryContainer: const Color(0xFF78350F),
      tertiary: AppColors.success,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: const Color(0xFFFEE2E2),
      onErrorContainer: const Color(0xFF7F1D1D),
      surface: Colors.white,
      onSurface: const Color(0xFF111827),
      onSurfaceVariant: const Color(0xFF6B7280),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF8F9FC),
      surfaceContainer: const Color(0xFFF2F3F8),
      surfaceContainerHigh: const Color(0xFFEDEEF5),
      surfaceContainerHighest: const Color(0xFFE8EAF2),
      outline: const Color(0xFFD1D5E0),
      outlineVariant: const Color(0xFFE7E9F0),
    ),
    background: AppConfig.lightBackground,
  );

  static ThemeData get dark => _build(
    ColorScheme.fromSeed(
      seedColor: AppConfig.primaryColor,
      brightness: Brightness.dark,
      primary: Color.lerp(AppConfig.primaryColor, Colors.white, 0.3),
      onPrimary: Colors.white,
      primaryContainer: Color.lerp(
        AppConfig.primaryColor,
        AppConfig.darkBackground,
        0.45,
      ),
      onPrimaryContainer: const Color(0xFFE0E7FF),
      secondary: const Color(0xFFFBBF24),
      onSecondary: const Color(0xFF1F1300),
      secondaryContainer: const Color(0xFF3B2A0A),
      onSecondaryContainer: const Color(0xFFFDE68A),
      tertiary: const Color(0xFF22C55E),
      onTertiary: const Color(0xFF052E16),
      error: const Color(0xFFF87171),
      onError: const Color(0xFF450A0A),
      errorContainer: const Color(0xFF3F1518),
      onErrorContainer: const Color(0xFFFECACA),
      surface: const Color(0xFF171B30),
      onSurface: const Color(0xFFE8EAF6),
      onSurfaceVariant: const Color(0xFFA3A8C3),
      surfaceContainerLowest: const Color(0xFF12152A),
      surfaceContainerLow: const Color(0xFF161A2E),
      surfaceContainer: const Color(0xFF1B1F36),
      surfaceContainerHigh: const Color(0xFF21263F),
      surfaceContainerHighest: const Color(0xFF282D48),
      outline: const Color(0xFF3A3F5C),
      outlineVariant: const Color(0xFF2A2F4A),
    ),
    background: AppConfig.darkBackground,
  );

  static ThemeData _build(ColorScheme colors, {required Color background}) {
    final isLight = colors.brightness == Brightness.light;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      fontFamily: AppConfig.fontFamily,
    );
    final text = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
    const field = BorderRadius.all(Radius.circular(AppRadii.md));
    const buttonShape = RoundedRectangleBorder(borderRadius: field);
    const buttonSize = Size(64, 52);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: colors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: colors.onSurface),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        color: isLight ? colors.surface : colors.surfaceContainer,
        elevation: isLight ? 3 : 0,
        shadowColor: colors.primary.withValues(alpha: 0.10),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.lg)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? colors.surface : colors.surfaceContainerHigh,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: const OutlineInputBorder(
          borderRadius: field,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: field,
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: field,
          borderSide: BorderSide(color: colors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: field,
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: field,
          borderSide: BorderSide(color: colors.error, width: 1.6),
        ),
        prefixIconColor: colors.onSurfaceVariant,
        suffixIconColor: colors.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          side: BorderSide(color: colors.outline),
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: text.labelLarge),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide.none,
        backgroundColor: colors.surfaceContainerHigh,
        labelStyle: text.labelLarge?.copyWith(color: colors.onSurface),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.sm)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        elevation: 0,
        backgroundColor: isLight ? colors.surface : colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colors.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.primary
                : colors.onSurfaceVariant,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceContainerHighest,
        linearMinHeight: 6,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: colors.primary,
        unselectedLabelColor: colors.onSurfaceVariant,
        labelStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: text.titleSmall,
        indicator: BoxDecoration(
          color: isLight ? colors.surface : colors.surfaceContainerHighest,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadii.sm)),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: colors.primaryContainer,
          selectedForegroundColor: colors.onPrimaryContainer,
          side: BorderSide(color: colors.outlineVariant),
          textStyle: text.labelLarge,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.onSurfaceVariant,
        titleTextStyle: text.titleSmall?.copyWith(color: colors.onSurface),
        subtitleTextStyle: text.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadii.xl)),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../widgets/context_matrix_theme.dart';

class HunkTheme {
  const HunkTheme._();

  static ThemeData dark() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: ContextMatrixStyle.electricBlue,
          brightness: Brightness.dark,
        ).copyWith(
          primary: ContextMatrixStyle.electricBlue,
          onPrimary: const Color(0xFF03101F),
          primaryContainer: const Color(0xFF0B304D),
          onPrimaryContainer: ContextMatrixStyle.text,
          secondary: ContextMatrixStyle.violet,
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xFF251B45),
          onSecondaryContainer: ContextMatrixStyle.text,
          tertiary: ContextMatrixStyle.teal,
          onTertiary: const Color(0xFF031915),
          surface: ContextMatrixStyle.background,
          onSurface: ContextMatrixStyle.text,
          surfaceContainerLow: const Color(0xFF081120),
          surfaceContainer: const Color(0xFF0B1324),
          surfaceContainerHigh: const Color(0xFF111A2D),
          surfaceContainerHighest: const Color(0xFF141B2F),
          onSurfaceVariant: ContextMatrixStyle.mutedText,
          outline: ContextMatrixStyle.border,
          outlineVariant: ContextMatrixStyle.border.withValues(alpha: 0.72),
          error: ContextMatrixStyle.danger,
          errorContainer: const Color(0xFF3B1420),
          onErrorContainer: const Color(0xFFFFDCE4),
        );

    final base = ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ContextMatrixStyle.background,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
    );

    final textTheme = base.textTheme.apply(
      bodyColor: ContextMatrixStyle.text,
      displayColor: ContextMatrixStyle.text,
    );

    return base.copyWith(
      textTheme: textTheme.copyWith(
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ContextMatrixStyle.background.withValues(alpha: 0.96),
        foregroundColor: ContextMatrixStyle.text,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: ContextMatrixStyle.text,
          fontWeight: FontWeight.w800,
        ),
        shape: Border(
          bottom: BorderSide(
            color: ContextMatrixStyle.border.withValues(alpha: 0.65),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: ContextMatrixStyle.panel.withValues(alpha: 0.96),
        indicatorColor: ContextMatrixStyle.electricBlue.withValues(alpha: 0.18),
        shadowColor: ContextMatrixStyle.electricBlue.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? ContextMatrixStyle.electricBlue
                : ContextMatrixStyle.mutedText,
            size: selected ? 25 : 23,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected
                ? ContextMatrixStyle.text
                : ContextMatrixStyle.mutedText,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ContextMatrixStyle.panel2.withValues(alpha: 0.74),
        labelStyle: const TextStyle(color: ContextMatrixStyle.mutedText),
        helperStyle: TextStyle(
          color: ContextMatrixStyle.mutedText.withValues(alpha: 0.82),
        ),
        hintStyle: TextStyle(
          color: ContextMatrixStyle.mutedText.withValues(alpha: 0.72),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ContextMatrixStyle.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: ContextMatrixStyle.border.withValues(alpha: 0.82),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: ContextMatrixStyle.electricBlue,
            width: 1.4,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ContextMatrixStyle.electricBlue,
          foregroundColor: const Color(0xFF03101F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ContextMatrixStyle.text,
          side: BorderSide(
            color: ContextMatrixStyle.border.withValues(alpha: 0.9),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: ContextMatrixStyle.text,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: ContextMatrixStyle.panel2.withValues(alpha: 0.72),
          foregroundColor: ContextMatrixStyle.mutedText,
          selectedBackgroundColor: ContextMatrixStyle.electricBlue.withValues(
            alpha: 0.18,
          ),
          selectedForegroundColor: ContextMatrixStyle.text,
          side: BorderSide(
            color: ContextMatrixStyle.border.withValues(alpha: 0.82),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: ContextMatrixStyle.panel2.withValues(alpha: 0.74),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ContextMatrixStyle.panel2,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: ContextMatrixStyle.text,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ContextMatrixStyle.electricBlue,
        linearTrackColor: ContextMatrixStyle.border,
      ),
      dividerTheme: DividerThemeData(
        color: ContextMatrixStyle.border.withValues(alpha: 0.72),
      ),
    );
  }
}

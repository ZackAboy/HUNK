import 'package:flutter/material.dart';

import '../models/context_entry.dart';

class ContextMatrixStyle {
  const ContextMatrixStyle._();

  static const background = Color(0xFF050915);
  static const background2 = Color(0xFF081120);
  static const panel = Color(0xE60B1324);
  static const panel2 = Color(0xF0141B2F);
  static const border = Color(0xFF23314D);
  static const text = Color(0xFFF3F7FF);
  static const mutedText = Color(0xFF96A7C4);
  static const electricBlue = Color(0xFF38BDF8);
  static const cyan = Color(0xFF22D3EE);
  static const teal = Color(0xFF2DD4BF);
  static const violet = Color(0xFF8B5CF6);
  static const purple = Color(0xFFA855F7);
  static const magenta = Color(0xFFE879F9);
  static const indigo = Color(0xFF6366F1);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFFB7185);
  static const success = Color(0xFF34D399);
  static const slate = Color(0xFF64748B);

  static LinearGradient get screenGradient {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [background, Color(0xFF071A2B), Color(0xFF101025)],
    );
  }

  static Color sectionColor(ContextSection section) {
    return switch (section) {
      ContextSection.profile => cyan,
      ContextSection.goals => violet,
      ContextSection.preferences => magenta,
      ContextSection.equipmentAccess => electricBlue,
      ContextSection.healthConstraints => purple,
      ContextSection.currentState => teal,
      ContextSection.trainingHistory => indigo,
      ContextSection.nutritionContext => Color(0xFF67E8F9),
      ContextSection.environment => Color(0xFF5EEAD4),
      ContextSection.personalityMatrix => Color(0xFFC084FC),
      ContextSection.otherNotes => Color(0xFF94A3B8),
    };
  }

  static Color sourceColor(ContextSource source) {
    return switch (source) {
      ContextSource.manual => cyan,
      ContextSource.chatExtracted => purple,
      ContextSource.userConfirmed => success,
      ContextSource.futureHealthImport => success,
      ContextSource.futureWeatherImport => teal,
      ContextSource.systemDefault => slate,
    };
  }

  static IconData sectionIcon(ContextSection section) {
    return switch (section) {
      ContextSection.profile => Icons.person_outline,
      ContextSection.goals => Icons.flag_outlined,
      ContextSection.preferences => Icons.tune_outlined,
      ContextSection.equipmentAccess => Icons.fitness_center_outlined,
      ContextSection.healthConstraints => Icons.health_and_safety_outlined,
      ContextSection.currentState => Icons.battery_5_bar_outlined,
      ContextSection.trainingHistory => Icons.history_outlined,
      ContextSection.nutritionContext => Icons.restaurant_outlined,
      ContextSection.environment => Icons.wb_sunny_outlined,
      ContextSection.personalityMatrix => Icons.psychology_outlined,
      ContextSection.otherNotes => Icons.notes_outlined,
    };
  }

  static String shortSectionLabel(ContextSection section) {
    return switch (section) {
      ContextSection.profile => 'Body',
      ContextSection.goals => 'Goals',
      ContextSection.preferences => 'Prefs',
      ContextSection.equipmentAccess => 'Equipment',
      ContextSection.healthConstraints => 'Health',
      ContextSection.currentState => 'Today',
      ContextSection.trainingHistory => 'Training',
      ContextSection.nutritionContext => 'Nutrition',
      ContextSection.environment => 'Env',
      ContextSection.personalityMatrix => 'Personality',
      ContextSection.otherNotes => 'Memory',
    };
  }

  static BoxDecoration panelDecoration({Color? accent}) {
    final line = accent ?? border;
    return BoxDecoration(
      color: panel,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: line.withValues(alpha: 0.46)),
      boxShadow: [
        BoxShadow(
          color: line.withValues(alpha: 0.16),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }
}

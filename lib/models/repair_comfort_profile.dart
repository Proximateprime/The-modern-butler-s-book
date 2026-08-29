/// Explicit repair-step comfort. Not a skill score and never inferred silently.
enum RepairComfortLevel {
  moreDetail,
  standard,
  shorter,
}

extension RepairComfortLevelLabel on RepairComfortLevel {
  String get label => switch (this) {
    RepairComfortLevel.moreDetail => 'More detail',
    RepairComfortLevel.standard => 'Standard',
    RepairComfortLevel.shorter => 'Shorter steps',
  };
}

/// Household-chosen step detail per appliance domain.
class RepairComfortProfile {
  const RepairComfortProfile({
    this.learnPreferences = false,
    this.levels = const {},
  });

  static const List<String> domains = [
    'dryer',
    'washer',
    'fridge',
    'dishwasher',
  ];

  /// Off by default. When on, the app may *ask* after Fixed — never auto-change.
  final bool learnPreferences;
  final Map<String, RepairComfortLevel> levels;

  RepairComfortLevel levelFor(String category) {
    return levels[category] ?? RepairComfortLevel.standard;
  }

  RepairComfortProfile withLevel(String category, RepairComfortLevel level) {
    return RepairComfortProfile(
      learnPreferences: learnPreferences,
      levels: {...levels, category: level},
    );
  }

  RepairComfortProfile withLearnPreferences(bool enabled) {
    return RepairComfortProfile(
      learnPreferences: enabled,
      levels: levels,
    );
  }

  bool shouldAskToShorten(String category) {
    return learnPreferences &&
        levelFor(category) != RepairComfortLevel.shorter;
  }

  Map<String, dynamic> toJson() {
    return {
      'learnPreferences': learnPreferences,
      'levels': {
        for (final entry in levels.entries) entry.key: entry.value.name,
      },
    };
  }

  factory RepairComfortProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const RepairComfortProfile();
    }
    final rawLevels = json['levels'] as Map? ?? const {};
    return RepairComfortProfile(
      learnPreferences: json['learnPreferences'] as bool? ?? false,
      levels: {
        for (final entry in rawLevels.entries)
          entry.key.toString(): _parseLevel(entry.value),
      },
    );
  }

  static RepairComfortLevel _parseLevel(Object? raw) {
    final name = raw?.toString();
    for (final level in RepairComfortLevel.values) {
      if (level.name == name) {
        return level;
      }
    }
    return RepairComfortLevel.standard;
  }
}

/// Display-only: which parts of a Safe Guidance step to show.
class ComfortStepVisibility {
  const ComfortStepVisibility({
    required this.showFullStep,
    required this.showResultMeans,
    required this.showWhenToStop,
  });

  final bool showFullStep;
  final bool showResultMeans;
  final bool showWhenToStop;
}

ComfortStepVisibility comfortStepVisibility({
  required RepairComfortLevel level,
  required String step,
}) {
  final lower = step.toLowerCase();
  final safetyCritical =
      lower.contains('unplug') ||
      lower.contains('do not') ||
      lower.contains('never ') ||
      lower.contains('breaker') ||
      lower.contains('stop') ||
      lower.contains('call a professional') ||
      lower.contains('call a qualified');
  return switch (level) {
    RepairComfortLevel.standard => const ComfortStepVisibility(
      showFullStep: true,
      showResultMeans: false,
      showWhenToStop: false,
    ),
    RepairComfortLevel.moreDetail => const ComfortStepVisibility(
      showFullStep: true,
      showResultMeans: true,
      showWhenToStop: true,
    ),
    RepairComfortLevel.shorter => ComfortStepVisibility(
      showFullStep: safetyCritical,
      showResultMeans: false,
      showWhenToStop: safetyCritical,
    ),
  };
}

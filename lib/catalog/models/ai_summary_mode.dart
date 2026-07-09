import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';

part 'ai_summary_mode.mapper.dart';

/// Preference for showing AI-written mod summaries on catalog cards.
///
/// AI summaries come from the forum bundle's `llm` data. Author-written text
/// (the scraped summary/description) is always preferred unless the user picks
/// [always].
@MappableEnum(defaultValue: AiSummaryMode.whenNoAuthorText)
enum AiSummaryMode {
  /// Prefer the AI sentence over scraped text whenever it exists.
  always,

  /// Keep author text when it exists; use the AI sentence only to fill cards
  /// that would otherwise have no description.
  whenNoAuthorText,

  /// Never show AI text — today's behavior.
  never,
}

extension AiSummaryModeDisplay on AiSummaryMode {
  String get label => switch (this) {
    AiSummaryMode.always => 'Always',
    AiSummaryMode.whenNoAuthorText => 'Only if missing',
    AiSummaryMode.never => 'Never',
  };

  IconData get icon => switch (this) {
    AiSummaryMode.always => Icons.auto_awesome,
    AiSummaryMode.whenNoAuthorText => Icons.auto_fix_high,
    AiSummaryMode.never => Icons.block,
  };
}

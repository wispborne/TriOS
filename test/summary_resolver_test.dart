import 'package:flutter_test/flutter_test.dart';
import 'package:trios/catalog/models/ai_summary_mode.dart';
import 'package:trios/catalog/models/mod_repo_entry.dart';
import 'package:trios/catalog/models/catalog_mod.dart';
import 'package:trios/catalog/summary_resolver.dart';

CatalogMod _make({
  String? summaryText,
  String? descriptionText,
  String? modInfoText,
  String? aiSentence,
  String? aiParagraph,
}) =>
    CatalogMod(
      entry: ModRepoEntry(name: 'Test'),
      title: 'Test',
      authors: 'Author',
      summaryText: summaryText,
      descriptionText: descriptionText,
      modInfoText: modInfoText,
      aiSentence: aiSentence,
      aiParagraph: aiParagraph,
    );

void main() {
  group('resolveSummaryText', () {
    test('always mode returns AI text when available', () {
      final mod = _make(
        summaryText: 'Author summary',
        aiSentence: 'AI sentence',
      );

      final result = resolveSummaryText(
        mod,
        aiMode: AiSummaryMode.always,
        aiLength: AiTextLength.sentence,
        authorOrder: AuthorTextOrder.shortFirst,
      );

      expect(result?.text, 'AI sentence');
      expect(result?.source, ModSummarySource.ai);
    });

    test('always mode falls back to author text when no AI', () {
      final mod = _make(summaryText: 'Author summary');

      final result = resolveSummaryText(
        mod,
        aiMode: AiSummaryMode.always,
        aiLength: AiTextLength.sentence,
        authorOrder: AuthorTextOrder.shortFirst,
      );

      expect(result?.text, 'Author summary');
      expect(result?.source, ModSummarySource.modIndex);
    });

    test('whenNoAuthorText returns author text when present', () {
      final mod = _make(
        summaryText: 'Author summary',
        aiSentence: 'AI sentence',
      );

      final result = resolveSummaryText(
        mod,
        aiMode: AiSummaryMode.whenNoAuthorText,
        aiLength: AiTextLength.sentence,
        authorOrder: AuthorTextOrder.shortFirst,
      );

      expect(result?.text, 'Author summary');
      expect(result?.source, ModSummarySource.modIndex);
    });

    test('whenNoAuthorText returns AI text when no author text', () {
      final mod = _make(aiSentence: 'AI sentence');

      final result = resolveSummaryText(
        mod,
        aiMode: AiSummaryMode.whenNoAuthorText,
        aiLength: AiTextLength.sentence,
        authorOrder: AuthorTextOrder.shortFirst,
      );

      expect(result?.text, 'AI sentence');
      expect(result?.source, ModSummarySource.ai);
    });

    test('never mode returns only author text', () {
      final mod = _make(
        summaryText: 'Author summary',
        aiSentence: 'AI sentence',
      );

      final result = resolveSummaryText(
        mod,
        aiMode: AiSummaryMode.never,
        aiLength: AiTextLength.sentence,
        authorOrder: AuthorTextOrder.shortFirst,
      );

      expect(result?.text, 'Author summary');
      expect(result?.source, ModSummarySource.modIndex);
    });

    test('never mode returns null when no author text exists', () {
      final mod = _make(aiSentence: 'AI sentence');

      final result = resolveSummaryText(
        mod,
        aiMode: AiSummaryMode.never,
        aiLength: AiTextLength.sentence,
        authorOrder: AuthorTextOrder.shortFirst,
      );

      expect(result, isNull);
    });

    test('shortFirst order tries summary then description', () {
      final mod = _make(
        descriptionText: 'Description',
      );

      final result = resolveSummaryText(
        mod,
        aiMode: AiSummaryMode.never,
        aiLength: AiTextLength.sentence,
        authorOrder: AuthorTextOrder.shortFirst,
      );

      expect(result?.text, 'Description');
    });

    test('longFirst order tries description then summary', () {
      final mod = _make(
        summaryText: 'Summary',
        descriptionText: 'Description',
      );

      final result = resolveSummaryText(
        mod,
        aiMode: AiSummaryMode.never,
        aiLength: AiTextLength.sentence,
        authorOrder: AuthorTextOrder.longFirst,
      );

      expect(result?.text, 'Description');
    });

    test('mod_info text is credited to the mod_info file', () {
      final mod = _make(modInfoText: 'From mod_info.json');

      final result = resolveSummaryText(
        mod,
        aiMode: AiSummaryMode.never,
        aiLength: AiTextLength.sentence,
        authorOrder: AuthorTextOrder.shortFirst,
      );

      expect(result?.text, 'From mod_info.json');
      expect(result?.source, ModSummarySource.modInfoFile);
    });

    test('paragraph AI length uses paragraph', () {
      final mod = _make(
        aiSentence: 'AI sentence',
        aiParagraph: 'AI paragraph',
      );

      final result = resolveSummaryText(
        mod,
        aiMode: AiSummaryMode.always,
        aiLength: AiTextLength.paragraph,
        authorOrder: AuthorTextOrder.shortFirst,
      );

      expect(result?.text, 'AI paragraph');
    });
  });

  group('resolveAuthorText', () {
    test('returns author text in short-first order', () {
      final mod = _make(
        summaryText: 'Summary',
        descriptionText: 'Description',
      );

      final result = resolveAuthorText(
        mod,
        authorOrder: AuthorTextOrder.shortFirst,
      );

      expect(result?.text, 'Summary');
      expect(result?.source, ModSummarySource.modIndex);
    });

    test('falls back to mod_info text and credits the file', () {
      final mod = _make(modInfoText: 'From mod_info.json');

      final result = resolveAuthorText(
        mod,
        authorOrder: AuthorTextOrder.longFirst,
      );

      expect(result?.text, 'From mod_info.json');
      expect(result?.source, ModSummarySource.modInfoFile);
    });

    test('returns null when no author text exists', () {
      final mod = _make(aiSentence: 'AI only');

      final result = resolveAuthorText(
        mod,
        authorOrder: AuthorTextOrder.shortFirst,
      );

      expect(result, isNull);
    });
  });

  group('shouldShowAiWithAuthorText', () {
    test('always mode shows AI beside author text', () {
      final mod = _make(aiParagraph: 'AI paragraph');

      expect(
        shouldShowAiWithAuthorText(
          mod,
          aiMode: AiSummaryMode.always,
          hasAuthorText: true,
        ),
        isTrue,
      );
    });

    test('whenNoAuthorText shows AI only when no author text', () {
      final mod = _make(aiParagraph: 'AI paragraph');

      expect(
        shouldShowAiWithAuthorText(
          mod,
          aiMode: AiSummaryMode.whenNoAuthorText,
          hasAuthorText: true,
        ),
        isFalse,
      );
      expect(
        shouldShowAiWithAuthorText(
          mod,
          aiMode: AiSummaryMode.whenNoAuthorText,
          hasAuthorText: false,
        ),
        isTrue,
      );
    });

    test('never mode never shows AI', () {
      final mod = _make(aiParagraph: 'AI paragraph');

      expect(
        shouldShowAiWithAuthorText(
          mod,
          aiMode: AiSummaryMode.never,
          hasAuthorText: false,
        ),
        isFalse,
      );
    });

    test('returns false when no AI paragraph exists', () {
      final mod = _make();

      expect(
        shouldShowAiWithAuthorText(
          mod,
          aiMode: AiSummaryMode.always,
          hasAuthorText: false,
        ),
        isFalse,
      );
    });
  });
}

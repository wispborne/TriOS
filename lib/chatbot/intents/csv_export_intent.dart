import '../chatbot_engine.dart';
import '../chatbot_models.dart';
import 'mod_aware_intent.dart';

/// Tells users about CSV export functionality in viewers and mod manager.
class CsvExportIntent extends ChatIntent {
  static const _phrases = [
    'export csv',
    'export to csv',
    'csv export',
    'export data',
    'export mods',
    'export ships',
    'export weapons',
    'export hullmods',
    'download csv',
    'save as csv',
    'spreadsheet export',
  ];

  static const _primaryKeywords = {
    'csv': 0.55,
    'export': 0.45,
    'spreadsheet': 0.4,
  };

  static const _secondaryKeywords = {
    'data': 0.1,
    'download': 0.1,
    'save': 0.1,
    'table': 0.1,
    'file': 0.1,
  };

  @override
  String get id => 'csv_export';

  @override
  double match(String input, ConversationContext context) {
    return ModAwareIntent.scoreInput(
      input,
      _phrases,
      _primaryKeywords,
      _secondaryKeywords,
    );
  }

  @override
  ChatResponse respond(String input, ConversationContext context) {
    return const ChatResponse(text: _response);
  }

  static const _response = 'CSV Export\n'
      '\n'
      'You can export data to CSV from several pages:\n'
      '  Mod Manager — exports your mod list with versions, authors, etc.\n'
      '  Ships — exports all ship/hull data\n'
      '  Weapons — exports all weapon data\n'
      '  Hullmods — exports all hull modification data\n'
      '\n'
      'Look for the export button in the toolbar or menu on each page.';
}

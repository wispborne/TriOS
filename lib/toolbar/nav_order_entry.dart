import 'package:dart_mappable/dart_mappable.dart';
import 'package:trios/trios/navigation.dart';

part 'nav_order_entry.mapper.dart';

/// A single entry in the user-customizable navigation order.
///
/// Either a tool ([NavToolEntry]) or the section divider ([NavDividerEntry]).
/// Persists in `Settings.navIconOrder`.
@MappableClass(discriminatorKey: 'type')
sealed class NavOrderEntry with NavOrderEntryMappable {
  const NavOrderEntry();
}

@MappableClass(discriminatorValue: 'tool')
class NavToolEntry extends NavOrderEntry with NavToolEntryMappable {
  final TriOSTools tool;

  const NavToolEntry(this.tool);
}

@MappableClass(discriminatorValue: 'divider')
class NavDividerEntry extends NavOrderEntry with NavDividerEntryMappable {
  const NavDividerEntry();
}

/// Logical sections of the nav. Callers ask the controller for the tools in
/// each section; the split is determined by the position of the divider entry.
enum NavSection { core, viewers }

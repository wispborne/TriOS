/// Generic filter engine: typed filter groups, scope-aware controller
/// toolkit, and renderer widget that viewer pages use to define and apply
/// filters.
///
/// - Group types: [FilterGroup], [ChipFilterGroup], [BoolFilterGroup],
///   [EnumFilterGroup], [CompositeFilterGroup] (+ [BoolField], [EnumField]).
/// - Identity: [FilterScope] (pageId, scopeId).
/// - Toolkit: [FilterScopeController].
/// - UI: [FilterGroupRenderer].
library;

export 'filter_group.dart';
export 'filter_group_renderer.dart';
export 'filter_scope.dart';
export 'filter_scope_controller.dart';

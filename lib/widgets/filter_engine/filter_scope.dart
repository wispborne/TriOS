/// Identity for a filter scope: `(pageId, scopeId)`.
///
/// Most pages have a single scope; `scopeId` defaults to `'main'`. Portraits
/// declares three (`main`, `left`, `right`) on one page.
///
/// Persistence keys are derived as `"pageId::scopeId::groupId"`.
class FilterScope {
  final String pageId;
  final String scopeId;

  const FilterScope(this.pageId, {this.scopeId = 'main'});

  String keyFor(String groupId) => '$pageId::$scopeId::$groupId';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterScope &&
          pageId == other.pageId &&
          scopeId == other.scopeId;

  @override
  int get hashCode => Object.hash(pageId, scopeId);

  @override
  String toString() => '$pageId::$scopeId';
}

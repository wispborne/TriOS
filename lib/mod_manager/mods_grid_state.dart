

import 'package:freezed_annotation/freezed_annotation.dart';

part '../generated/mod_manager/mods_grid_state.freezed.dart';
part '../generated/mod_manager/mods_grid_state.g.dart';

@freezed
class ModsGridState with _$ModsGridState{
  factory ModsGridState({
    @Default(true) bool isGroupEnabledExpanded,
    @Default(true) bool isGroupDisabledExpanded,
  }) = _ModsGridState;

  factory ModsGridState.fromJson(Map<String, Object?> json) =>
      _$ModsGridStateFromJson(json);
}

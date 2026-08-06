import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trios/mod_manager/version_checker.dart';
import 'package:trios/trios/deep_link/deep_link_handler.dart';
import 'package:trios/trios/download_manager/download_manager.dart';

/// What a download button is about, so it can find its own download among the
/// ones running.
///
/// No single clue works everywhere: a catalog install doesn't know the mod's
/// real id until the archive is unpacked, and a version-check update doesn't
/// know the catalog entry's name. So a target carries whatever it knows, and
/// [matches] tries each clue in turn.
@immutable
class DownloadTarget {
  /// The mod's id, when it's already installed or otherwise known.
  final String? modId;

  /// The URL the download would fetch.
  final String? url;

  /// The catalog entry's name, for catalog and forum installs.
  final String? catalogName;

  /// Whatever the download would be called on screen. Last resort.
  final String? displayName;

  const DownloadTarget({
    this.modId,
    this.url,
    this.catalogName,
    this.displayName,
  }) : assert(
         modId != null ||
             url != null ||
             catalogName != null ||
             displayName != null,
         'A download target needs at least one clue to match on.',
       );

  /// Does [download] look like the download this target is about?
  bool matches(Download download) {
    // Mod ids are exact. When both sides know one and they disagree, this is a
    // different mod and no amount of matching names should override that.
    final theirModId = _name(
      download is ModDownload ? download.modInfo.id : null,
    );
    final ourModId = _name(modId);
    if (ourModId != null && theirModId != null) return ourModId == theirModId;

    final ourUrl = _url(url);
    final theirUrl = _url(download.task.request.url);
    if (ourUrl != null && theirUrl != null && ourUrl == theirUrl) return true;

    // Catalog installs are named after their catalog entry, so the entry name
    // and the display name are worth checking against each other.
    final ourNames = {_name(catalogName), _name(displayName)}..remove(null);
    final theirNames = {
      _name(download.sourceHint?.catalogName),
      _name(download.displayName),
    }..remove(null);
    return ourNames.intersection(theirNames).isNotEmpty;
  }

  static String? _name(String? value) {
    final trimmed = value?.trim().toLowerCase();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static String? _url(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty)
        ? null
        : trimmed.fixModDownloadUrl();
  }

  @override
  bool operator ==(Object other) =>
      other is DownloadTarget &&
      other.modId == modId &&
      other.url == url &&
      other.catalogName == catalogName &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(modId, url, catalogName, displayName);

  @override
  String toString() =>
      'DownloadTarget(modId: $modId, url: $url, '
      'catalogName: $catalogName, displayName: $displayName)';
}

/// The download running for [target], or null when there isn't one.
Download? findActiveDownload(
  Iterable<Download> downloads,
  DownloadTarget target,
) => downloads.firstWhereOrNull((d) => d.isInProgress && target.matches(d));

/// How long a "just clicked" button keeps spinning with nothing to back it up.
const _pendingClickTimeout = Duration(seconds: 10);

/// Downloads that have been asked for but haven't shown up in the download
/// manager yet.
///
/// Some downloads take a moment to register — a TriOS deep link has to resolve
/// and ask the user to confirm first — and without this a button would sit
/// there looking dead in the meantime.
final pendingDownloadClicks =
    NotifierProvider<PendingDownloadClicks, Set<DownloadTarget>>(
      PendingDownloadClicks.new,
    );

class PendingDownloadClicks extends Notifier<Set<DownloadTarget>> {
  final _timeouts = <DownloadTarget, Timer>{};

  @override
  Set<DownloadTarget> build() {
    // A real download turned up — its own progress takes over from here.
    // Ask the same question the buttons ask, so a finished download left over
    // from earlier in the session can't hand off to nothing.
    ref.listen(downloadManager, (_, next) {
      final downloads = next.valueOrNull ?? const <Download>[];
      for (final target in state.toList()) {
        if (findActiveDownload(downloads, target) != null) clear(target);
      }
    });

    // The deep-link install flow finished getting ready: either its
    // confirmation dialog is up or the user backed out. Either way the button
    // has nothing left to wait for.
    ref.listen(deepLinkProcessing, (previous, next) {
      if (previous == true && next == false) clearAll();
    });

    ref.onDispose(_cancelTimeouts);
    return const <DownloadTarget>{};
  }

  void markClicked(DownloadTarget target) {
    _timeouts.remove(target)?.cancel();
    // Safety net: never spin forever if nothing ever registers (a de-duplicated
    // double click, say, or a download that fails before it starts).
    _timeouts[target] = Timer(_pendingClickTimeout, () => clear(target));
    state = {...state, target};
  }

  void clear(DownloadTarget target) {
    _timeouts.remove(target)?.cancel();
    if (!state.contains(target)) return;
    state = state.where((t) => t != target).toSet();
  }

  void clearAll() {
    _cancelTimeouts();
    if (state.isNotEmpty) state = const <DownloadTarget>{};
  }

  void _cancelTimeouts() {
    for (final timer in _timeouts.values) {
      timer.cancel();
    }
    _timeouts.clear();
  }
}

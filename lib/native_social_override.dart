import 'dart:async';

import 'package:amity_sdk/amity_sdk.dart';

/// Injection seam for the TPS-0 native social pilot.
///
/// The UI in this package stays exactly as it is. Only the *source* of the
/// posts changes: when [globalFeedFetcher] is set, the feed view-model calls it
/// instead of building an Amity live collection.
///
/// The fetcher is injected by the host app (mobile-app-padel) so this package
/// gains no new dependency and no knowledge of Supabase. If nothing injects,
/// behaviour is byte-identical to today.
typedef NativeFeedFetcher = Future<List<AmityPost>> Function({
  int limit,
  String? token,
});

/// Same idea as [NativeFeedFetcher], scoped to one community's own timeline
/// (community_feed_viewmodel.dart) rather than the global feed.
typedef NativeCommunityFeedFetcher = Future<List<AmityPost>> Function({
  required String communityId,
  int limit,
  String? token,
});

class NativeSocialOverride {
  NativeSocialOverride._();

  /// Set by the host app at startup when `tps-0-native-social` is on for the
  /// signed-in user. Null means "use Amity", which is the default everywhere.
  static NativeFeedFetcher? globalFeedFetcher;

  /// Same gate, for a single community's timeline.
  static NativeCommunityFeedFetcher? communityFeedFetcher;

  static bool get isActive => globalFeedFetcher != null;

  /// Cleared on sign-out / flag-off so a stale session can never leak.
  static void reset() {
    globalFeedFetcher = null;
    communityFeedFetcher = null;
  }

  /// Signals when the host app's install() has finished deciding whether the
  /// override applies. Feed screens can render (and fire GlobalFeedInit)
  /// before install() — which runs deep in the post-login bootstrap chain —
  /// has had a chance to run, so a fast tap into Feed right after cold start
  /// used to race ahead of it and permanently latch onto Amity for the rest
  /// of the session. Awaiting this (with a timeout, so a stuck install()
  /// never strands the feed) closes that window.
  static final Completer<void> _ready = Completer<void>();
  static Future<void> get ready => _ready.future;

  /// Called by the host app at the end of install(), success or failure.
  static void markReady() {
    if (!_ready.isCompleted) _ready.complete();
  }
}

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

class NativeSocialOverride {
  NativeSocialOverride._();

  /// Set by the host app at startup when `tps-0-native-social` is on for the
  /// signed-in user. Null means "use Amity", which is the default everywhere.
  static NativeFeedFetcher? globalFeedFetcher;

  static bool get isActive => globalFeedFetcher != null;

  /// Cleared on sign-out / flag-off so a stale session can never leak.
  static void reset() => globalFeedFetcher = null;
}

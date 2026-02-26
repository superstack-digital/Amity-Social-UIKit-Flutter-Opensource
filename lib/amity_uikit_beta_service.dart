
import 'amity_uikit_beta_service_platform_interface.dart';
import 'package:amity_uikit_beta_service/v4/utils/post_data_cache_manager.dart';

class AmityUikitBetaService {
  Future<String?> getPlatformVersion() {
    return AmityUikitBetaServicePlatform.instance.getPlatformVersion();
  }

  /// Clear all feed post caches
  /// Call this when you need to force refresh feed data
  /// (e.g., after creating/updating/deleting a post, match, or event)
  static void clearFeedCache() {
    PostDataCacheManager().clearAllCaches();
  }

  /// Clear specific match cache by match ID
  static void clearMatchCache(int matchId) {
    PostDataCacheManager().clearMatchCache(matchId);
  }

  /// Clear specific event cache by event ID
  static void clearEventCache(int eventId) {
    PostDataCacheManager().clearEventCache(eventId);
  }

  /// Clear specific user cache by user ID
  static void clearUserCache(int userId) {
    PostDataCacheManager().clearUserCache(userId);
  }

  /// Clear current user cache
  static void clearCurrentUserCache() {
    PostDataCacheManager().clearCurrentUserCache();
  }

  /// Clear only expired cache entries (automatic cleanup)
  static void clearExpiredCaches() {
    PostDataCacheManager().clearExpiredEntries();
  }

  /// Get cache statistics (for debugging)
  static Map<String, int> getFeedCacheStats() {
    return PostDataCacheManager().getCacheStats();
  }
}

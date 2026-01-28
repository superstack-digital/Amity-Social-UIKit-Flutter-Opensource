/// Post Height Cache Manager
/// Caches the rendered height of posts to prevent layout shifts and jank during scroll
class PostHeightCacheManager {
  static final PostHeightCacheManager _instance = PostHeightCacheManager._internal();
  factory PostHeightCacheManager() => _instance;
  PostHeightCacheManager._internal();

  // Cache post heights by post ID
  final Map<String, double> _heightCache = {};

  /// Get cached height for a post
  double? getHeight(String postId) {
    return _heightCache[postId];
  }

  /// Set height for a post after measurement
  void setHeight(String postId, double height) {
    _heightCache[postId] = height;
  }

  /// Check if height is cached
  bool hasHeight(String postId) {
    return _heightCache.containsKey(postId);
  }

  /// Clear height for specific post (e.g., after content change)
  void clearHeight(String postId) {
    _heightCache.remove(postId);
  }

  /// Clear all cached heights
  void clearAllHeights() {
    _heightCache.clear();
  }

  /// Get cache stats
  Map<String, dynamic> getStats() {
    return {
      'totalCached': _heightCache.length,
      'heights': _heightCache,
    };
  }
}

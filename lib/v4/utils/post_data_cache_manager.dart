import 'package:amity_sdk/amity_sdk.dart';
import 'package:mobile_app_padel/features/profile/data/match.dart';
import 'package:mobile_app_padel/features/community/data/models/event.dart';
import 'package:mobile_app_padel/features/community/data/models/event_standing.dart';
import 'package:mobile_app_padel/features/onboarding/data/models/user.dart';
import 'package:mobile_app_padel/features/profile/data/repositories/match_repository.dart';
import 'package:mobile_app_padel/features/community/data/repositories/event_repository.dart';
import 'package:mobile_app_padel/features/profile/data/repositories/profile_repository.dart';
import 'package:mobile_app_padel/features/community/data/models/community_ranking_data.dart';
import 'package:mobile_app_padel/shared/deeplink.dart';

/// Cache entry wrapper with timestamp
class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;

  _CacheEntry(this.data, this.timestamp);

  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(timestamp) > maxAge;
  }
}

/// Global cache manager for post-related data
/// Prevents duplicate API calls across different posts
/// Auto-clears cache after 24 hours
class PostDataCacheManager {
  static final PostDataCacheManager _instance = PostDataCacheManager._internal();
  factory PostDataCacheManager() => _instance;
  PostDataCacheManager._internal();

  // Cache storage with timestamps
  final Map<int, _CacheEntry<IMatch>> _matchCache = {};
  final Map<int, _CacheEntry<Event>> _eventCache = {};
  final Map<int, _CacheEntry<IMatch>> _matchResultCache = {};
  final Map<int, _CacheEntry<List<EventStanding>>> _eventStandingCache = {};
  final Map<int, _CacheEntry<User>> _userCache = {};
  final Map<String, _CacheEntry<List<CommunityRankingData>>> _communityRankingCache = {}; // Key: "communityId_eventType_startDate_endDate"
  _CacheEntry<AmityUser>? _currentUserCache;

  // Cache duration - 2 minutes for all data to ensure freshness
  // Events and matches can be updated frequently
  static const Duration _cacheDuration = Duration(minutes: 2);

  // Track ongoing requests to prevent duplicate calls
  final Map<String, Future<dynamic>> _ongoingRequests = {};

  /// Get match details with cache
  Future<IMatch?> getMatchDetails(int matchId) async {
    // Check cache first and validate expiry
    if (_matchCache.containsKey(matchId)) {
      final entry = _matchCache[matchId]!;
      if (!entry.isExpired(_cacheDuration)) {
        return entry.data;
      } else {
        // Cache expired, remove it
        _matchCache.remove(matchId);
      }
    }

    // Check if request is already ongoing
    final key = 'match_$matchId';
    if (_ongoingRequests.containsKey(key)) {
      return await _ongoingRequests[key] as IMatch?;
    }

    // Make new request
    final future = MatchRepository.getInstance().getMatchDetails(matchId);
    _ongoingRequests[key] = future;

    try {
      final result = await future;
      if (result != null) {
        _matchCache[matchId] = _CacheEntry(result, DateTime.now());
      }
      return result;
    } finally {
      _ongoingRequests.remove(key);
    }
  }

  /// Get event details with cache
  Future<Event?> getEventDetails(int eventId) async {
    if (_eventCache.containsKey(eventId)) {
      final entry = _eventCache[eventId]!;
      if (!entry.isExpired(_cacheDuration)) {
        return entry.data;
      } else {
        _eventCache.remove(eventId);
      }
    }

    final key = 'event_$eventId';
    if (_ongoingRequests.containsKey(key)) {
      return await _ongoingRequests[key] as Event?;
    }

    final future = EventRepository.getInstance().getEventDetails(eventId);
    _ongoingRequests[key] = future;

    try {
      final result = await future;
      if (result != null) {
        _eventCache[eventId] = _CacheEntry(result, DateTime.now());
      }
      return result;
    } finally {
      _ongoingRequests.remove(key);
    }
  }

  /// Get match result details with cache
  Future<IMatch?> getMatchResultDetails(int matchResultId) async {
    if (_matchResultCache.containsKey(matchResultId)) {
      final entry = _matchResultCache[matchResultId]!;
      if (!entry.isExpired(_cacheDuration)) {
        return entry.data;
      } else {
        _matchResultCache.remove(matchResultId);
      }
    }

    final key = 'match_result_$matchResultId';
    if (_ongoingRequests.containsKey(key)) {
      return await _ongoingRequests[key] as IMatch?;
    }

    final future = MatchRepository.getInstance().getMatchDetails(matchResultId);
    _ongoingRequests[key] = future;

    try {
      final result = await future;
      if (result != null) {
        _matchResultCache[matchResultId] = _CacheEntry(result, DateTime.now());
      }
      return result;
    } finally {
      _ongoingRequests.remove(key);
    }
  }

  /// Get event standing details with cache
  Future<List<EventStanding>?> getEventStandingDetails(int eventStandingId) async {
    if (_eventStandingCache.containsKey(eventStandingId)) {
      final entry = _eventStandingCache[eventStandingId]!;
      if (!entry.isExpired(_cacheDuration)) {
        return entry.data;
      } else {
        _eventStandingCache.remove(eventStandingId);
      }
    }

    final key = 'event_standing_$eventStandingId';
    if (_ongoingRequests.containsKey(key)) {
      return await _ongoingRequests[key] as List<EventStanding>?;
    }

    final future = EventRepository.getInstance().getEventStandingById(eventStandingId);
    _ongoingRequests[key] = future;

    try {
      final result = await future;
      if (result != null) {
        _eventStandingCache[eventStandingId] = _CacheEntry(result, DateTime.now());
      }
      return result;
    } finally {
      _ongoingRequests.remove(key);
    }
  }

  /// Get user details with cache
  Future<User?> getUserDetails(int userId) async {
    if (_userCache.containsKey(userId)) {
      final entry = _userCache[userId]!;
      if (!entry.isExpired(_cacheDuration)) {
        return entry.data;
      } else {
        _userCache.remove(userId);
      }
    }

    final key = 'user_$userId';
    if (_ongoingRequests.containsKey(key)) {
      return await _ongoingRequests[key] as User?;
    }

    final future = ProfileRepository.getInstance().getUserDetails(userId);
    _ongoingRequests[key] = future;

    try {
      final result = await future;
      if (result != null) {
        _userCache[userId] = _CacheEntry(result, DateTime.now());
      }
      return result;
    } finally {
      _ongoingRequests.remove(key);
    }
  }

  /// Get multiple users at once with cache
  Future<List<User>> getMultipleUsers(List<int> userIds) async {
    final List<User> results = [];
    final List<int> uncachedIds = [];

    // Separate cached and uncached, check expiry
    for (final id in userIds) {
      if (_userCache.containsKey(id)) {
        final entry = _userCache[id]!;
        if (!entry.isExpired(_cacheDuration)) {
          results.add(entry.data);
        } else {
          _userCache.remove(id);
          uncachedIds.add(id);
        }
      } else {
        uncachedIds.add(id);
      }
    }

    // Fetch uncached users
    if (uncachedIds.isNotEmpty) {
      final futures = uncachedIds.map((id) => getUserDetails(id));
      final fetchedUsers = await Future.wait(futures);
      
      for (final user in fetchedUsers) {
        if (user != null) {
          results.add(user);
        }
      }
    }

    return results;
  }

  /// Get current user with cache (expires after 5 minutes)
  Future<AmityUser?> getCurrentUser() async {
    // Check if cache is still valid
    if (_currentUserCache != null) {
      if (!_currentUserCache!.isExpired(_cacheDuration)) {
        return _currentUserCache!.data;
      } else {
        _currentUserCache = null;
      }
    }

    final key = 'current_user';
    if (_ongoingRequests.containsKey(key)) {
      return await _ongoingRequests[key] as AmityUser?;
    }

    final future = Future.value(AmityCoreClient.getCurrentUser());
    _ongoingRequests[key] = future;

    try {
      final result = await future;
      if (result != null) {
        _currentUserCache = _CacheEntry(result, DateTime.now());
      }
      return result;
    } finally {
      _ongoingRequests.remove(key);
    }
  }

  /// Get weekly ranking data with cache
  /// Get community ranking data with cache
  Future<List<CommunityRankingData>?> getCommunityRankingData(
    String communityId,
    String eventType,
    String startDate,
    String endDate,
  ) async {
    final cacheKey = '${communityId}_${eventType}_${startDate}_${endDate}';
    
    if (_communityRankingCache.containsKey(cacheKey)) {
      final entry = _communityRankingCache[cacheKey]!;
      if (!entry.isExpired(_cacheDuration)) {
        return entry.data;
      } else {
        _communityRankingCache.remove(cacheKey);
      }
    }

    final key = 'community_ranking_$cacheKey';
    if (_ongoingRequests.containsKey(key)) {
      return await _ongoingRequests[key] as List<CommunityRankingData>?;
    }

    final future = _fetchCommunityRankingData(communityId, eventType, startDate, endDate);
    _ongoingRequests[key] = future;

    try {
      final result = await future;
      if (result != null) {
        _communityRankingCache[cacheKey] = _CacheEntry(result, DateTime.now());
      }
      return result;
    } finally {
      _ongoingRequests.remove(key);
    }
  }

  /// Fetch community ranking data from Supabase
  Future<List<CommunityRankingData>?> _fetchCommunityRankingData(
    String communityId,
    String eventType,
    String startDate,
    String endDate,
  ) async {
    try {
      final response = await supabaseClient.rpc('get_community_rankings', params: {
        'p_community_id': communityId,
        'p_event_type': eventType,
        'p_time_period': 'custom',
        'p_start_date': startDate,
        'p_end_date': endDate,
        'p_include_details': true
      });

      if (response == null) return null;

      final rankingsData = response as List<dynamic>;
      return rankingsData.map((e) => CommunityRankingData.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error fetching weekly ranking data: $e');
      return null;
    }
  }

  /// Clear specific cache
  void clearMatchCache(int matchId) => _matchCache.remove(matchId);
  void clearEventCache(int eventId) => _eventCache.remove(eventId);
  void clearUserCache(int userId) => _userCache.remove(userId);
  void clearCommunityRankingCache(String communityId, String eventType, String startDate, String endDate) {
    final cacheKey = '${communityId}_${eventType}_${startDate}_${endDate}';
    _communityRankingCache.remove(cacheKey);
  }
  void clearCurrentUserCache() {
    _currentUserCache = null;
  }

  /// Clear all caches
  void clearAllCaches() {
    _matchCache.clear();
    _eventCache.clear();
    _matchResultCache.clear();
    _eventStandingCache.clear();
    _userCache.clear();
    _communityRankingCache.clear();
    _currentUserCache = null;
    _ongoingRequests.clear();
  }

  /// Clear expired entries from all caches
  void clearExpiredEntries() {
    _matchCache.removeWhere((key, entry) => entry.isExpired(_cacheDuration));
    _eventCache.removeWhere((key, entry) => entry.isExpired(_cacheDuration));
    _matchResultCache.removeWhere((key, entry) => entry.isExpired(_cacheDuration));
    _eventStandingCache.removeWhere((key, entry) => entry.isExpired(_cacheDuration));
    _userCache.removeWhere((key, entry) => entry.isExpired(_cacheDuration));
    _communityRankingCache.removeWhere((key, entry) => entry.isExpired(_cacheDuration));
    
    if (_currentUserCache != null && _currentUserCache!.isExpired(_cacheDuration)) {
      _currentUserCache = null;
    }
  }

  /// Get cache stats (for debugging)
  Map<String, int> getCacheStats() {
    return {
      'matches': _matchCache.length,
      'events': _eventCache.length,
      'matchResults': _matchResultCache.length,
      'eventStandings': _eventStandingCache.length,
      'users': _userCache.length,
      'communityRankings': _communityRankingCache.length,
      'currentUser': _currentUserCache != null ? 1 : 0,
      'ongoingRequests': _ongoingRequests.length,
    };
  }

  /// Synchronous cache getters - return immediately without async
  IMatch? getCachedMatch(int matchId) {
    if (_matchCache.containsKey(matchId)) {
      final entry = _matchCache[matchId]!;
      if (!entry.isExpired(_cacheDuration)) {
        return entry.data;
      }
      _matchCache.remove(matchId);
    }
    return null;
  }

  Event? getCachedEvent(int eventId) {
    if (_eventCache.containsKey(eventId)) {
      final entry = _eventCache[eventId]!;
      if (!entry.isExpired(_cacheDuration)) {
        return entry.data;
      }
      _eventCache.remove(eventId);
    }
    return null;
  }

  IMatch? getCachedMatchResult(int matchResultId) {
    if (_matchResultCache.containsKey(matchResultId)) {
      final entry = _matchResultCache[matchResultId]!;
      if (!entry.isExpired(_cacheDuration)) {
        return entry.data;
      }
      _matchResultCache.remove(matchResultId);
    }
    return null;
  }

  List<EventStanding>? getCachedEventStanding(int eventStandingId) {
    if (_eventStandingCache.containsKey(eventStandingId)) {
      final entry = _eventStandingCache[eventStandingId]!;
      if (!entry.isExpired(_cacheDuration)) {
        return entry.data;
      }
      _eventStandingCache.remove(eventStandingId);
    }
    return null;
  }

  User? getCachedUser(int userId) {
    if (_userCache.containsKey(userId)) {
      final entry = _userCache[userId]!;
      if (!entry.isExpired(_cacheDuration)) {
        return entry.data;
      }
      _userCache.remove(userId);
    }
    return null;
  }

  AmityUser? getCachedCurrentUser() {
    if (_currentUserCache != null && !_currentUserCache!.isExpired(_cacheDuration)) {
      return _currentUserCache!.data;
    }
    return null;
  }

  List<CommunityRankingData>? getCachedCommunityRanking(String communityId, String eventType, String startDate, String endDate) {
    final cacheKey = '${communityId}_${eventType}_${startDate}_${endDate}';
    if (_communityRankingCache.containsKey(cacheKey)) {
      final entry = _communityRankingCache[cacheKey]!;
      if (!entry.isExpired(_cacheDuration)) {
        return entry.data;
      }
      _communityRankingCache.remove(cacheKey);
    }
    return null;
  }
}

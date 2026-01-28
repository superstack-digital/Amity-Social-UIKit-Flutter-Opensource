import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/v4/core/base_component.dart';
import 'package:amity_uikit_beta_service/v4/social/post/common/post_action.dart';
import 'package:amity_uikit_beta_service/v4/social/post/post_detail/post_detail.dart';
import 'package:amity_uikit_beta_service/v4/social/post/post_item/post_item_updated.dart';
import 'package:flutter/material.dart';

import 'package:mobile_app_padel/features/community/presentation/screens/people_profile_screen.dart';
import 'package:mobile_app_padel/shared/constants.dart';
import 'package:mobile_app_padel/shared/deeplink.dart';
import 'package:mobile_app_padel/features/profile/data/repositories/match_repository.dart';
import 'package:mobile_app_padel/features/profile/data/repositories/profile_repository.dart';
import 'package:mobile_app_padel/features/play/presentation/widgets/court_match_item.dart';
import 'package:mobile_app_padel/features/profile/data/match.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:mobile_app_padel/shared/widgets/skeleton_container.dart';
import 'package:mobile_app_padel/shared/styles.dart';
import 'package:mobile_app_padel/shared/widgets/richtext_with_mention.dart';
import 'package:mobile_app_padel/shared/widgets/create_post_text_field.dart';
import 'package:mobile_app_padel/features/community/data/models/event.dart';
import 'package:mobile_app_padel/features/community/data/models/event_standing.dart';
import 'package:mobile_app_padel/features/community/data/repositories/event_repository.dart';
import 'package:mobile_app_padel/features/play/presentation/widgets/upcoming_event_item.dart';
import 'package:mobile_app_padel/features/profile/widgets/profile_score_set_item.dart';
import 'package:mobile_app_padel/features/community/presentation/screens/ranking_leaderboard.dart';
import 'package:mobile_app_padel/features/community/data/models/community_leaderboard_data.dart';
import 'package:mobile_app_padel/features/onboarding/data/models/user.dart';
import 'package:mobile_app_padel/features/community/widgets/ranking_avatar.dart';
import 'package:mobile_app_padel/features/community/widgets/team_ranking_avatar.dart';
import 'package:country_picker/country_picker.dart';
import 'package:mobile_app_padel/shared/widgets/deleted_content_placeholder.dart';
import 'package:amity_uikit_beta_service/v4/utils/post_data_cache_manager.dart';
import 'package:mobile_app_padel/features/community/data/models/community_ranking_data.dart';

enum AmityPostContentComponentStyle { feed, detail }

class AmityPostContentComponent extends StatefulWidget {
  final String? pageId;
  final String? componentId;
  final AmityPost post;
  final AmityPostContentComponentStyle style;
  final AmityPostAction? action;

  const AmityPostContentComponent({
    Key? key,
    this.pageId,
    required this.post,
    required this.style,
    this.componentId = "post_content_component",
    this.action,
  }) : super(key: key);

  @override
  State<AmityPostContentComponent> createState() => _AmityPostContentComponentState();
}

class _AmityPostContentComponentState extends State<AmityPostContentComponent> {
  IMatch? _match;
  Event? _event;
  IMatch? _matchResult;
  List<EventStanding>? _eventStandings;
  User? _followingUser;
  AmityUser? _currentUser;
  List<CommunityRankingData>? _communityRanking;
  bool _isLoading = false;
  bool _hasLoadedData = false;

  @override
  void initState() {
    super.initState();
    _loadDataIfNeeded();
  }

  Future<void> _loadDataIfNeeded() async {
    if (_hasLoadedData || _isLoading) return;

    if (widget.style != AmityPostContentComponentStyle.feed) return;

    final metadata = widget.post.metadata;
    final matchId = metadata?["matchId"] as int?;
    final matchResultId = metadata?["matchResultId"] as int?;
    final eventId = metadata?["eventId"] as int?;
    final eventStandingId = metadata?["eventStandingId"] as int?;
    final userId = metadata?["followingUserId"] as int?;
    
    // Weekly ranking metadata (camelCase)
    final communityRankingCommunityId = metadata?["communityId"] as String?;
    final communityRankingEventType = metadata?["eventType"] as String?;
    final communityRankingStartDate = metadata?["startDate"] as String?;
    final communityRankingEndDate = metadata?["endDate"] as String?;

    // Use cache manager - it returns instantly if cached
    final cacheManager = PostDataCacheManager();

    // Try to load from cache synchronously first
    _loadFromCacheSync(
        cacheManager, matchId, eventId, matchResultId, eventStandingId, userId,
        communityRankingCommunityId, communityRankingEventType, communityRankingStartDate, communityRankingEndDate);

    // Build list of futures only for needed data using cache
    final List<Future<dynamic>> futures = [];
    int matchIndex = -1;
    int eventIndex = -1;
    int matchResultIndex = -1;
    int eventStandingIndex = -1;
    int followingUserIndex = -1;
    int currentUserIndex = -1;
    int communityRankingIndex = -1;

    if (matchId != null) {
      matchIndex = futures.length;
      futures.add(cacheManager.getMatchDetails(matchId));
    }

    if (eventId != null) {
      eventIndex = futures.length;
      futures.add(cacheManager.getEventDetails(eventId));
    }

    if (matchResultId != null) {
      matchResultIndex = futures.length;
      futures.add(cacheManager.getMatchResultDetails(matchResultId));
    }

    if (eventStandingId != null) {
      eventStandingIndex = futures.length;
      futures.add(cacheManager.getEventStandingDetails(eventStandingId));
    }

    if (userId != null) {
      followingUserIndex = futures.length;
      futures.add(cacheManager.getUserDetails(userId));
      currentUserIndex = futures.length;
      futures.add(cacheManager.getCurrentUser());
    }
    
    if (communityRankingCommunityId != null && communityRankingEventType != null && 
        communityRankingStartDate != null && communityRankingEndDate != null) {
      communityRankingIndex = futures.length;
      futures.add(cacheManager.getCommunityRankingData(
        communityRankingCommunityId,
        communityRankingEventType,
        communityRankingStartDate,
        communityRankingEndDate,
      ));
    }

    if (futures.isEmpty) {
      setState(() {
        _hasLoadedData = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait(futures);

      if (mounted) {
        setState(() {
          if (matchIndex >= 0) _match = results[matchIndex] as IMatch?;
          if (eventIndex >= 0) _event = results[eventIndex] as Event?;
          if (matchResultIndex >= 0) _matchResult = results[matchResultIndex] as IMatch?;
          if (eventStandingIndex >= 0)
            _eventStandings = results[eventStandingIndex] as List<EventStanding>?;
          if (followingUserIndex >= 0)
            _followingUser = results[followingUserIndex] as User?;
          if (currentUserIndex >= 0)
            _currentUser = results[currentUserIndex] as AmityUser?;
          if (communityRankingIndex >= 0)
            _communityRanking = results[communityRankingIndex] as List<CommunityRankingData>?;
          _isLoading = false;
          _hasLoadedData = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasLoadedData = true;
        });
      }
    }
  }

  void _loadFromCacheSync(PostDataCacheManager cacheManager, int? matchId, int? eventId,
      int? matchResultId, int? eventStandingId, int? userId,
      String? communityRankingCommunityId, String? communityRankingEventType,
      String? communityRankingStartDate, String? communityRankingEndDate) {
    // Try to get cached data synchronously before first render
    if (matchId != null) {
      _match = cacheManager.getCachedMatch(matchId);
    }
    if (eventId != null) {
      _event = cacheManager.getCachedEvent(eventId);
    }
    if (matchResultId != null) {
      _matchResult = cacheManager.getCachedMatchResult(matchResultId);
    }
    if (eventStandingId != null) {
      _eventStandings = cacheManager.getCachedEventStanding(eventStandingId);
    }
    if (userId != null) {
      _followingUser = cacheManager.getCachedUser(userId);
      _currentUser = cacheManager.getCachedCurrentUser();
    }
    if (communityRankingCommunityId != null && communityRankingEventType != null &&
        communityRankingStartDate != null && communityRankingEndDate != null) {
      _communityRanking = cacheManager.getCachedCommunityRanking(
        communityRankingCommunityId,
        communityRankingEventType,
        communityRankingStartDate,
        communityRankingEndDate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.style == AmityPostContentComponentStyle.feed) {
      // Always render immediately with whatever data we have (cached or null)
      // This prevents showing loading spinner when scrolling
      return PostItem(
        pageId: widget.pageId,
        post: widget.post,
        action: widget.action,
        match: _match,
        event: _event,
        matchResult: _matchResult,
        eventStanding: _eventStandings,
        followingUser: _followingUser,
        currentUser: _currentUser,
        communityRanking: _communityRanking,
      );
    } else {
      return PostDetail(pageId: widget.pageId, post: widget.post, action: widget.action);
    }
  }

  Widget _buildLoadingPlaceholder() {
    // Fixed height placeholder to prevent jank
    // Adjust height based on post type
    double placeholderHeight = 200; // Default height

    final metadata = widget.post.metadata;
    if (metadata?["eventId"] != null) {
      placeholderHeight = 300; // Event posts are taller
    } else if (metadata?["matchId"] != null) {
      placeholderHeight = 250; // Match posts
    }

    return Container(
      height: placeholderHeight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skeleton placeholder
          Container(
            width: double.infinity,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 150,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

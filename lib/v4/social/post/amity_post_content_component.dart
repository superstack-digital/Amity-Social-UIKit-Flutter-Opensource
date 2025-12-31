import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/v4/core/base_component.dart';
import 'package:amity_uikit_beta_service/v4/social/post/common/post_action.dart';
import 'package:amity_uikit_beta_service/v4/social/post/post_detail/post_detail.dart';
import 'package:amity_uikit_beta_service/v4/social/post/post_item/post_item_updated.dart';
import 'package:flutter/widgets.dart';

import 'package:mobile_app_padel/features/community/presentation/screens/people_profile_screen.dart';
import 'package:mobile_app_padel/shared/constants.dart';
import 'package:mobile_app_padel/shared/deeplink.dart';
import 'package:mobile_app_padel/features/profile/data/repositories/match_repository.dart';
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

enum AmityPostContentComponentStyle { feed, detail }

class AmityPostContentComponent extends NewBaseComponent {
  final AmityPost post;
  final AmityPostContentComponentStyle style;
  final AmityPostAction? action;

  AmityPostContentComponent({
    super.key,
    super.pageId,
    required this.post,
    required this.style,
    super.componentId = "post_content_component",
    this.action,
  });

  @override
  Widget buildComponent(BuildContext context) {
    if (style == AmityPostContentComponentStyle.feed) {
      final metadata = post.metadata;
      final matchId = metadata?["matchId"];
      final matchResultId = metadata?["matchResultId"];
      final eventId = metadata?["eventId"];
      final eventStandingId = metadata?["eventStandingId"];

      _getMatchDetails(int? matchId) async {
        if (matchId != null) {
          return await MatchRepository
              .getInstance()
              .getMatchDetails(
              matchId);
        }
        return null;
      }

      _getMatchResultDetails(int? matchResultId) async {
        if (matchResultId != null) {
          return await MatchRepository
              .getInstance()
              .getMatchDetails(
              matchResultId);
        }
        return null;
      }

      _getEventDetails(int? eventId) async {
        if (eventId != null) {
          return await EventRepository
              .getInstance()
              .getEventDetails(eventId);
        }
        return null;
      }
      _getEventStandingDetails(int? eventStandingId) async {
        if (eventStandingId != null) {
          return await EventRepository
              .getInstance()
              .getEventStandingById(eventStandingId);
        }
        return null;
      }
      return FutureBuilder<List<dynamic>>(
          future: Future.wait([
            _getMatchDetails(matchId),
            _getEventDetails(eventId),
            _getMatchResultDetails(matchResultId),
            _getEventStandingDetails(eventStandingId),
          ]),
          builder: (context, snapshot1) {
            final match = snapshot1.data?[0] as IMatch?;
            final event = snapshot1.data?[1] as Event?;
            final matchResult = snapshot1.data?[2] as IMatch?;
            final eventStandings = snapshot1.data?[3] as List<EventStanding>?;
            return PostItem(pageId: pageId,
                post: post,
                action: action,
                match: match,
                event: event,
                matchResult: matchResult,
                eventStanding: eventStandings != null ? eventStandings : null);
          });
    } else {
      return PostDetail(pageId: pageId, post: post, action: action);
    }
  }
}

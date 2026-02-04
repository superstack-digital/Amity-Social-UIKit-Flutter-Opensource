import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/v4/core/base_component.dart';
import 'package:amity_uikit_beta_service/v4/social/globalfeed/bloc/global_feed_bloc.dart';
import 'package:amity_uikit_beta_service/v4/social/post/common/post_action.dart';
import 'package:amity_uikit_beta_service/v4/social/post/common/post_children_content_image.dart';
import 'package:amity_uikit_beta_service/v4/social/post/common/post_children_content_video.dart';
import 'package:amity_uikit_beta_service/v4/social/post/common/post_header.dart';
import 'package:amity_uikit_beta_service/v4/social/post/post_detail/amity_post_detail_page.dart';
import 'package:amity_uikit_beta_service/v4/social/post/post_item/bloc/post_item_bloc.dart';
import 'package:amity_uikit_beta_service/v4/social/post/post_item/post_item_bottom.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:linkify/linkify.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:amity_uikit_beta_service/viewmodel/community_feed_viewmodel.dart';
import 'package:provider/provider.dart';

// Import custom components from mobile_app_padel
import 'package:mobile_app_padel/features/profile/data/match.dart';
import 'package:mobile_app_padel/features/play/presentation/widgets/post_match_item.dart';
import 'package:mobile_app_padel/features/profile/widgets/profile_score_set_item.dart';
import 'package:mobile_app_padel/features/community/data/models/event.dart';
import 'package:mobile_app_padel/features/play/presentation/widgets/upcoming_event_item.dart';
import 'package:mobile_app_padel/features/community/data/models/event_standing.dart';
import 'package:mobile_app_padel/features/community/presentation/screens/ranking_leaderboard.dart';
import 'package:mobile_app_padel/features/community/data/models/community_leaderboard_data.dart';
import 'package:mobile_app_padel/features/onboarding/data/models/user.dart';
import 'package:mobile_app_padel/features/community/widgets/ranking_avatar.dart';
import 'package:mobile_app_padel/features/community/widgets/team_ranking_avatar.dart';
import 'package:country_picker/country_picker.dart';
import 'package:mobile_app_padel/shared/widgets/deleted_content_placeholder.dart';
import 'package:mobile_app_padel/shared/styles.dart';
import 'package:mobile_app_padel/shared/widgets/create_post_text_field.dart';
import 'package:mobile_app_padel/features/community/presentation/screens/people_profile_screen.dart';
import 'package:mobile_app_padel/shared/constants.dart';
import 'package:get/get.dart';
import 'package:amity_uikit_beta_service/view/social/comments_v2.dart';
import 'package:amity_uikit_beta_service/view/social/global_feed.dart';
import 'package:mobile_app_padel/shared/functions.dart';
import 'package:mobile_app_padel/shared/shared_preferences.dart';
import 'package:mobile_app_padel/features/community/widgets/post_event_item.dart';
import 'package:mobile_app_padel/features/community/widgets/following_user_post_item.dart';
import 'package:mobile_app_padel/features/community/widgets/levelel_up_post_item.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:mobile_app_padel/features/community/data/models/community_ranking_data.dart';
import 'package:mobile_app_padel/features/community/presentation/screens/community_ranking_leaderboard.dart';
import 'package:mobile_app_padel/shared/widgets/link_preview_image.dart';
import 'package:any_link_preview/any_link_preview.dart';


class PostItem extends NewBaseComponent {
  final AmityPost post;
  final AmityPostAction? action;
  final IMatch? match;
  final IMatch? matchResult;
  final Event? event;
  final List<EventStanding>? eventStanding;
  final User? followingUser;
  final AmityUser? currentUser;
  final List<CommunityRankingData>? communityRanking;
  final bool isPostDetail;

  PostItem({
    Key? key,
    String? pageId,
    required this.post,
    this.action,
    this.match,
    this.matchResult,
    this.event,
    this.eventStanding,
    this.followingUser,
    this.currentUser,
    this.communityRanking,
    this.isPostDetail = false,
  }) : super(key: key, pageId: pageId, componentId: "post_item_component");

  @override
  Widget buildComponent(BuildContext context) {
    return BlocBuilder<PostItemBloc, PostItemState>(builder: (context, state) {
      if (state is PostItemStateLoaded) {
        return renderPost(context: context, post: state.post);
      } else if (state is PostItemStateReacting) {
        return renderPost(context: context, post: state.post, isReacting: true);
      } else {
        return renderPost(context: context, post: post);
      }
    });
  }

  Widget renderPost(
      {required BuildContext context,
      required AmityPost post,
      bool isReacting = false}) {
    onAddReaction(reactionType) {
      context
          .read<PostItemBloc>()
          .add(AddReactionToPost(post: post, reactionType: reactionType));
    }

    onRemoveReaction(reactionType) {
      context
          .read<PostItemBloc>()
          .add(RemoveReactionToPost(post: post, reactionType: reactionType));
    }

    onPostUpdated(post) {
      context.read<PostItemBloc>().add(PostItemLoaded(post: post));
    }

    var postAction = (action != null)
        ? action!.copyWith(
            onAddReaction: onAddReaction, onRemoveReaction: onRemoveReaction, onPostUpdated: onPostUpdated)
        : AmityPostAction(
            onAddReaction: onAddReaction,
            onRemoveReaction: onRemoveReaction,
            onPostDeleted: (String) {},
            onPostUpdated: onPostUpdated);

    var page = CommentScreenV2(
      amityPost: post,
      theme: ThemeData(),
      isFromFeed: true,
      feedType: FeedType.community,
      eventStanding: eventStanding,
      event: event,
      match: match,
      matchResult: matchResult,
    );

    return GestureDetector(
      onTap: isPostDetail ||
          getGeneratePostType(post) == GeneratePostType.start_following_user ? null : () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => PopScope(
            canPop: true,
            child: page,
            onPopInvoked: (didPop) => {
              if (didPop)
                {
                  context
                      .read<GlobalFeedBloc>()
                      .add(GlobalFeedReloadThePost(post: post))
                }
            },
          ),
        ));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 10),
        decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Styles.grayD5D5D5, width: 1))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AmityPostHeader(
              post: post,
              theme: theme,
              action: postAction,
              matchResult: matchResult,
              match: match,
              event: event,
              eventStanding: eventStanding,
              followingUser: followingUser,
            ),
            getTextPostContent(post),
            // Add link preview if text post contains URL
            Builder(
              builder: (context) {
                final hasChildren = post.children?.isNotEmpty ?? false;
                // Only show link preview if post has no image/video children
                if (!hasChildren && post.data is TextData) {
                  return _getLinkPreview(context, post);
                }
                return const SizedBox();
              },
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: post.children?.isEmpty == true ? 0 : 4),
              child: getChildrenPostContent(context, post),
            ),
            // Add custom components for match, matchResult, event, eventStanding
            getMetadataComponents(context, post),
            getPostBottom(
                post: post, action: postAction, isReacting: isReacting),
          ],
        ),
      ),
    );
  }

  Widget getTextPostContent(AmityPost post) {
    final type = getGeneratePostType(post);
    if (type == GeneratePostType.event_created ||
        type == GeneratePostType.match_looking_for_players ||
        type == GeneratePostType.event_standing ||
        type == GeneratePostType.start_following_user ||
        type == GeneratePostType.level_up || 
        type == GeneratePostType.joined_event ||
        type == GeneratePostType.joined_match ||
        type == GeneratePostType.weekly_ranking) {

      return Container();
    }


    String textContent = "";
    if (post.data is TextData) {
      textContent = (post.data as TextData).text ?? "";
    }
    
    if (textContent.isEmpty) {
      return Container();
    }

    // Get mentions from post metadata
    final mentions = post.metadata?["mentions"] as List<dynamic>? ?? [];

    return Builder(
      builder: (context) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: mentions.isNotEmpty
              ? _buildTextWithMentions(context, textContent, mentions)
              : RichText(
                  text: TextSpan(
                    children: _buildTextSpansWithLinks(
                      textContent,
                      TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      TextStyle(
                        color: Styles.green,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.underline,
                      ),
                      context,
                    ),
                  ),
                ),
        );
      },
    );
  }

  /// Build text with mentions support
  Widget _buildTextWithMentions(BuildContext context, String text, List<dynamic> mentionsData) {
    final mentionsList = mentionsData
        .map((mention) => Mention(
              index: mention['index'] as int,
              length: mention['length'] as int,
              text: mention['text'] as String,
              userId: mention['userId'] as String,
            ))
        .toList();

    mentionsList.sort((a, b) => a.index.compareTo(b.index));

    return RichText(
      text: _buildMentionsTextSpan(
        context,
        text,
        mentionsList,
        TextStyle(
          color: theme.baseColor,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        TextStyle(
          color: Styles.green,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Build TextSpan with mentions highlighting
  TextSpan _buildMentionsTextSpan(
    BuildContext context,
    String currentText,
    List<Mention> mentionsList,
    TextStyle textStyle,
    TextStyle mentionStyle,
  ) {
    final List<InlineSpan> children = [];
    int currentPos = 0;

    for (var mention in mentionsList) {
      if (mention.index < currentPos || mention.index >= currentText.length) {
        continue;
      }

      // Add text before mention
      if (mention.index > currentPos) {
        final textSpans = _buildTextSpansWithLinks(
          currentText.substring(currentPos, mention.index),
          textStyle,
          TextStyle(
            color: Styles.green,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            decoration: TextDecoration.underline,
          ),
          context,
        );
        children.addAll(textSpans);
      }

      // Add mention text
      int mentionEnd = mention.index + mention.length;
      if (mentionEnd > currentText.length) {
        mentionEnd = currentText.length;
      }

      children.add(
        TextSpan(
          text: currentText.substring(mention.index, mentionEnd),
          style: mentionStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              _handleMentionTap(mention.userId);
            },
        ),
      );

      currentPos = mentionEnd;
    }

    // Add remaining text after last mention
    if (currentPos < currentText.length) {
      final textSpans = _buildTextSpansWithLinks(
        currentText.substring(currentPos),
        textStyle,
        TextStyle(
          color: Styles.green,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          decoration: TextDecoration.underline,
        ),
        context,
      );
      children.addAll(textSpans);
    }

    return TextSpan(children: children);
  }

  /// Build text spans with clickable links
  List<InlineSpan> _buildTextSpansWithLinks(
    String text,
    TextStyle textStyle,
    TextStyle linkStyle,
    BuildContext context,
  ) {
    final elements = linkify(text);

    return elements.map((element) {
      if (element is LinkableElement) {
        // Check if the URL contains deeplink host
        if (element.url.contains(deeplinkHost)) {
          // Return WidgetSpan for deeplink handling with loading state
          return WidgetSpan(
            child: Consumer<CommuFeedVM>(
              builder: (context, vm, _) {
                return InkWell(
                  onTap: () {
                    vm.setLoadingValue(true);
                    FlutterBranchSdk.handleDeepLink(element.url);
                    Future.delayed(Duration(seconds: 3), () {
                      vm.setLoadingValue(false);
                    });
                  },
                  child: Text(element.text, style: linkStyle),
                );
              },
            ),
          );
        } else {
          // Regular external link
          return TextSpan(
            text: element.text,
            style: linkStyle,
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _handleLinkTap(element.url);
              },
          );
        }
      } else {
        return TextSpan(
          text: element.text,
          style: textStyle,
        );
      }
    }).toList();
  }

  /// Handle mention tap - navigate to user profile
  void _handleMentionTap(String userId) {
    final parsedId = int.tryParse(userId);
    if (parsedId != null) {
      Get.to(() => PeopleProfileScreen(
            userId: parsedId,
            openFrom: OpenProfileFrom.community,
          ));
    }
  }

  /// Handle link tap
  Future<void> _handleLinkTap(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      print('Could not launch $url: $e');
    }
  }

  /// Extract link from post text
  String _extractLink(AmityPost post) {
    if (post.data is! TextData) return "";
    
    final textdata = post.data as TextData;
    final text = textdata.text ?? "";
    var elements = linkify(text,
        options: const LinkifyOptions(
          humanize: false,
          defaultToHttps: true,
        ));
    for (var e in elements) {
      if (e is LinkableElement) {
        return e.url;
      }
    }
    return "";
  }

  /// Check if post contains a valid URL
  bool _urlValidation(AmityPost post) {
    final url = _extractLink(post);
    return AnyLinkPreview.isValidLink(url);
  }

  /// Render link preview thumbnail
  Widget _getLinkPreview(BuildContext context, AmityPost post) {
    if (!_urlValidation(post)) {
      return const SizedBox();
    }

    final url = _extractLink(post);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Consumer<CommuFeedVM>(
        builder: (context, vm, _) {
          return LinkPreviewImage(
            url: url.toLowerCase(),
            onTap: () {
              vm.setLoadingValue(true);
              FlutterBranchSdk.handleDeepLink(url);
              Future.delayed(Duration(seconds: 3), () {
                vm.setLoadingValue(false);
              });
            },
          );
        },
      ),
    );
  }

  Widget getImagePostContent(List<ImageData> images) {
    final imageUrl = images.first.image?.getUrl(AmityImageSize.LARGE) ?? "";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Image.network(imageUrl),
      ),
    );
  }

  Widget getVideoPostContent(List<VideoData> images) {
    return Container();
  }

  Widget getChildrenPostContent(BuildContext context, AmityPost post) {
    final noChildrenPost = post.children?.isEmpty ?? true;
    if (noChildrenPost) {
      return Container();
    } else if (post.children!.first.data is ImageData) {
      return PostContentImage(posts: post.children!);
    } else if (post.children!.first.data is VideoData) {
      return PostContentVideo(posts: post.children!);
    } else {
      return Container();
    }
  }

  /// New method to render metadata components (match, matchResult, event, eventStanding)
  Widget getMetadataComponents(BuildContext context, AmityPost post) {

    final metadata = post.metadata;

    if (metadata == null) return Container();

    return Container(
      width: double.infinity,
      padding: metadata['eventId'] != null ? EdgeInsets.zero : const EdgeInsets.symmetric(
          horizontal: 20),
      child: Column(
        children: [
          // Match component
          if (metadata['matchId'] != null)
            match != null
                ? match!.status == MatchStatus.cancelled
                ? DeletedContentPlaceholder(
              type: DeletedContentType.match,
              margin: const EdgeInsets.symmetric(vertical: 12),
              subtitle: _formatMatchDateTime(match!),
            )
                :
            PostMatchItem(
                margin: EdgeInsets.only(top: 5),
                match: match!,
                onInvitePlayer: () {}
            )
                : Container(
              height: 100,
              alignment: Alignment.center,
              child: CupertinoActivityIndicator(color: Styles.green),
            ),

          // Match Result component
          if (metadata['matchResultId'] != null)
            matchResult != null
                ? matchResult!.status == MatchStatus.cancelled
                    ? DeletedContentPlaceholder(
                        type: DeletedContentType.matchResult,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        subtitle: _formatMatchDateTime(matchResult!),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ProfileScoreSetItem(
                          match: matchResult!,
                          buttonTitle: "",
                          onClickButton: (match) {},
                          isComplete: true,
                          hideAddDetails: true,
                        ),
                      )
                : Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: CupertinoActivityIndicator(color: Styles.green),
                ),

          // Event Standing component
          if (metadata['eventStandingId'] != null)
            eventStanding != null && eventStanding!.isNotEmpty
                ? eventStanding!.first.event.deleted == true
                    ? DeletedContentPlaceholder(
                        type: DeletedContentType.eventStanding,
                        margin: const EdgeInsets.only(top: 10),
                        subtitle:
                            '${eventStanding!.first.event.name}\n${_formatEventDateTime(eventStanding!.first.event)}',
                      )
                    : Padding(
                        padding: const EdgeInsets.only(top: 0.0),
                        child: Column(
                          children: [
                            _buildEventStandingTopRankings(eventStanding!),
                            // const SizedBox(height: 12),
                            // RankingLeaderboard(
                            //   leaderboardType: _getLeaderboardType(eventStanding!.first),
                            //   data: _convertEventStandingsToLeaderboardData(eventStanding!),
                            // ),
                          ],
                        ),
                      )
                : Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: CupertinoActivityIndicator(color: Styles.green),
                ),

          // Following user
          if (metadata['followingUserId'] != null && followingUser != null)
            FollowingUserPostItem(
                user: followingUser!,
                currentUser: currentUser
            ),
          if(metadata?['type'] == 'level_up')
            LeveledUpPostItem(user: post.postedUser,
                oldLevel: metadata?["oldLevel"] ?? 0,
                newLevel: metadata?["newLevel"] ?? 0),
          if (metadata['eventId'] != null && metadata?["type"] == "joined_event")
            event != null
                ? event!.deleted == true
                ? Padding(padding: EdgeInsets.symmetric(horizontal: 20),
                child: DeletedContentPlaceholder(
                  type: DeletedContentType.event,
                  margin: EdgeInsets.zero,
                  subtitle: '${event!.name}\n${_formatEventDateTime(event!)}',
                ))
                : PostEventItem(event: event!,
                communityName: (post.target as CommunityTarget).targetCommunity
                    ?.displayName ?? "",
                margin: EdgeInsets.only(top: 10))
                : SizedBox.shrink()

          // Event component
          else
            if (metadata['eventId'] != null)
              event != null
                  ? event!.deleted == true
                  ? Padding(padding: EdgeInsets.symmetric(horizontal: 20),
                  child: DeletedContentPlaceholder(
                    type: DeletedContentType.event,
                    margin: EdgeInsets.zero,
                    subtitle: '${event!.name}\n${_formatEventDateTime(event!)}',
                  ))
                  : PostEventItem(event: event!,
                  communityName: (post.target as CommunityTarget).targetCommunity
                      ?.displayName ?? "")
                  : SizedBox.shrink(),

          // Weekly Ranking component
          if (metadata?['type'] == 'weekly_ranking')
            communityRanking != null && communityRanking!.isNotEmpty
                ? CommunityRankingLeaderboard(
                isSharing: true,
                flexibleWidth: true,
                title: "${(post.target as CommunityTarget).targetCommunity?.displayName ??
                    ""} Rankings",
                community: (post.target as CommunityTarget).targetCommunity,
                data: communityRanking!.take(3).toList(),
                leaderboardType: LeaderboardType.team)
                : Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: CupertinoActivityIndicator(color: Styles.green),
                ),
        ],
      ),
    );
  }

  Widget getPostBottom(
      {required AmityPost post,
      required AmityPostAction action,
      bool isReacting = false}) {
    return PostItemBottom(
      post: post,
      action: action,
      isReacting: isReacting,
      componentId: '',
      isOptimisticUi: true,
      hideDivider: true
    );
  }

  // Helper methods from global_feed.dart
  String _formatMatchDateTime(IMatch match) {
    if (match.booking == null) return '';

    try {
      final startTime = match.booking!.getDateTime().toLocal();
      final endTime = match.booking!.getEndDateTime().toLocal();

      final dateFormat = 'EEE, dd MMM';
      final timeFormat = 'HH:mm';

      final datePart = _formatDate(startTime, dateFormat);
      final startTimePart = _formatDate(startTime, timeFormat);
      final endTimePart = _formatDate(endTime, timeFormat);

      return '$datePart $startTimePart - $endTimePart';
    } catch (e) {
      return '';
    }
  }

  String _formatEventDateTime(Event event) {
    try {
      final startTime = event.getStartDateTimeInLocal();
      final endTime = event.getEndDateTimeInLocal();

      final dateFormat = 'EEE, dd MMM';
      final timeFormat = 'HH:mm';

      final datePart = _formatDate(startTime, dateFormat);
      final startTimePart = _formatDate(startTime, timeFormat);
      final endTimePart = _formatDate(endTime, timeFormat);

      return '$datePart $startTimePart - $endTimePart';
    } catch (e) {
      return '';
    }
  }

  String _formatDate(DateTime date, String format) {
    if (format == 'EEE, dd MMM') {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final weekday = weekdays[date.weekday - 1];
      final day = date.day.toString().padLeft(2, '0');
      final month = months[date.month - 1];
      return '$weekday, $day $month';
    } else if (format == 'HH:mm') {
      final hour24 = date.hour;
      final period = hour24 >= 12 ? 'PM' : 'AM';
      final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour12:$minute $period';
    }
    return '';
  }

  LeaderboardType _getLeaderboardType(EventStanding standing) {
    final tournamentType = standing.event.tournamentType ?? 'americano';

    switch (tournamentType.toLowerCase()) {
      case 'mexicano':
        return LeaderboardType.mexicano;
      case 'teamamericano':
      case 'teammexicano':
        return LeaderboardType.team;
      case 'social':
        return LeaderboardType.social;
      default:
        return LeaderboardType.americano;
    }
  }

  DisplayUser _convertUserToDisplayUser(User user) {
    return DisplayUser(
      id: user.id,
      fullName: user.fullName,
      country: user.country,
      level: user.level,
      public: user.public,
      avatar: user.avatar,
      gender: user.gender,
      reliability: user.reliability,
    );
  }

  Widget _buildEventStandingTopRankings(List<EventStanding> standings) {
    if (standings.isEmpty) return const SizedBox();

    final tournamentType = standings.first.event.tournamentType ?? 'americano';
    final isTeam = tournamentType.toLowerCase() == 'teamamericano' ||
        tournamentType.toLowerCase() == 'teammexicano';

    final top3 = standings.take(3).toList();

    if (isTeam) {
      return Container(
        decoration: BoxDecoration(
          color: Styles.green20,
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (top3.isNotEmpty)
              TeamRankingAvatar(
                type: RankingAvatarType.first,
                players: [
                  _convertUserToDisplayUser(top3[0].user),
                  if (top3[0].partner != null) _convertUserToDisplayUser(top3[0].partner!),
                ],
                points: top3[0].points.toDouble(),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                if (top3.length > 1)
                  TeamRankingAvatar(
                    type: RankingAvatarType.second,
                    players: [
                      _convertUserToDisplayUser(top3[1].user),
                      if (top3[1].partner != null) _convertUserToDisplayUser(top3[1].partner!),
                    ],
                    points: top3[1].points.toDouble(),
                  ),
                if (top3.length > 2)
                  TeamRankingAvatar(
                    type: RankingAvatarType.third,
                    players: [
                      _convertUserToDisplayUser(top3[2].user),
                      if (top3[2].partner != null) _convertUserToDisplayUser(top3[2].partner!),
                    ],
                    points: top3[2].points.toDouble(),
                  ),
              ],
            ),
          ],
        ),
      );
    } else {
      final firstNationalityCode = Country.tryParse(top3.isNotEmpty ? top3[0].user.country ?? "" : "")?.countryCode;
      final secondNationalityCode = Country.tryParse(top3.length > 1 ? top3[1].user.country ?? "" : "")?.countryCode;
      final thirdNationalityCode = Country.tryParse(top3.length > 2 ? top3[2].user.country ?? "" : "")?.countryCode;

      return Container(
        decoration: BoxDecoration(
            color: HexColor("FDFBF9"),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(width: 1, color: Styles.level2)
        ),
        margin: EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          children: [
            Text('${eventStanding?.first?.event?.tournament?.toUpperCase()} WINNER',
                style: Styles.fontInterMedium(14, lineHeightInPxl: 21)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (top3.length > 1)
                  Column(
                    children: [
                      RankingAvatar(
                        type: RankingAvatarType.second,
                        avatarUrl: top3[1].user.avatar ?? '',
                        nationalityCode: secondNationalityCode,
                        fullName: top3[1].user.fullName,
                        borderSize: 2,
                        size: 56
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${top3[1].points} pts',
                        style: Styles.fontSFProSemiBold(14,
                            color: Styles.green, lineHeightInPxl: 24, letterSpacingInPercent: -2),
                      ),
                      Text(
                        top3[1].user.fullName?.split(' ').first ?? '',
                        style: Styles.fontSFProRegular(10,
                            letterSpacingInPercent: -2, color: Styles.trafficGrey, lineHeightInPxl: 20),
                      ),
                    ],
                  ),
                if (top3.isNotEmpty)
                  Column(
                    children: [
                      Container(
                        child: RankingAvatar(
                            borderSize: 2,
                            type: RankingAvatarType.first,
                            avatarUrl: top3[0].user.avatar ?? '',
                            nationalityCode: firstNationalityCode,
                            fullName: top3[0].user.fullName,
                            size: 71
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${top3[0].points} pts',
                        style: Styles.fontSFProSemiBold(14,
                            color: Styles.green, lineHeightInPxl: 24, letterSpacingInPercent: -2),
                      ),
                      Text(
                        top3[0].user.fullName?.split(' ').first ?? '',
                        style: Styles.fontSFProRegular(10,
                            letterSpacingInPercent: -2, color: Styles.trafficGrey, lineHeightInPxl: 20),
                      ),
                    ],
                  ),
                if (top3.length > 2)
                  Column(
                    children: [
                      RankingAvatar(
                        type: RankingAvatarType.third,
                        avatarUrl: top3[2].user.avatar ?? '',
                        nationalityCode: thirdNationalityCode,
                        fullName: top3[2].user.fullName,
                        borderSize: 2,
                        size: 56
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${top3[2].points} pts',
                        style: Styles.fontSFProSemiBold(14,
                            color: Styles.green, lineHeightInPxl: 24, letterSpacingInPercent: -2),
                      ),
                      Text(
                        top3[2].user.fullName?.split(' ').first ?? '',
                        style: Styles.fontSFProRegular(10,
                            letterSpacingInPercent: -2, color: Styles.trafficGrey, lineHeightInPxl: 20),
                      ),
                    ],
                  ),
              ],
            )
          ],
        ),
      );
    }
  }

  List<CommunityLeaderboardData> _convertEventStandingsToLeaderboardData(List<EventStanding> standings) {
    if (standings.isEmpty) return [];

    final tournamentType = standings.first.event.tournamentType ?? 'americano';
    final isTeam = tournamentType.toLowerCase() == 'teamamericano' ||
        tournamentType.toLowerCase() == 'teammexicano';

    if (isTeam) {
      return standings.map((standing) {
        return CommunityTeamLeaderboard(
          id: standing.id,
          userId: standing.userId,
          createdAt: standing.createdAt,
          updatedAt: standing.updatedAt,
          leaderboardType: 'team',
          periodStart: standing.createdAt,
          communityId: standing.event.communityId ?? '',
          periodEnd: standing.createdAt,
          points: standing.points,
          wins: standing.wins,
          ties: standing.ties,
          losses: standing.losses,
          pointsFor: standing.pointsFor,
          pointsAgainst: standing.pointsAgainst,
          tournamentType: tournamentType,
          partnerId: standing.partnerId,
          user: _convertUserToDisplayUser(standing.user),
          partner: standing.partner != null
              ? _convertUserToDisplayUser(standing.partner!)
              : _convertUserToDisplayUser(standing.user),
        );
      }).toList();
    } else {
      return standings.map((standing) {
        return CommunityPlayerLeaderboard(
          id: standing.id,
          userId: standing.userId,
          createdAt: standing.createdAt,
          updatedAt: standing.updatedAt,
          leaderboardType: tournamentType,
          periodStart: standing.createdAt,
          communityId: standing.event.communityId ?? '',
          periodEnd: standing.createdAt,
          points: standing.points,
          wins: standing.wins,
          ties: standing.ties,
          losses: standing.losses,
          pointsFor: standing.pointsFor,
          pointsAgainst: standing.pointsAgainst,
          tournamentType: tournamentType,
          user: _convertUserToDisplayUser(standing.user),
        );
      }).toList();
    }
  }

  String _formatEventType(String eventType) {
    switch (eventType) {
      case 'americano':
        return 'Americano';
      case 'mexicano':
        return 'Mexicano';
      case 'team':
        return 'Team';
      case 'teamAmericano':
        return 'Team Americano';
      case 'teamMexicano':
        return 'Team Mexicano';
      case 'social':
        return 'Social';
      default:
        return eventType.toUpperCase();
    }
  }

  String _formatDate2(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildRankingRow(CommunityRankingData ranking, int rank) {
    final isTeam = ranking.partnerId != null;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Styles.level2.withOpacity(0.3), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 30,
            child: Text(
              '#$rank',
              style: Styles.fontInterSemiBold(14, color: Styles.green),
            ),
          ),
          const SizedBox(width: 12),
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'User ${ranking.userId}',
                      style: Styles.fontInterMedium(14, lineHeightInPxl: 20),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${ranking.userLevel ?? 0})',
                      style: Styles.fontInterRegular(12, color: Styles.trafficGrey),
                    ),
                  ],
                ),
                if (isTeam && ranking.partnerId != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Partner ${ranking.partnerId}',
                        style: Styles.fontInterRegular(12, color: Styles.trafficGrey),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${ranking.partnerLevel ?? 0})',
                        style: Styles.fontInterRegular(12, color: Styles.trafficGrey),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${ranking.totalPoints} pts',
                style: Styles.fontInterBold(14, color: Styles.green),
              ),
              Text(
                '${ranking.win ?? 0}W ${ranking.second ?? 0}S',
                style: Styles.fontInterRegular(11, color: Styles.trafficGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _listMediaGrid(List<AmityPost> files) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: files.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        String fileImage = _getFileImage(files[index].data!.fileInfo.fileName!);

        return Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(
              color: theme.baseColorShade4,
              width: 1.0,
            ),
          ),
          margin: const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              ListTile(
                onTap: () {
                  _launchUrl(
                    files[index].data!.fileInfo.fileUrl!,
                  );
                },
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 8, horizontal: 14),
                tileColor: Colors.white.withOpacity(0.0),
                leading: Container(
                  height: 100,
                  width: 40,
                  alignment: Alignment.centerLeft,
                  child: Image(
                    image: AssetImage(fileImage,
                        package: 'amity_uikit_beta_service'),
                  ),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${files[index].data!.fileInfo.fileName}",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '${(files[index].data!.fileInfo.fileSize)} KB',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  String _getFileImage(String filePath) {
    String extension = filePath.split('.').last;
    switch (extension) {
      case 'audio':
        return 'assets/images/fileType/audio_small.png';
      case 'avi':
        return 'assets/images/fileType/avi_large.png';
      case 'csv':
        return 'assets/images/fileType/csv_large.png';
      case 'doc':
        return 'assets/images/fileType/doc_large.png';
      case 'exe':
        return 'assets/images/fileType/exe_large.png';
      case 'html':
        return 'assets/images/fileType/html_large.png';
      case 'img':
        return 'assets/images/fileType/img_large.png';
      case 'mov':
        return 'assets/images/fileType/mov_large.png';
      case 'mp3':
        return 'assets/images/fileType/mp3_large.png';
      case 'mp4':
        return 'assets/images/fileType/mp4_large.png';
      case 'pdf':
        return 'assets/images/fileType/pdf_large.png';
      case 'ppx':
        return 'assets/images/fileType/ppx_large.png';
      case 'rar':
        return 'assets/images/fileType/rar_large.png';
      case 'txt':
        return 'assets/images/fileType/txt_large.png';
      case 'xls':
        return 'assets/images/fileType/xls_large.png';
      case 'zip':
        return 'assets/images/fileType/zip_large.png';
      default:
        return 'assets/images/fileType/default.png';
    }
  }
}

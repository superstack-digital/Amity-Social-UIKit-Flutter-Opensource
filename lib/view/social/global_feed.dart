import 'dart:developer';

import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/components/alert_dialog.dart';
import 'package:amity_uikit_beta_service/components/post_profile.dart';
import 'package:amity_uikit_beta_service/components/reaction_button.dart';
import 'package:amity_uikit_beta_service/components/skeleton.dart';
import 'package:amity_uikit_beta_service/view/UIKit/social/community_setting/posts/edit_post_page.dart';
import 'package:amity_uikit_beta_service/view/UIKit/social/general_component.dart';
import 'package:amity_uikit_beta_service/view/UIKit/social/my_community_feed.dart';
import 'package:amity_uikit_beta_service/view/social/community_feedV2.dart';
import 'package:amity_uikit_beta_service/view/user/user_profile_v2.dart';
import 'package:amity_uikit_beta_service/viewmodel/my_community_viewmodel.dart';
import 'package:amity_uikit_beta_service/viewmodel/user_viewmodel.dart';
import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/custom_user_avatar.dart';
import '../../viewmodel/community_feed_viewmodel.dart';
import '../../viewmodel/configuration_viewmodel.dart';
import '../../viewmodel/edit_post_viewmodel.dart';
import '../../viewmodel/feed_viewmodel.dart';
import '../../viewmodel/post_viewmodel.dart';
import '../../viewmodel/user_feed_viewmodel.dart';
import 'comments.dart';
import 'post_content_widget.dart';
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


class GlobalFeedScreen extends StatefulWidget {
  final isShowMyCommunity;
  final bool canCreateCommunity;
  final bool isInit;

  const GlobalFeedScreen({
    super.key,
    this.isShowMyCommunity = true,
    this.canCreateCommunity = true,
    this.isInit = false,
    // this.isCustomPostRanking = false
  });

  @override
  GlobalFeedScreenState createState() => GlobalFeedScreenState();
}

class GlobalFeedScreenState extends State<GlobalFeedScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!widget.isInit) {
      Future.delayed(Duration.zero, () {
        var globalFeedProvider = Provider.of<FeedVM>(context, listen: false);
        var myCommunityList =
        Provider.of<MyCommunityVM>(context, listen: false);

        myCommunityList.initMyCommunityFeed();

        globalFeedProvider.initAmityGlobalfeed();
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    final mediaQuery = MediaQuery.of(context);
    final bHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        AppBar().preferredSize.height;

    final theme = Theme.of(context);
    return Consumer<FeedVM>(builder: (context, vm, _) {
      return RefreshIndicator(
        color: Provider
            .of<AmityUIConfiguration>(context)
            .primaryColor,
        onRefresh: () async {
          var globalFeedProvider = Provider.of<FeedVM>(context, listen: false);
          var myCommunityList =
          Provider.of<MyCommunityVM>(context, listen: false);

          myCommunityList.initMyCommunityFeed();

          globalFeedProvider.initAmityGlobalfeed(
            // isCustomPostRanking: widget.isCustomPostRanking
              isCustomPostRanking: false);
        },
        child: Container(
          color:
          Provider
              .of<AmityUIConfiguration>(context)
              .appColors
              .baseShade4,
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Container(
                      child: FadedSlideAnimation(
                        beginOffset: const Offset(0, 0.3),
                        endOffset: const Offset(0, 0),
                        slideCurve: Curves.linearToEaseOut,
                        child: ListView.builder(
                          // shrinkWrap: true,
                          controller: vm.scrollcontroller,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: vm.getAmityPosts.length,
                          itemBuilder: (context, index) {
                            print("HIHI");
                            return StreamBuilder<AmityPost>(
                              key: Key(vm.getAmityPosts[index].postId!),
                              stream: vm.getAmityPosts[index].listen.stream,
                              initialData: vm.getAmityPosts[index],
                              builder: (context, snapshot) {
                                final metadata = snapshot.data?.metadata;
                                final matchId = metadata?["matchId"];
                                final matchResultId = metadata?["matchResultId"];
                                final eventId = metadata?["eventId"];

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

                                return FutureBuilder<List<dynamic>>(
                                    future: Future.wait([
                                      _getMatchDetails(matchId),
                                      _getEventDetails(eventId),
                                      _getMatchResultDetails(matchResultId),
                                    ]),
                                    builder: (context, snapshot1) {
                                      final match = snapshot1.data?[0] as IMatch?;
                                      final event = snapshot1.data?[1] as Event?;
                                      final matchResult = snapshot1.data?[2] as IMatch?;

                                      return Column(
                                        children: [
                                          index != 0
                                              ? const SizedBox()
                                              : widget.isShowMyCommunity
                                              ? CommunityIconList(
                                            amityCommunites: Provider
                                                .of<
                                                MyCommunityVM>(context)
                                                .amityCommunitiesForFeed,
                                            canCreateCommunity:
                                            widget.canCreateCommunity,
                                          )
                                              : const SizedBox(),
                                          PostWidget(
                                            isPostDetail: false,
                                            match: match,
                                            matchResult: matchResult,
                                            event: event,
                                            // customPostRanking:
                                            //     widget.isCustomPostRanking,
                                            feedType: FeedType.global,
                                            showCommunity: true,
                                            showlatestComment: true,
                                            post: snapshot.data!,
                                            theme: theme,
                                            postIndex: index,
                                            isFromFeed: true,
                                          ),
                                        ],
                                      );
                                    });
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              vm.getAmityPosts.isEmpty
                  ? LoadingSkeleton(
                context: context,
              )
                  : vm.isLoading
                  ? vm.getAmityPosts.isEmpty
                  ? LoadingSkeleton(
                context: context,
              )
                  : const Text("")
                  : const Text("")
            ],
          ),
        ),
      );
    });
  }
}

enum FeedType { user, community, global, pending }

class PostWidget extends StatefulWidget {
  const PostWidget({
    Key? key,
    required this.post,
    required this.theme,
    required this.postIndex,
    this.isFromFeed = false,
    required this.showlatestComment,
    required this.feedType,
    required this.showCommunity,
    this.showAcceptOrRejectButton = false,
    required this.isPostDetail,
    this.match,
    this.matchResult,
    this.event,
    this.eventStanding
  }) : super(key: key);
  final FeedType feedType;
  final AmityPost post;
  final ThemeData theme;
  final int postIndex;
  final bool isFromFeed;
  final bool showlatestComment;
  final bool showCommunity;
  final bool showAcceptOrRejectButton;
  final bool isPostDetail;
  final IMatch? match;
  final IMatch? matchResult;
  final Event? event;
  final List<EventStanding>? eventStanding;

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> // with AutomaticKeepAliveClientMixin
    {
  double iconSize = 16;
  double feedReactionCountSize = 16;

  Widget postWidgets() {
    List<Widget> widgets = [];
    if (widget.post.data != null) {
      widgets
          .add(AmityPostWidget([widget.post], false, false, widget.feedType));
    }
    final childrenPosts = widget.post.children;
    if (childrenPosts != null && childrenPosts.isNotEmpty) {
      widgets.add(AmityPostWidget(childrenPosts, true, true, widget.feedType));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
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

    // Get top 3
    final top3 = standings.take(3).toList();

    if (isTeam) {
      // Team ranking - show team avatars
      return Container(
        decoration: BoxDecoration(
          color: Styles.green20,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1st place - first row
            if (top3.isNotEmpty)
              TeamRankingAvatar(
                type: RankingAvatarType.first,
                players: [
                  _convertUserToDisplayUser(top3[0].user),
                  if (top3[0].partner != null) _convertUserToDisplayUser(top3[0].partner!),
                ],
                points: top3[0].points.toDouble(),
              ),
            // 2nd and 3rd place - second row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 2nd place
                if (top3.length > 1)
                  TeamRankingAvatar(
                    type: RankingAvatarType.second,
                    players: [
                      _convertUserToDisplayUser(top3[1].user),
                      if (top3[1].partner != null) _convertUserToDisplayUser(top3[1].partner!),
                    ],
                    points: top3[1].points.toDouble(),
                  ),
                // 3rd place
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
      // Player ranking - show individual avatars in single row
      final firstNationalityCode = Country.tryParse(top3.isNotEmpty ? top3[0].user.country ?? "" : "")?.countryCode;
      final secondNationalityCode = Country.tryParse(top3.length > 1 ? top3[1].user.country ?? "" : "")?.countryCode;
      final thirdNationalityCode = Country.tryParse(top3.length > 2 ? top3[2].user.country ?? "" : "")?.countryCode;

      return Container(
        decoration: BoxDecoration(
          color: Styles.green20,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 2nd place
            if (top3.length > 1)
              Column(
                children: [
                  RankingAvatar(
                    type: RankingAvatarType.second,
                    avatarUrl: top3[1].user.avatar ?? '',
                    nationalityCode: secondNationalityCode,
                    fullName: top3[1].user.fullName,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${top3[1].points} pts',
                    style: Styles.fontSFProSemiBold(14,
                        color: Styles.green,
                        lineHeightInPxl: 24,
                        letterSpacingInPercent: -2),
                  ),
                  Text(
                    top3[1].user.fullName?.split(' ').first ?? '',
                    style: Styles.fontSFProRegular(10,
                        letterSpacingInPercent: -2,
                        color: Styles.trafficGrey,
                        lineHeightInPxl: 20),
                  ),
                ],
              ),
            // 1st place
            if (top3.isNotEmpty)
              Column(
                children: [
                  RankingAvatar(
                    type: RankingAvatarType.first,
                    avatarUrl: top3[0].user.avatar ?? '',
                    nationalityCode: firstNationalityCode,
                    fullName: top3[0].user.fullName,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${top3[0].points} pts',
                    style: Styles.fontSFProSemiBold(14,
                        color: Styles.green,
                        lineHeightInPxl: 24,
                        letterSpacingInPercent: -2),
                  ),
                  Text(
                    top3[0].user.fullName?.split(' ').first ?? '',
                    style: Styles.fontSFProRegular(10,
                        letterSpacingInPercent: -2,
                        color: Styles.trafficGrey,
                        lineHeightInPxl: 20),
                  ),
                ],
              ),
            // 3rd place
            if (top3.length > 2)
              Column(
                children: [
                  RankingAvatar(
                    type: RankingAvatarType.third,
                    avatarUrl: top3[2].user.avatar ?? '',
                    nationalityCode: thirdNationalityCode,
                    fullName: top3[2].user.fullName,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${top3[2].points} pts',
                    style: Styles.fontSFProSemiBold(14,
                        color: Styles.green,
                        lineHeightInPxl: 24,
                        letterSpacingInPercent: -2),
                  ),
                  Text(
                    top3[2].user.fullName?.split(' ').first ?? '',
                    style: Styles.fontSFProRegular(10,
                        letterSpacingInPercent: -2,
                        color: Styles.trafficGrey,
                        lineHeightInPxl: 20),
                  ),
                ],
              ),
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

  Widget postOptions(BuildContext context) {
    bool isPostOwner =
        widget.post.postedUserId == AmityCoreClient
            .getCurrentUser()
            .userId;
    final isFlaggedByMe = widget.post.isFlaggedByMe;
    List<String> postOwnerMenu = ['Edit Post', 'Delete Post', 'Share Post'];
    List<String> otherPostMenu = [
      isFlaggedByMe ? 'Unreport Post' : 'Report Post', 'Share Post'
      // 'Block User'
    ];

    return IconButton(
      icon: Icon(
        Icons.more_horiz_rounded,
        size: 24,
        color: widget.feedType == FeedType.user
            ? Provider
            .of<AmityUIConfiguration>(context)
            .appColors
            .userProfileTextColor
            : Colors.grey,
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return Container(
              decoration: BoxDecoration(
                color: Provider
                    .of<AmityUIConfiguration>(context)
                    .appColors
                    .baseBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.only(
                  top: 16, left: 16, right: 16, bottom: 32),
              child: Wrap(
                children: [
                  if (isPostOwner)
                    ...postOwnerMenu.map((option) =>
                        ListTile(
                          title: Text(
                            option,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            handleMenuOption(context, option, isFlaggedByMe);
                          },
                        )),
                  if (!isPostOwner)
                    ...otherPostMenu.map((option) =>
                        ListTile(
                          title: Text(
                            option,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            handleMenuOption(context, option, isFlaggedByMe);
                          },
                        )),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void handleMenuOption(_, String option, bool isFlaggedByMe) {
    switch (option) {
      case 'Report Post':
      case 'Unreport Post':
        log("isflag by me $isFlaggedByMe");
        if (isFlaggedByMe) {
          Provider.of<PostVM>(context, listen: false).unflagPost(widget.post);
        } else {
          Provider.of<PostVM>(context, listen: false).flagPost(widget.post);
        }
        break;
      case 'Edit Post':
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) =>
                ChangeNotifierProvider<EditPostVM>(
                    create: (context) => EditPostVM(),
                    child: AmityEditPostScreen(
                      amityPost: widget.post,
                    ))));
        break;
      case 'Delete Post':
        showDeleteConfirmationDialog(context);
        break;
      case 'Share Post':
        {
          handleShareContent(
              metadata: {"type": "communityPost", "postId": widget.post.postId ?? ""},
              title: "Join Community",
              shouldShare: true,
              description: "Let's join our match to play together");
          break;
        }
      case 'Block User':
        Provider.of<UserVM>(context, listen: false)
            .blockUser(widget.post.postedUserId!, () {
          if (widget.feedType == FeedType.global) {
            Provider.of<FeedVM>(context, listen: false).reload();
          } else if (widget.feedType == FeedType.community) {
            Provider.of<CommuFeedVM>(context, listen: false)
                .initAmityCommunityFeed(
                (widget.post.target as CommunityTarget).targetCommunityId!);
          }
        });
        break;
      default:
    }
  }

  void showDeleteConfirmationDialog(BuildContext context) {
    ConfirmationDialog().show(
      context: context,
      title: 'Delete Post?',
      detailText: 'Do you want to Delete your post?',
      leftButtonText: 'Cancel',
      rightButtonText: 'Delete',
      onConfirm: () {
        if (widget.feedType == FeedType.global) {
          Provider.of<FeedVM>(context, listen: false)
              .deletePost(widget.post, widget.postIndex, (isSuccess, error) {
            if (isSuccess && widget.isPostDetail) {
              Navigator.of(context).pop();
            }
          });
        } else if (widget.feedType == FeedType.community) {
          Provider.of<CommuFeedVM>(context, listen: false)
              .deletePost(widget.post, widget.postIndex, (isSuccess, error) {
            if (isSuccess && widget.isPostDetail) {
              Navigator.of(context).pop();
            }
          });
        } else if (widget.feedType == FeedType.user) {
          Provider.of<UserFeedVM>(context, listen: false)
              .deletePost(widget.post, (isSuccess, error) {
            if (isSuccess && widget.isPostDetail) {
              Navigator.of(context).pop();
            }
          });
        } else if (widget.feedType == FeedType.pending) {
          Provider.of<CommuFeedVM>(context, listen: false)
              .deletePendingPost(widget.post, widget.postIndex);
        } else {
          print("unhandled postType");
        }
      },
    );
  }

  // @override
  @override
  Widget build(BuildContext context) {
    final matchId = widget.post.metadata?["matchId"];
    return Column(
      children: [
        GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              if (widget.isFromFeed) {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        CommentScreen(
                          amityPost: widget.post,
                          theme: widget.theme,
                          isFromFeed: true,
                          feedType: widget.feedType,
                          match: widget.match,
                          matchResult: widget.matchResult,
                          event: widget.event,
                          eventStanding: widget.eventStanding,
                        )));
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 0),
              color: Provider
                  .of<AmityUIConfiguration>(context)
                  .appColors
                  .baseBackground,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                  children: [
                    Container(
                      child: ListTile(
                        contentPadding: const EdgeInsets.only(
                            left: 0, top: 0, right: 0, bottom: 0),
                        leading: FadeAnimation(
                            child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                      //     ChangeNotifierProvider(
                                      //   create: (context) => UserFeedVM(),
                                      //   child: UserProfileScreen(
                                      //     amityUser: widget.post.postedUser!,
                                      //     amityUserId:
                                      //         widget.post.postedUser!.userId!,
                                      //   ),
                                      // ),
                                      PeopleProfileScreen(
                                        userId: int.tryParse(
                                            widget.post.postedUser!.userId!) ?? 0,
                                        openFrom: OpenProfileFrom.community,
                                      ),
                                    ),
                                  );
                                },
                                child: getAvatarImage(widget
                                    .post.postedUser!.userId !=
                                    AmityCoreClient
                                        .getCurrentUser()
                                        .userId
                                    ? widget.post.postedUser?.avatarUrl ??
                                    widget.post.postedUser?.avatarCustomUrl
                                    : AmityCoreClient
                                    .getCurrentUser()
                                    .avatarUrl ?? AmityCoreClient
                                    .getCurrentUser()
                                    .avatarCustomUrl,
                                    fullName: widget
                                        .post.postedUser!.userId !=
                                        AmityCoreClient
                                            .getCurrentUser()
                                            .userId
                                        ? widget.post.postedUser?.displayName
                                        : AmityCoreClient
                                        .getCurrentUser()
                                        .displayName))),
                        title: Wrap(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                    //     ChangeNotifierProvider(
                                    //   create: (context) => UserFeedVM(),
                                    //   child: UserProfileScreen(
                                    //       amityUser: widget.post.postedUser!,
                                    //       amityUserId:
                                    //           widget.post.postedUser!.userId!),
                                    // ),
                                    PeopleProfileScreen(
                                      userId: int.tryParse(
                                          widget.post.postedUser!.userId!) ?? 0,
                                      openFrom: OpenProfileFrom.community,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                widget.post.postedUser!.userId !=
                                    AmityCoreClient
                                        .getCurrentUser()
                                        .userId
                                    ? widget.post.postedUser?.displayName ??
                                    "Display name"
                                    : AmityCoreClient
                                    .getCurrentUser()
                                    .displayName ??
                                    "",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Provider
                                        .of<AmityUIConfiguration>(
                                        context)
                                        .appColors
                                        .base),
                              ),
                            ),
                            widget.showCommunity &&
                                widget.post.targetType ==
                                    AmityPostTargetType.COMMUNITY
                                ? Icon(
                              Icons.arrow_right_rounded,
                              color: Provider
                                  .of<AmityUIConfiguration>(
                                  context)
                                  .appColors
                                  .base,
                            )
                                : Container(),
                            widget.showCommunity &&
                                widget.post.targetType ==
                                    AmityPostTargetType.COMMUNITY
                                ? GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            ChangeNotifierProvider(
                                              create: (context) =>
                                                  CommuFeedVM(),
                                              child: CommunityScreen(
                                                isFromFeed: true,
                                                community: (widget
                                                    .post.target
                                                as CommunityTarget)
                                                    .targetCommunity!,
                                              ),
                                            )));
                              },
                              child: Text(
                                (widget.post.target as CommunityTarget)
                                    .targetCommunity!
                                    .displayName ??
                                    "Community name",
                                style: widget.theme.textTheme.bodyLarge!
                                    .copyWith(
                                  color:
                                  Provider
                                      .of<AmityUIConfiguration>(
                                      context)
                                      .appColors
                                      .base,
                                  overflow: TextOverflow.ellipsis,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            )
                                : Container()
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            TimeAgoWidget(
                              createdAt: widget.post.createdAt!,
                              textColor: widget.feedType == FeedType.user
                                  ? Provider
                                  .of<AmityUIConfiguration>(context)
                                  .appColors
                                  .userProfileTextColor
                                  : Colors.grey,
                            ),
                            widget.post.editedAt != widget.post.createdAt
                                ? Row(
                              children: [
                                const SizedBox(
                                  width: 4,
                                ),
                                Icon(
                                  Icons.circle,
                                  size: 4,
                                  color: widget.feedType == FeedType.user
                                      ? Provider
                                      .of<AmityUIConfiguration>(
                                      context)
                                      .appColors
                                      .userProfileTextColor
                                      : Colors.grey,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text("Edited",
                                    style: TextStyle(
                                      color: widget.feedType ==
                                          FeedType.user
                                          ? Provider
                                          .of<
                                          AmityUIConfiguration>(
                                          context)
                                          .appColors
                                          .userProfileTextColor
                                          : Colors.grey,
                                    )),
                              ],
                            )
                                : const SizedBox()
                          ],
                        ),
                        trailing: widget.feedType == FeedType.pending &&
                            widget.post.postedUser!.userId !=
                                AmityCoreClient
                                    .getCurrentUser()
                                    .userId
                            ? null
                            : Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Image.asset(
                            //   'assets/Icons/ic_share.png',
                            //   scale: 3,
                            // ),
                            // SizedBox(width: iconSize.feedIconSize),
                            // Icon(
                            //   Icons.bookmark_border,
                            //   size: iconSize.feedIconSize,
                            //   color: ApplicationColors.grey,
                            // ),
                            // SizedBox(width: iconSize.feedIconSize),
                            postOptions(context),
                          ],
                        ),
                      ),
                    ),
                    postWidgets(),
                    if(matchId != null)
                      if(widget.match != null)
                        CourtMatchItem(
                            margin: EdgeInsets.zero,
                            match: widget.match!, onInvitePlayer: () {}) else
                        CircularProgressIndicator(color: Styles.green),
                    if(widget.post.metadata?["matchResultId"] != null)
                      if(widget.matchResult != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: ProfileScoreSetItem(
                            match: widget.matchResult!,
                            buttonTitle: "",
                            onClickButton: (match) {},
                            isComplete: true,
                            hideAddDetails: true,
                          ),
                        ) else
                        CircularProgressIndicator(color: Styles.green),
                    if(widget.post.metadata?["eventId"] != null)
                      if(widget.event != null)
                        UpcomingEventItem(
                            data: widget.event!,
                            margin: EdgeInsets.zero) else
                        CircularProgressIndicator(color: Styles.green),
                    if(widget.post.metadata?["eventStandingId"] != null)
                      if(widget.eventStanding != null && widget.eventStanding!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            children: [
                              _buildEventStandingTopRankings(widget.eventStanding!),
                              const SizedBox(height: 12),
                              RankingLeaderboard(
                                leaderboardType: _getLeaderboardType(widget.eventStanding!.first),
                                data: _convertEventStandingsToLeaderboardData(widget.eventStanding!),
                              ),
                            ],
                          ),
                        ) else
                        CircularProgressIndicator(color: Styles.green),
                    widget.feedType == FeedType.pending
                        ? const SizedBox()
                        : Container(
                      child: Padding(
                          padding: const EdgeInsets.only(
                              top: 16, bottom: 16, left: 0, right: 0),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Builder(builder: (context) {
                                return widget.post.reactionCount! > 0
                                    ? Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Provider
                                          .of<
                                          AmityUIConfiguration>(
                                          context)
                                          .primaryColor,
                                      child: const Icon(
                                        Icons.thumb_up,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                        widget.post.reactionCount
                                            .toString(),
                                        style: TextStyle(
                                            color: widget
                                                .feedType ==
                                                FeedType.user
                                                ? Provider
                                                .of<
                                                AmityUIConfiguration>(
                                                context)
                                                .appColors
                                                .userProfileTextColor
                                                : Colors.grey,
                                            fontSize:
                                            feedReactionCountSize,
                                            letterSpacing: 1)),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                        widget.post.reactionCount! >
                                            1
                                            ? "likes"
                                            : "like",
                                        style: TextStyle(
                                            color: widget
                                                .feedType ==
                                                FeedType.user
                                                ? Provider
                                                .of<
                                                AmityUIConfiguration>(
                                                context)
                                                .appColors
                                                .userProfileTextColor
                                                : Colors.grey,
                                            fontSize:
                                            feedReactionCountSize,
                                            letterSpacing: 1)),
                                  ],
                                )
                                    : const SizedBox(
                                  width: 0,
                                );
                              }),
                              Builder(builder: (context) {
                                // any logic needed...
                                if (widget.post.commentCount! > 1) {
                                  return Text(
                                    '${widget.post.commentCount} comments',
                                    style: TextStyle(
                                        color: widget.feedType ==
                                            FeedType.user
                                            ? Provider
                                            .of<
                                            AmityUIConfiguration>(
                                            context)
                                            .appColors
                                            .userProfileTextColor
                                            : Colors.grey,
                                        fontSize: feedReactionCountSize,
                                        letterSpacing: 0.5),
                                  );
                                } else if (widget.post.commentCount! ==
                                    0) {
                                  return const SizedBox(
                                    width: 0,
                                  );
                                } else {
                                  return Text(
                                    '${widget.post.commentCount} comment',
                                    style: TextStyle(
                                        color: widget.feedType ==
                                            FeedType.user
                                            ? Provider
                                            .of<
                                            AmityUIConfiguration>(
                                            context)
                                            .appColors
                                            .userProfileTextColor
                                            : Colors.grey,
                                        fontSize: feedReactionCountSize,
                                        letterSpacing: 0.5),
                                  );
                                }
                              })
                            ],
                          )),
                    ),
                    Divider(
                      color: widget.feedType == FeedType.user
                          ? Provider
                          .of<AmityUIConfiguration>(context)
                          .appColors
                          .userProfileTextColor
                          : Color(0xFFEBECEF),
                      height: 1,
                    ),
                    // const SizedBox(
                    //   height: 7,
                    // ),
                    widget.feedType == FeedType.pending
                        ? widget.showAcceptOrRejectButton
                        ? PendingSectionButton(
                      postId: widget.post.postId!,
                      communityId:
                      (widget.post.target as CommunityTarget)
                          .targetCommunityId!,
                    )
                        : const SizedBox()
                        : Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ReactionWidget(
                              post: widget.post,
                              feedType: widget.feedType,
                              feedReactionCountSize:
                              feedReactionCountSize),

                          GestureDetector(
                            onTap: () {
                              if (widget.isFromFeed) {
                                Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            CommentScreen(
                                              amityPost: widget.post,
                                              theme: widget.theme,
                                              isFromFeed: true,
                                              feedType: widget.feedType,
                                              match: widget.match,
                                              matchResult: widget.matchResult,
                                              event: widget.event,
                                              eventStanding: widget.eventStanding,
                                            )));
                              }
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Provider
                                    .of<AmityUIConfiguration>(context)
                                    .iconConfig
                                    .commentIcon(),
                                const SizedBox(width: 5.5),
                                Text(
                                  'Comment',
                                  style: TextStyle(
                                      color: Provider
                                          .of<
                                          AmityUIConfiguration>(
                                          context)
                                          .appColors
                                          .userProfileIconColor,
                                      fontSize: feedReactionCountSize,
                                      letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          GestureDetector(
                            onTap: () {
                                handleShareContent(
                                    metadata: {"type": "communityPost", "postId": widget.post.postId ?? ""},
                                    title: "Join Community",
                                    shouldShare: true,
                                    description: "Let's join our match to play together");
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Provider
                                    .of<AmityUIConfiguration>(context)
                                    .iconConfig
                                    .shareIcon(),
                                const SizedBox(width: 5.5),
                                Text(
                                  'Share',
                                  style: TextStyle(
                                      color: Provider
                                          .of<
                                          AmityUIConfiguration>(
                                          context)
                                          .appColors
                                          .userProfileIconColor,
                                      fontSize: feedReactionCountSize,
                                      letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Divider(),
                    // CommentComponent(
                    //     key: Key(widget.post.postId!),
                    //     postId: widget.post.postId!,
                    //     theme: widget.theme)
                  ],
                ),
              ),
            )),
        widget.post.latestComments == null
            ? const SizedBox()
            : !widget.showlatestComment
            ? const SizedBox()
            : Container(
            color: Provider
                .of<AmityUIConfiguration>(context)
                .appColors
                .baseBackground,
            child: Divider(
              color: widget.feedType == FeedType.user
                  ? Provider
                  .of<AmityUIConfiguration>(context)
                  .appColors
                  .userProfileTextColor
                  : Color(0xFFEBECEF),
              height: 0,
            )),
        // widget.isFromFeed
        //     ? const SizedBox()
        //     : Container(
        //         color: Colors.white,
        //         child: const Divider(
        //           color: Colors.grey,
        //           height: 0,
        //         )),

        !widget.showlatestComment
            ? const SizedBox()
            : widget.post.latestComments == null
            ? const SizedBox()
            : widget.post.latestComments!.isEmpty
            ? const SizedBox()
            : Container(
          color: Provider
              .of<AmityUIConfiguration>(context)
              .appColors
              .baseBackground,
          child: LatestCommentComponent(
            feedType: widget.feedType,
            postId: widget.post.data!.postId,
            comments: widget.post.latestComments!,
          ),
        ),

        !widget.isFromFeed
            ? const SizedBox()
            : const SizedBox(
          height: 8,
        )
      ],
    );
  }

// @override
// bool get wantKeepAlive {
//   final childrenPosts = widget.post.children;
//   if (childrenPosts != null && childrenPosts.isNotEmpty) {
//     if (childrenPosts[0].data is VideoData) {
//       log("keep ${childrenPosts[0].parentPostId} alive");
//       return true;
//     } else {
//       return true;
//     }
//   } else {
//     return false;
//   }
// }
}

class PendingSectionButton extends StatelessWidget {
  final String postId;
  final String communityId;

  const PendingSectionButton(
      {super.key, required this.postId, required this.communityId});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 11,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Provider.of<CommuFeedVM>(context, listen: false).acceptPost(
                    postId: postId,
                    communityId: communityId,
                    callback: (isSuccess) {},
                  );
                },
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                    Provider
                        .of<AmityUIConfiguration>(context)
                        .primaryColor,
                    borderRadius: BorderRadius.circular(4), // Set border radius
                  ),
                  child: const Center(
                      child: Text("Accept",
                          style: TextStyle(
                              color: Colors.white))), // Text color set to white
                ),
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Provider.of<CommuFeedVM>(context, listen: false).declinePost(
                    postId: postId,
                    communityId: communityId,
                    callback: (isSuccess) {},
                  );
                },
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white, // Decline button background color
                    borderRadius: BorderRadius.circular(4), // Set border radius
                    border: Border.all(color: Colors.grey), // Border color
                  ),
                  child: const Center(
                      child: Text("Decline")), // Text with default color
                ),
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 12,
        ),
      ],
    );
  }
}

class LatestCommentComponent extends StatefulWidget {
  const LatestCommentComponent({
    Key? key,
    required this.postId,
    required this.comments,
    required this.feedType,
    this.textColor,
  }) : super(key: key);
  final FeedType feedType;
  final String postId;

  final List<AmityComment> comments;
  final Color? textColor;

  @override
  State<LatestCommentComponent> createState() => _LatestCommentComponentState();
}

class _LatestCommentComponentState extends State<LatestCommentComponent> {
  @override
  void initState() {
    super.initState();
  }

  bool isLiked(AsyncSnapshot<AmityComment> snapshot) {
    var comments = snapshot.data!;
    return comments.myReactions?.isNotEmpty ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PostVM>(builder: (context, vm, _) {
      return ListView.builder(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: widget.comments.length,
        itemBuilder: (context, index) {
          return StreamBuilder<AmityComment>(
            key: Key(widget.comments[index].commentId!),
            stream: widget.comments[index].listen.stream,
            initialData: widget.comments[index],
            builder: (context, snapshot) {
              var comments = snapshot.data!;
              var commentData = comments.data as CommentTextData;

              return index > 1
                  ? const SizedBox()
                  : comments.isDeleted!
                  ? Container(
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(9.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14,
                          ),
                          Icon(
                            Icons.remove_circle_outline,
                            size: 15,
                            color: Color(0xff636878),
                          ),
                          SizedBox(
                            width: 14,
                          ),
                          Text(
                            "This comment  has been deleted",
                            style: TextStyle(
                                color: Color(0xff636878),
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 0,
                    )
                  ],
                ),
              )
                  : Column(
                children: [
                  Container(
                    color: widget.feedType == FeedType.user
                        ? Provider
                        .of<AmityUIConfiguration>(context)
                        .appColors
                        .userProfileBGColor
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 0, horizontal: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(
                              top: 14, left: 16, bottom: 8),
                          child: CustomListTile(
                              avatarUrl: comments.user!.avatarUrl ??
                                  comments.user!.avatarCustomUrl,
                              displayName:
                              comments.user!.displayName!,
                              createdAt: comments.createdAt!,
                              editedAt: comments.editedAt!,
                              userId: comments.user!.userId!,
                              user: comments.user!),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          margin: const EdgeInsets.only(
                              left: 70.0, right: 18),
                          decoration: BoxDecoration(
                            color: Provider
                                .of<AmityUIConfiguration>(
                                context)
                                .appColors
                                .baseShade4,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                            ),
                          ),
                          child: Consumer<CommuFeedVM>(builder: (context, vm, _){
                            return RichTextWithMentions(
                                mentionColor: Styles.green,
                                fullText: commentData.text!,
                                mentions: comments.metadata?["mentions"] !=
                                    null ? (comments.metadata!["mentions"] as List<dynamic>)
                                    .map((e) => Mention.fromJson(e)).toList() : [],
                                isOpponent: true,
                                onLinkClicked: (_){
                                  print("Link clicked: $_");
                                  vm.addLoadingTime();
                                },
                                onMentionTap: (userId) {
                                  final parsedId = int.tryParse(userId);
                                  if (parsedId != null) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            PeopleProfileScreen(
                                              userId: parsedId,
                                              openFrom:
                                              OpenProfileFrom.community,
                                            ),
                                      ),
                                    );
                                  }
                                },
                                textColor: Provider
                                    .of<AmityUIConfiguration>(
                                    context)
                                    .appColors
                                    .base);
                          }),
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        CommentActionComponent(
                            amityComment: comments),
                        const SizedBox(
                          height: 16,
                        ),
                      ],
                    ),
                  ),
                  // const Divider(
                  //   height: 0,
                  // ),
                ],
              );
            },
          );
        },
      );
    });
  }
}

class CommentActionComponent extends StatelessWidget {
  const CommentActionComponent({
    super.key,
    required this.amityComment,
  });

  final AmityComment amityComment;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AmityComment>(
        stream: amityComment.listen.stream,
        initialData: amityComment,
        builder: (context, snapshot) {
          var comments = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.only(left: 70.0, top: 5.0),
            child: Row(
              children: [
                // Like Button
                comments.myReactions == null
                    ? GestureDetector(
                  onTap: () {
                    Provider.of<PostVM>(context, listen: false)
                        .addCommentReaction(comments);
                  },
                  child: Row(
                    children: [
                      Provider
                          .of<AmityUIConfiguration>(context)
                          .iconConfig
                          .likeIcon(),
                      snapshot.data!.reactionCount! > 0
                          ? Text(
                        " ${snapshot.data!.reactionCount!}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff898E9E),
                        ),
                      )
                          : const Text(
                        " Like",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff898E9E),
                        ),
                      ),
                    ],
                  ),
                )
                    : comments.myReactions!.isEmpty
                    ? GestureDetector(
                  onTap: () {
                    Provider.of<PostVM>(context, listen: false)
                        .addCommentReaction(comments);
                  },
                  child: Row(
                    children: [
                      Provider
                          .of<AmityUIConfiguration>(context)
                          .iconConfig
                          .likeIcon(),
                      snapshot.data!.reactionCount! > 0
                          ? Text(
                        " ${snapshot.data!.reactionCount!}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff898E9E),
                        ),
                      )
                          : const Text(
                        " Like",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff898E9E),
                        ),
                      ),
                    ],
                  ),
                )
                    : GestureDetector(
                    onTap: () {
                      print("addCommentReaction");
                      Provider.of<PostVM>(context, listen: false)
                          .removeCommentReaction(comments);
                    },
                    child: Row(
                      children: [
                        Provider
                            .of<AmityUIConfiguration>(context)
                            .iconConfig
                            .likedIcon(
                            color:
                            Provider
                                .of<AmityUIConfiguration>(
                                context)
                                .primaryColor),
                        Text(
                          " ${snapshot.data?.reactionCount ?? 0}",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Provider
                                  .of<AmityUIConfiguration>(
                                  context)
                                  .appColors
                                  .primary),
                        ),
                      ],
                    )),

                // const SizedBox(width: 10),
                // // Reply Button
                // Provider.of<AmityUIConfiguration>(
                //         context)
                //     .iconConfig
                //     .replyIcon(),

                // const Text(
                //   "Reply",
                //   style: TextStyle(
                //     color: Color(0xff898E9E),
                //   ),
                // ),

                // More Options Button
                const SizedBox(
                  width: 10,
                ),
                GestureDetector(
                  child: const Icon(
                    Icons.more_horiz,
                    color: Color(0xff898E9E),
                  ),
                  onTap: () {
                    AmityGeneralCompomemt.showOptionsBottomSheet(context, [
                      comments.user?.userId! ==
                          AmityCoreClient
                              .getCurrentUser()
                              .userId
                          ? const SizedBox()
                          : ListTile(
                        title: const Text(
                          'Report',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                        },
                      ),

                      ///check admin
                      comments.user?.userId! !=
                          AmityCoreClient
                              .getCurrentUser()
                              .userId
                          ? const SizedBox()
                          : ListTile(
                        title: const Text(
                          'Edit Comment',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) =>
                                  EditCommentPage(
                                    feedType: FeedType.user,
                                    initailText:
                                    (comments.data as CommentTextData)
                                        .text!,
                                    comment: comments,
                                    postCallback: () async {},
                                  )));
                        },
                      ),
                      comments.user?.userId! !=
                          AmityCoreClient
                              .getCurrentUser()
                              .userId
                          ? const SizedBox()
                          : ListTile(
                        title: const Text(
                          'Delete Comment',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        onTap: () async {
                          ConfirmationDialog().show(
                              context: context,
                              title: "Delete this comment",
                              detailText:
                              " This comment will be permanently deleted. You'll no longer to see and find this comment",
                              onConfirm: () {
                                Provider.of<PostVM>(context)
                                    .deleteComment(comments);
                                // AmitySuccessDialog
                                //     .showTimedDialog(
                                //         "Success",
                                //         context:
                                //             context);
                                Navigator.pop(context);
                              });
                        },
                      ),
                    ]);
                  },
                ),
              ],
            ),
          );
        });
  }
}

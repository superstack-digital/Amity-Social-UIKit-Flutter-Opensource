import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/v4/core/theme.dart';
import 'package:amity_uikit_beta_service/v4/core/toast/bloc/amity_uikit_toast_bloc.dart';
import 'package:amity_uikit_beta_service/v4/social/post/common/post_action.dart';
import 'package:amity_uikit_beta_service/v4/social/post/common/post_display_name.dart';
import 'package:amity_uikit_beta_service/v4/social/post/post_item/bloc/post_item_bloc.dart';
import 'package:amity_uikit_beta_service/v4/social/post_composer_page/post_composer_model.dart';
import 'package:amity_uikit_beta_service/v4/social/post_composer_page/post_composer_page.dart';
import 'package:amity_uikit_beta_service/v4/utils/network_image.dart';
import 'package:amity_uikit_beta_service/viewmodel/edit_post_viewmodel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app_padel/features/community/presentation/screens/people_profile_screen.dart';
import 'package:mobile_app_padel/shared/constants.dart';
import 'package:mobile_app_padel/features/profile/data/match.dart';
import 'package:mobile_app_padel/features/community/data/models/event.dart';
import 'package:mobile_app_padel/features/community/data/models/event_standing.dart';
import 'package:amity_uikit_beta_service/view/social/global_feed.dart';
import 'package:amity_uikit_beta_service/view/UIKit/social/general_component.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:mobile_app_padel/shared/styles.dart';
import 'package:mobile_app_padel/shared/functions.dart';
import 'package:mobile_app_padel/features/onboarding/data/models/user.dart';
import 'package:mobile_app_padel/features/profile/data/repositories/profile_repository.dart';
import 'package:amity_uikit_beta_service/v4/utils/post_data_cache_manager.dart';
import 'package:mobile_app_padel/shared/widgets/shadow_avatar.dart';
import 'package:amity_uikit_beta_service/view/social/community_feedV2.dart';
import 'package:mobile_app_padel/shared/deeplink.dart';
import 'package:mobile_app_padel/features/community/presentation/screens/people_profile_screen.dart';
import 'package:amity_uikit_beta_service/view/social/community_feedV2.dart';
import 'package:collection/collection.dart';



class AmityPostHeader extends StatefulWidget {
  final AmityPost post;
  final bool isShowOption;
  final AmityThemeColor theme;
  final AmityPostAction? action;
  final IMatch? match;
  final IMatch? matchResult;
  final Event? event;
  final List<EventStanding>? eventStanding;
  final User? followingUser;

  const AmityPostHeader({
    super.key,
    required this.post,
    this.isShowOption = true,
    required this.theme,
    this.action,
    this.match,
    this.matchResult,
    this.event,
    this.eventStanding,
    this.followingUser});

  @override
  State<AmityPostHeader> createState() => _AmityPostHeaderState();
}

class _AmityPostHeaderState extends State<AmityPostHeader> {
  List<User>? _joinedUsers;
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _loadJoinedUsersIfNeeded();
  }

  Future<void> _loadJoinedUsersIfNeeded() async {
    final type = getGeneratePostType(widget.post);
    if ((type == GeneratePostType.joined_event || type == GeneratePostType.joined_match) && 
        !_isLoadingUsers && _joinedUsers == null) {
      final joinedUserIds = widget.post.metadata?["joinedUserIds"] as List<dynamic>?;
      if (joinedUserIds != null && joinedUserIds.isNotEmpty) {
        setState(() {
          _isLoadingUsers = true;
        });
        
        try {
          // Use cache manager for batch user loading
          final cacheManager = PostDataCacheManager();
          final userIdsList = joinedUserIds.map((id) => id as int).toList();
          final users = await cacheManager.getMultipleUsers(userIdsList);
          
          if (mounted) {
            setState(() {
              _joinedUsers = users;
              _isLoadingUsers = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoadingUsers = false;
            });
          }
        }
      }
    }
  }

  void goToUserProfile(String? userId) {
    if (userId == null || userId.isEmpty) return;

    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => PeopleProfileScreen(userId: int.parse(userId))));

  }

  void goToCommunityPage(AmityCommunity? community){
    if (community == null) return;

    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => CommunityScreen(community: community)));
  }

  @override
  Widget build(BuildContext context) {
    final isJoinedMatchPost = widget.post.metadata?["type"] == "joined_match";

    return Container(
      height: isJoinedMatchPost ? 87 : 60,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child:
              Container(
                child:  TimeAgoWidget(createdAt: widget.post.createdAt ?? DateTime.now(),
                    textStyle: Styles.fontInterRegular(10, lineHeightInPxl: 21, color: Styles.tpsBrown)),
                alignment: Alignment.centerRight,
              )),
              GestureDetector(
                onTap: () => showPostAction(context, widget.post),
                child: Container(
                  padding: EdgeInsets.only(right: 10, left: 7),
                  child: Icon(
                    Icons.more_vert,
                    color: HexColor("B3B3B3"),
                  ),
                ),
              )
            ],
          ),
          SizedBox(height: 36, child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                  onTap: () {
                    final userId = int.tryParse(widget.post.postedUserId ?? '0');
                    if (userId != null && userId.toString() != AmityCoreClient.getUserId()) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              PeopleProfileScreen(
                                userId: int.parse(widget.post.postedUserId ?? '0'),
                              ),
                        ),
                      );
                    }
                  },
                  child: _buildAvatarSection()),

              // Expanded(child: PostDisplayName(post: post, theme: theme)),
              Expanded(child: Container(padding: EdgeInsets.only(right: 15),
                  child: _postTitle)),
            ],
          )),
          if(widget.post.metadata?["type"] == "joined_match")
            Container(
              margin: EdgeInsets.only(top: isJoinedMatchPost ? 5 : 0, left: 51),
              child: RichText(
                text: TextSpan(
                    text: "",
                    children: [
                      TextSpan(
                        text: 'Created by ',
                        style: Styles.fontInterRegular(
                            12, lineHeightInPxl: 20, color: Styles.gray8B9197),
                      ),
                      TextSpan(
                        text: "${widget.match?.getPlayers().firstWhere((element) =>
                        element.user.id == widget.match?.createdUserId).user.fullName ?? ""}",
                        style: Styles.fontInterSemiBold(
                            12, lineHeightInPxl: 20, color: Styles.green),
                      ),
                      TextSpan(
                        text: " in ",
                        style: Styles.fontInterRegular(
                            12, lineHeightInPxl: 20, color: Styles.gray8B9197),
                      ),
                      TextSpan(
                        text: "${widget.match?.getCourt()?.name ?? ""}",
                        style: Styles.fontInterSemiBold(
                            12, lineHeightInPxl: 20, color: Styles.green),
                      ),
                    ]
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget getPostOptionIcon() {
    return Container(
      width: 16,
      height: 16,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SvgPicture.asset(
        'assets/Icons/amity_ic_post_item_option.svg',
        package: 'amity_uikit_beta_service',
        width: 16,
        height: 12,
      ),
    );
  }

  void showPostAction(BuildContext context, AmityPost post) async {
    final currentUserId = AmityCoreClient.getUserId();

    var isModerator = false;

    var postTarget = post.target;
    if (postTarget is CommunityTarget) {
      var roles = await AmitySocialClient.newCommunityRepository()
          .getCurrentUserRoles(postTarget.targetCommunityId ?? "");

      if (roles != null &&
          (roles.contains("moderator") ||
              roles.contains("community-moderator"))) {
        isModerator = true;
      }
    }

    if (post.postedUserId == currentUserId) {
      showPostOwnerAction(context, post, widget.theme, isModerator);
    } else {
      showPostGeneralAction(context, post, isModerator);
    }
  }

  void showPostGeneralAction(
      BuildContext context, AmityPost post, bool isModerator) {
    onReport() => {
          context.read<PostItemBloc>().add(PostItemFlag(
              post: post, toastBloc: context.read<AmityToastBloc>()))
        };
    onUnReport() => {
          context.read<PostItemBloc>().add(PostItemUnFlag(
              post: post, toastBloc: context.read<AmityToastBloc>()))
        };

    onDelete() {
      context
          .read<PostItemBloc>()
          .add(PostItemDelete(post: post, action: widget.action));
    }

    onShare() {
      handleShareContent(
          metadata: {"type": "communityPost", "postId": post.postId ?? ""},
          title: "Join Community",
          shouldShare: true,
          description: "Let's join our match to play together");
    }

    double height = 0;
    double baseHeight = 80;
    double itemHeight = 48;
    if (isModerator) {
      itemHeight += 48;
    }
    // Add height for Share option
    itemHeight += 48;
    height = baseHeight + itemHeight;

    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        builder: (BuildContext context) {
          return SizedBox(
            height: height,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 36,
                  padding: const EdgeInsets.only(top: 12, bottom: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: ShapeDecoration(
                          color: Color(0xFFA5A9B5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                (!post.isFlaggedByMe)
                    ? GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          onReport();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.only(top: 2, bottom: 2),
                                child: SvgPicture.asset(
                                  'assets/Icons/amity_ic_flag.svg',
                                  package: 'amity_uikit_beta_service',
                                  width: 24,
                                  height: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Report post',
                                style: TextStyle(
                                  color: Color(0xFF292B32),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          onUnReport();
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.only(top: 2, bottom: 2),
                                child: SvgPicture.asset(
                                  'assets/Icons/amity_ic_flag.svg',
                                  package: 'amity_uikit_beta_service',
                                  width: 24,
                                  height: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Unreport post',
                                style: TextStyle(
                                  color: Color(0xFF292B32),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onShare();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(top: 2, bottom: 2),
                          child: Icon(
                            Icons.ios_share_outlined,
                            size: 24,
                            color: Color(0xFF292B32),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Share post',
                          style: TextStyle(
                            color: Color(0xFF292B32),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isModerator) _getDeletetedPost(context, post, onDelete)
              ],
            ),
          );
        });
  }

  void showPostOwnerAction(BuildContext context, AmityPost post,
      AmityThemeColor theme, bool isModerator) {
  final editOption = AmityPostComposerOptions.editOptions(post: post);

    onEdit() => {
          Navigator.of(context).push(MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => ChangeNotifierProvider<EditPostVM>(
                  create: (context) => EditPostVM(),
                  child: PostComposerPage(options: editOption))))
        };
    onDelete() {
      context
          .read<PostItemBloc>()
          .add(PostItemDelete(post: post, action: widget.action));
    }

    onShare() {
      handleShareContent(
          metadata: {"type": "communityPost", "postId": post.postId ?? ""},
          title: "Join Community",
          shouldShare: true,
          description: "Let's join our match to play together");
    }

    double height = 0;
    double baseHeight = 80;
    double itemsHeight = 144; // 3 items: Edit + Share + Delete
    height = baseHeight + itemsHeight;

    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        builder: (BuildContext context) {
          return SizedBox(
            height: height,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 36,
                  padding: const EdgeInsets.only(top: 12, bottom: 20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: ShapeDecoration(
                          color: Color(0xFFA5A9B5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onEdit();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(top: 2, bottom: 2),
                          child: SvgPicture.asset(
                            'assets/Icons/amity_ic_edit_comment.svg',
                            package: 'amity_uikit_beta_service',
                            width: 24,
                            height: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Edit post',
                          style: TextStyle(
                            color: Color(0xFF292B32),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    onShare();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.only(top: 2, bottom: 2),
                          child: Icon(
                            Icons.ios_share_outlined,
                            size: 24,
                            color: Color(0xFF292B32),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Share post',
                          style: TextStyle(
                            color: Color(0xFF292B32),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _getDeletetedPost(context, post, onDelete),
              ],
            ),
          );
        });
  }

  Widget _getDeletetedPost(
      BuildContext context, AmityPost post, Function onDelete) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: const Text("Delete post"),
              content: const Text("This post will be permanently deleted."),
              actions: [
                CupertinoDialogAction(
                  child: const Text("Cancel",
                      style: TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      )),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                CupertinoDialogAction(
                  child: Text(
                    "Delete",
                    style: TextStyle(
                      color: widget.theme.alertColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDelete();
                  },
                ),
              ],
            );
          },
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: SvgPicture.asset(
                'assets/Icons/amity_ic_delete.svg',
                package: 'amity_uikit_beta_service',
                width: 24,
                height: 20,
                colorFilter:
                    ColorFilter.mode(widget.theme.alertColor, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete post',
              style: TextStyle(
                color: widget.theme.alertColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String getPostOwnerName(GeneratePostType type) {
    switch (type) {
      case GeneratePostType.event_created:
      case GeneratePostType.weekly_ranking:
        return (widget.post.target as CommunityTarget).targetCommunity?.displayName ?? "";
      case GeneratePostType.event_standing:
        return widget.eventStanding?.first.user.fullName ?? "";
      default:
        return widget.post.postedUser?.displayName ?? "";
    }
  }

  String getRevenueName(GeneratePostType type){
    switch (type) {
      case GeneratePostType.event_created:
        return widget.event?.club?.name ?? "";
      default:
        return widget.post.postedUser?.displayName ?? "";
    }
  }

  RichText get _postTitle {
    final type = getGeneratePostType(widget.post);

    switch(type){
      case GeneratePostType.event_created:
        return RichText(
          softWrap: true,
          overflow: TextOverflow.visible,
          maxLines: 2,
          text: TextSpan(
            children: [
              WidgetSpan(
                child: SizedBox(
                  height: 19,
                  child: InkWell(
                    onTap: () =>
                        goToCommunityPage(
                            (widget.post.target as CommunityTarget).targetCommunity),
                    child: Text(
                        getPostOwnerName(type),
                        style: Styles.fontInterSemiBold(
                            14, lineHeightInPxl: 21, color: Styles.gray2E3944)),
                  ),
                ),
              ),
               TextSpan(
                text: ' created a new ',
                 style: Styles.fontInterRegular(
                     14, lineHeightInPxl: 21, color: Styles.gray2E3944),
              ),
              TextSpan(
                text: "event",
                style: Styles.fontInterSemiBold(
                    14, lineHeightInPxl: 21, color: Styles.gray2E3944),
              ),
            ],
          ),
        );
      case GeneratePostType.match_looking_for_players:
        return RichText(
          softWrap: true,
          overflow: TextOverflow.visible,
          maxLines: 2,
          text: TextSpan(
            children: [
              WidgetSpan(
                  child:
                    Container(
                      height: 19,
                      child: InkWell(
                        onTap: () => goToUserProfile(widget.post.postedUserId),
                        child: Text(
                            getPostOwnerName(type),
                            style: Styles.fontInterSemiBold(
                                14, lineHeightInPxl: 21, color: Styles.gray2E3944)
                        ),
                      ),
                    )
              ),
              TextSpan(
                text: ' created a match at ',
                style: Styles.fontInterRegular(
                    14, lineHeightInPxl: 21, color: Styles.gray2E3944),
              ),
              TextSpan(
                text: widget.match?.getCourt()?.name ?? "",
                style: Styles.fontInterSemiBold(
                    14, lineHeightInPxl: 21, color: Styles.gray2E3944),
              ),
            ],
          ),
        );
      case GeneratePostType.match_completed:
        // Get winning and losing teams
        final teams = widget.matchResult?.getTeams() ?? [];
        final winningTeamId = widget.matchResult?.winningEphemeralTeamId ?? 
                               widget.matchResult?.winningTeamId;
        
        if (teams.isEmpty || teams.length < 2) {
          return RichText(
            text: TextSpan(
              text: 'Match completed',
              style: Styles.fontInterRegular(
                  14, lineHeightInPxl: 21, color: Styles.gray2E3944),
            ),
          );
        }

        final winningTeam = teams.firstWhere(
          (team) => team.id == winningTeamId,
          orElse: () => teams[0],
        );
        final losingTeam = teams.firstWhere(
          (team) => team.id != winningTeamId,
          orElse: () => teams[1],
        );

        final List<User> winningTeamUsers = [];

        if(winningTeam.playerOne != null) {
          winningTeamUsers.add(winningTeam.playerOne!);
        }
        if(winningTeam.playerTwo != null) {
          winningTeamUsers.add(winningTeam.playerTwo!);
        }

        final List<User> losingTeamUsers = [];
        if(losingTeam.playerOne != null) {
          losingTeamUsers.add(losingTeam.playerOne!);
        }
        if(losingTeam.playerTwo != null) {
          losingTeamUsers.add(losingTeam.playerTwo!);
        }


        final winnerNames = winningTeamUsers
            ?.map((u) => u.fullName?.split(' ').first ?? '')
            .where((name) => name.isNotEmpty)
            .join(' & ') ?? '';
        final winnerUserIds = winningTeamUsers
            ?.map((u) => u.id?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList() ?? [];
        
        final loserNames = losingTeamUsers
            ?.map((u) => u.fullName?.split(' ').first ?? '')
            .where((name) => name.isNotEmpty)
            .join(' & ') ?? '';
        final loserUserIds = losingTeamUsers
            ?.map((u) => u.id?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList() ?? [];

        final communityName = (widget.post.target as CommunityTarget?)
            ?.targetCommunity?.displayName ?? '';

        return RichText(
          softWrap: true,
          overflow: TextOverflow.visible,
          maxLines: 3,
          text: TextSpan(
            children: [
              ...winningTeamUsers.mapIndexed((index, user) => [
                WidgetSpan(
                    child:
                    Container(
                      height: 19,
                      child: InkWell(
                        onTap: () => goToUserProfile(user.id?.toString()),
                        child: Text(
                            user.fullName ?? "",
                            style: Styles.fontInterSemiBold(
                                14, lineHeightInPxl: 21, color: Styles.gray2E3944)
                        ),
                      ),
                    )
                ),
                  if(winningTeamUsers.length == 2 && index == 0) ...[
                    TextSpan(
                      text: ' & ',
                      style: Styles.fontInterRegular(
                          14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                    )
                  ]
              ]).expand((element) => element).toList(),
              TextSpan(
                text: ' defeated ',
                style: Styles.fontInterRegular(
                    14, lineHeightInPxl: 21, color: Styles.gray2E3944),
              ),
              ...losingTeamUsers.mapIndexed((index, user) => [
                WidgetSpan(
                    child:
                    Container(
                      height: 19,
                      child: InkWell(
                        onTap: () => goToUserProfile(user.id?.toString()),
                        child: Text(
                            user.fullName ?? "",
                            style: Styles.fontInterSemiBold(
                                14, lineHeightInPxl: 21, color: Styles.gray2E3944)
                        ),
                      ),
                    )
                ),
                  if(losingTeamUsers.length == 2 && index == 0) ...[
                    TextSpan(
                      text: ' & ',
                      style: Styles.fontInterRegular(
                          14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                    )
                  ]
              ]).expand((element) => element).toList(),
              TextSpan(
                text: ' in ',
                style: Styles.fontInterRegular(
                    14, lineHeightInPxl: 21, color: Styles.gray2E3944),
              ),
              WidgetSpan(
                child: Container(
                  height: 19,
                  child: InkWell(
                    onTap: () => goToCommunityPage(
                        (widget.post.target as CommunityTarget?)?.targetCommunity),
                    child: Text(
                      communityName,
                      style: Styles.fontInterSemiBold(
                          14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      case GeneratePostType.event_standing:
        return RichText(
          softWrap: true,
          overflow: TextOverflow.visible,
          maxLines: 2,
          text: TextSpan(
            children: [
              WidgetSpan(
                  child:
                  Container(
                    height: 19,
                    child: InkWell(
                      onTap: () => goToUserProfile(widget.eventStanding?.first.user.id?.toString()),
                      child: Text(
                        getPostOwnerName(type),
                        style: Styles.fontInterSemiBold(
                            14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                      ),
                    ),
                  )
              ),
              TextSpan(
                text: ' won the ${widget.eventStanding?.first.event?.tournament ?? "event"} tournament in ',
                style: Styles.fontInterRegular(
                    14, lineHeightInPxl: 21, color: Styles.gray2E3944),
              ),
              TextSpan(
                text: widget.eventStanding?.first.event.club?.name ?? "",
                style: Styles.fontInterSemiBold(
                    14, lineHeightInPxl: 21, color: Styles.gray2E3944),
              ),
            ],
          ),
        );
      case GeneratePostType.start_following_user:
        return RichText(
          softWrap: true,
          overflow: TextOverflow.visible,
          maxLines: 2,
          text: TextSpan(
            children: [
              WidgetSpan(
                  child:
                  Container(
                    height: 19,
                    child: InkWell(
                      onTap: () => goToUserProfile(widget.post.postedUserId),
                      child: Text(
                        getPostOwnerName(type),
                        style: Styles.fontInterSemiBold(
                            14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                      ),
                    ),
                  )
              ),
              TextSpan(
                text: ' started following ',
                style: Styles.fontInterRegular(
                    14, lineHeightInPxl: 21, color: Styles.gray2E3944),
              ),
              TextSpan(
                text: widget.followingUser?.fullName ?? "",
                style: Styles.fontInterSemiBold(
                    14, lineHeightInPxl: 21, color: Styles.gray2E3944),
              ),
            ],
          ),
        );
      case GeneratePostType.level_up:
        return RichText(
          softWrap: true,
          overflow: TextOverflow.visible,
          maxLines: 2,
          text: TextSpan(
            children: [
              WidgetSpan(
                  child:
                  Container(
                    height: 19,
                    child: InkWell(
                      onTap: () => goToUserProfile(widget.post.postedUserId),
                      child: Text(
                        getPostOwnerName(type),
                        style: Styles.fontInterSemiBold(
                            14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                      ),
                    ),
                  )
              ),
              TextSpan(
                text: ' just leveled up!',
                style: Styles.fontInterRegular(
                    14, lineHeightInPxl: 21, color: Styles.gray2E3944),
              ),
            ],
          ),
        );
      case GeneratePostType.joined_match:
        final joinedCount = _joinedUsers?.length ?? 0;

        return RichText(
            softWrap: true,
            overflow: TextOverflow.visible,
            maxLines: 2,
            text: TextSpan(
              children: [
                if (joinedCount >= 2) ...[
                  // Last joined user
                  WidgetSpan(
                      child:
                      Container(
                        height: 19,
                        child: InkWell(
                          onTap: () => goToUserProfile(_joinedUsers![joinedCount - 1].id.toString()),
                          child: Text(
                            _joinedUsers![joinedCount - 1].fullName ?? "",
                            style: Styles.fontInterSemiBold(
                                14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                          ),
                        ),
                      )
                  ),
                  TextSpan(
                    text: ' just joined a match with ',
                    style: Styles.fontInterRegular(
                        14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                  ),
                  // Show other players (all except last one)
                  if (joinedCount == 2) ...[
                    WidgetSpan(
                        child:
                        Container(
                          height: 19,
                          child: InkWell(
                            onTap: () => goToUserProfile(_joinedUsers![0].id.toString()),
                            child: Text(
                              _joinedUsers![0].fullName ?? "",
                              style: Styles.fontInterSemiBold(
                                  14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                            ),
                          ),
                        )
                    ),
                  ] else if (joinedCount == 3) ...[
                    // Show "A & B"
                    WidgetSpan(
                        child:
                        Container(
                          height: 19,
                          child: InkWell(
                            onTap: () => goToUserProfile(_joinedUsers![0].id.toString()),
                            child: Text(
                              _joinedUsers![0].fullName ?? "",
                              style: Styles.fontInterSemiBold(
                                  14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                            ),
                          ),
                        )
                    ),
                    TextSpan(
                      text: ' & ',
                      style: Styles.fontInterRegular(
                          14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                    ),
                    WidgetSpan(
                        child:
                        Container(
                          height: 19,
                          child: InkWell(
                            onTap: () => goToUserProfile(_joinedUsers![1].id.toString()),
                            child: Text(
                              _joinedUsers![1].fullName ?? "",
                              style: Styles.fontInterSemiBold(
                                  14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                            ),
                          ),
                        )
                    ),
                  ] else ...[
                    // Show "A & N other players"
                    WidgetSpan(
                        child:
                        Container(
                          height: 19,
                          child: InkWell(
                            onTap: () => goToUserProfile(_joinedUsers![0].id.toString()),
                            child: Text(
                              _joinedUsers![0].fullName ?? "",
                              style: Styles.fontInterSemiBold(
                                  14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                            ),
                          ),
                        )
                    ),
                    TextSpan(
                      text: ' & ${joinedCount - 2} other player${joinedCount - 2 > 1 ? 's' : ''}',
                      style: Styles.fontInterSemiBold(
                          14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                    ),
                  ],
                ] else ...[
                  // Fallback to posted user
                  TextSpan(
                    text: getPostOwnerName(type),
                    style: Styles.fontInterSemiBold(
                        14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                  ),
                  TextSpan(
                    text: ' just joined a match',
                    style: Styles.fontInterRegular(
                        14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                  ),
                ],
              ],
            ),
        );

      case GeneratePostType.joined_event:
        final joinedCount = _joinedUsers?.length ?? 0;

        return RichText(
          softWrap: true,
          overflow: TextOverflow.visible,
          maxLines: 2,
          text: TextSpan(
            children: [
              if (joinedCount == 2) ...[
                // Show "A & B"
                WidgetSpan(
                    child:
                    Container(
                      height: 19,
                      child: InkWell(
                        onTap: () => goToUserProfile(_joinedUsers![0].id.toString()),
                        child: Text(
                          _joinedUsers![0].fullName ?? "",
                          style: Styles.fontInterSemiBold(
                              14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                        ),
                      ),
                    )
                ),
                TextSpan(
                  text: ' & ',
                  style: Styles.fontInterRegular(
                      14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                ),
                WidgetSpan(
                    child:
                    Container(
                      height: 19,
                      child: InkWell(
                        onTap: () => goToUserProfile(_joinedUsers![1].id.toString()),
                        child: Text(
                          _joinedUsers![1].fullName ?? "",
                          style: Styles.fontInterSemiBold(
                              14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                        ),
                      ),
                    )
                ),
              ] else if (joinedCount >= 3) ...[
                // Show "A, B & N players"
                WidgetSpan(
                    child:
                    Container(
                      height: 19,
                      child: InkWell(
                        onTap: () => goToUserProfile(_joinedUsers![0].id.toString()),
                        child: Text(
                          _joinedUsers![0].fullName ?? "",
                          style: Styles.fontInterSemiBold(
                              14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                        ),
                      ),
                    )
                ),
                TextSpan(
                  text: ', ',
                  style: Styles.fontInterRegular(
                      14, lineHeightInPxl: 21, color: Styles.blackNeutral),
                ),
                WidgetSpan(
                    child:
                    Container(
                      height: 19,
                      child: InkWell(
                        onTap: () => goToUserProfile(_joinedUsers![1].id.toString()),
                        child: Text(
                          _joinedUsers![1].fullName ?? "",
                          style: Styles.fontInterSemiBold(
                              14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                        ),
                      ),
                    )
                ),
                TextSpan(
                  text: ' & ${joinedCount - 2} player${joinedCount - 2 > 1 ? 's' : ''}',
                  style: Styles.fontInterSemiBold(
                      14, lineHeightInPxl: 21, color: Styles.blackNeutral),
                ),
              ] else ...[
                // Fallback to posted user
                WidgetSpan(
                    child:
                    Container(
                      height: 19,
                      child: InkWell(
                        onTap: () => goToUserProfile(widget.post.postedUserId),
                        child: Text(
                          getPostOwnerName(type),
                          style: Styles.fontInterSemiBold(
                              14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                        ),
                      ),
                    )
                ),
              ],
              TextSpan(
                text: ' joined ',
                style: Styles.fontInterRegular(
                    14, lineHeightInPxl: 21, color: Styles.blackNeutral),
              ),
              TextSpan(
                text: widget.event?.name ?? "",
                style: Styles.fontInterSemiBold(
                    14, lineHeightInPxl: 21, color: Styles.blackNeutral),
              ),
            ],
          ),
        );
      case GeneratePostType.weekly_ranking:
        return RichText(
          softWrap: true,
          overflow: TextOverflow.visible,
          maxLines: 2,
          text: TextSpan(
            children: [
              TextSpan(
                text: "Weekly rankings update",
                style: Styles.fontInterSemiBold(
                    14, lineHeightInPxl: 21, color: Styles.blackNeutral),
              ),
              TextSpan(
                text: ' in ',
                style: Styles.fontInterRegular(
                    14, lineHeightInPxl: 21, color: Styles.blackNeutral),
              ),
              WidgetSpan(
                child: SizedBox(
                  height: 19,
                  child: InkWell(
                    onTap: () =>
                        goToCommunityPage(
                            (widget.post.target as CommunityTarget).targetCommunity),
                    child: Text(
                        getPostOwnerName(type),
                        style: Styles.fontInterSemiBold(
                            14, lineHeightInPxl: 21, color: Styles.gray2E3944)),
                  ),
                ),
              )
            ],
          ),
        );
      default:
        return RichText(
          text: TextSpan(
            text: "",
            children: [
              WidgetSpan(
                  child:
                  Container(
                    height: 19,
                    child: InkWell(
                      onTap: () => goToUserProfile(widget.post.postedUserId),
                      child: Text(
                        getPostOwnerName(type),
                        style: Styles.fontInterSemiBold(
                            14, lineHeightInPxl: 21, color: Styles.gray2E3944),
                      ),
                    ),
                  )
              ),
              if(widget.post.targetType == AmityPostTargetType.COMMUNITY) TextSpan(
                text: " posted in ",
                style: Styles.fontInterRegular(14, lineHeightInPxl: 21, color: Styles.blackNeutral)
              ),
              if(widget.post.targetType == AmityPostTargetType.COMMUNITY) TextSpan(
                text: "${(widget.post.target as CommunityTarget).targetCommunity?.displayName ?? ""}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ]
          ),
        );
    }
  }

  Widget _buildAvatarSection() {
    final type = getGeneratePostType(widget.post);
    
    // For joined_event and joined_match posts, show stacked avatars of joined users
    if ((type == GeneratePostType.joined_event) &&
        _joinedUsers != null && _joinedUsers!.length >= 2) {
      final displayCount = _joinedUsers!.length > 2 ? 2 : _joinedUsers!.length;
      final remainingCount = _joinedUsers!.length - 2;
      
      return Container(
        padding: const EdgeInsets.only(left: 20),
        child: SizedBox(
          width: displayCount == 2 && remainingCount > 0 ? 56 : 46, // Extra width for overlay
          height: 32,
          child: Stack(
            children: [
              // First avatar
              Positioned(
                left: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: AmityNetworkImage(
                      imageUrl: _joinedUsers![0].avatar,
                      placeHolderPath: "assets/Icons/amity_ic_user_avatar_placeholder.svg",
                    ),
                  ),
                ),
              ),
              // Second avatar (stacked)
              Positioned(
                left: 14,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      children: [
                        AmityNetworkImage(
                          imageUrl: _joinedUsers![1].avatar,
                          placeHolderPath: "assets/Icons/amity_ic_user_avatar_placeholder.svg",
                        ),
                        // Overlay if more than 2 users
                        if (remainingCount > 0)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Center(
                              child: Text(
                                '+$remainingCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if(type == GeneratePostType.joined_match) {
      final joinedCount = _joinedUsers?.length ?? 0;
      return Container(
          padding: const EdgeInsets.only(left: 20, right: 7),
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(color: Colors.white),
          child: SizedBox(
            width: 32,
            height: 32,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: AmityNetworkImage(
                imageUrl: _joinedUsers?[joinedCount - 1].avatar ?? "",
                placeHolderPath: "assets/Icons/amity_ic_user_avatar_placeholder.svg",
              ),
            ),
          ),
      );
    }


    if(type == GeneratePostType.event_created){
      final target = widget.post.target as CommunityTarget;
      return Container(
        padding: const EdgeInsets.only(left: 20, right: 7),
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(color: Colors.white),
        child: ShadowAvatar(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => CommunityScreen(
                    community: target.targetCommunity!))),
            borderWidth: 0,
            height: 32,
            width: 32,
            url: target.targetCommunity?.avatarImage
                ?.getUrl(AmityImageSize.SMALL) ?? "",
            fullName: target.targetCommunity?.displayName ?? ""),
      );
    }
    
    if(type == GeneratePostType.weekly_ranking){
      final target = widget.post.target as CommunityTarget;
      return Container(
        padding: const EdgeInsets.only(left: 20, right: 7),
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(color: Colors.white),
        child: ShadowAvatar(
            borderWidth: 0,
            height: 32,
            width: 32,
            url: target.targetCommunity?.avatarImage
                ?.getUrl(AmityImageSize.SMALL) ?? "",
            fullName: target.targetCommunity?.displayName ?? ""),
      );
    }

    if(type == GeneratePostType.event_standing){
      return Container(
        padding: const EdgeInsets.only(left: 20, right: 7),
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(color: Colors.white),
        child: ShadowAvatar(
            borderWidth: 0,
            height: 32,
            width: 32,
            url: widget.eventStanding?.first.user.avatar ?? "",
            fullName: widget.eventStanding?.first.user.fullName ?? ""),
      );
    }

    // Default: single avatar of poster
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 7),
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(color: Colors.white),
      child: ShadowAvatar(height: 32, width: 32, url: widget.post.postedUser?.avatarUrl ??
          widget.post.postedUser?.avatarCustomUrl ?? "", fullName: widget.post.postedUser?.displayName ?? ""),
    );
  }
}

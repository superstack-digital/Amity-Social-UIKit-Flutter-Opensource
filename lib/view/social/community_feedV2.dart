import 'dart:developer';
import 'dart:math' as math;

import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/view/UIKit/social/community_setting/community_member_page.dart';
import 'package:amity_uikit_beta_service/view/UIKit/social/community_setting/edit_community.dart';
import 'package:amity_uikit_beta_service/view/UIKit/social/community_setting/setting_page.dart';
import 'package:amity_uikit_beta_service/view/UIKit/social/create_post_screenV2.dart';
import 'package:amity_uikit_beta_service/view/social/global_feed.dart';
import 'package:amity_uikit_beta_service/view/social/pending_page.dart';
import 'package:amity_uikit_beta_service/view/user/medie_component.dart';
import 'package:amity_uikit_beta_service/viewmodel/explore_page_viewmodel.dart';
import 'package:amity_uikit_beta_service/viewmodel/my_community_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mobile_app_padel/features/community/presentation/screens/create_event_screen.dart';

import '../../viewmodel/community_feed_viewmodel.dart';
import '../../viewmodel/community_viewmodel.dart';
import '../../viewmodel/configuration_viewmodel.dart';
import 'package:flutter/cupertino.dart';
import 'package:mobile_app_padel/shared/functions.dart';
import 'package:mobile_app_padel/features/community/widgets/event_item.dart';
import 'package:mobile_app_padel/features/play/presentation/widgets/upcoming_event_item.dart';
import 'package:mobile_app_padel/features/community/widgets/share_match_modal.dart';
import 'package:mobile_app_padel/features/community/widgets/empty_community_matches_view.dart';
import 'package:mobile_app_padel/features/community/widgets/empty_community_event_view.dart';
import 'package:mobile_app_padel/features/community/presentation/screens/community_matches_screen.dart';
import 'package:mobile_app_padel/features/community/presentation/screens/community_rankings_screen.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:mobile_app_padel/features/chat/presentations/screens/chat_screen.dart';
import 'package:mobile_app_padel/shared/deeplink.dart';
import 'package:mobile_app_padel/features/chat/presentations/widgets/chat_screen_controller.dart';
import 'package:get/get.dart';
import 'package:mobile_app_padel/features/profile/data/repositories/match_repository.dart';
import 'package:mobile_app_padel/features/profile/data/match.dart';
import 'package:mobile_app_padel/features/community/presentation/controllers/share_open_matches_controller.dart';
import 'package:mobile_app_padel/features/community/presentation/controllers/community_rankings_controller.dart';
import 'package:mobile_app_padel/features/community/presentation/controllers/social_rankings_controller.dart';
import 'package:mobile_app_padel/features/community/presentation/controllers/americano_rankings_controller.dart';
import 'package:mobile_app_padel/features/community/presentation/controllers/mexicano_rankings_controller.dart';
import 'package:mobile_app_padel/features/community/presentation/controllers/team_rankings_controller.dart';
import 'package:mobile_app_padel/features/community/data/repositories/event_repository.dart';
import 'package:mobile_app_padel/features/community/data/models/event.dart';
import 'package:mobile_app_padel/features/community/data/models/event_standing.dart';
import 'package:amity_uikit_beta_service/v4/social/post/post_item/post_item_updated.dart';
import 'package:amity_uikit_beta_service/v4/social/post/post_item/bloc/post_item_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app_padel/features/community/presentation/controllers/community_controller.dart';


class CommunityScreen extends StatefulWidget {
  final AmityCommunity community;
  final bool isFromFeed;
  static const routeName = '/CommunityScreen';

  const CommunityScreen({Key? key, required this.community, this.isFromFeed = false})
      : super(key: key);

  @override
  CommunityScreenState createState() => CommunityScreenState();
}

class CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;

  @override
  void initState() {
    Provider.of<CommuFeedVM>(context, listen: false)
        .initAmityCommunityFeed(widget.community.communityId!);
    Provider.of<CommuFeedVM>(context, listen: false).getPostCount(widget.community);
    Provider.of<CommuFeedVM>(context, listen: false)
        .getReviewingPostCount(widget.community);
    Provider.of<CommuFeedVM>(context, listen: false)
        .initAmityCommunityImageFeed(widget.community.communityId!);
    Provider.of<CommuFeedVM>(context, listen: false)
        .initAmityCommunityVideoFeed(widget.community.communityId!);
    Provider.of<CommuFeedVM>(context, listen: false).initAmityPendingCommunityFeed(
        widget.community.communityId!, AmityFeedType.REVIEWING);
    Provider.of<CommuFeedVM>(context, listen: false)
        .checkRankingsEnabled().then((val) {
      Provider
          .of<CommuFeedVM>(context, listen: false)
          .userFeedTabController =
          TabController(
            length: val ? 5 : 4,
            vsync: this,
          );
    });


    super.initState();

  }

  getAvatarImage(String? url) {
    if (url != null) {
      return NetworkImage(url);
    } else {
      return const AssetImage("assets/images/user_placeholder.png",
          package: "amity_uikit_beta_service");
    }
  }

  Widget communityDescription(AmityCommunity community) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 5.0,
        ),
        Text(
          community.description ?? "",
          style: const TextStyle(fontSize: 15),
        ),
      ],
    );
  }

  Widget communityInfo(AmityCommunity community) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Column(
              children: [
                Text("${Provider
                    .of<CommuFeedVM>(context)
                    .postCount}",
                    style: const TextStyle(fontSize: 16)),
                const Text('posts',
                    style: TextStyle(fontSize: 16, color: Color(0xff898E9E)))
              ],
            ),
            Container(
              color: const Color(0xffE5E5E5), // Divider color
              height: 20,
              width: 1,

              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            GestureDetector(
              onTap: () {},
              child: Column(
                children: [
                  Text(
                    community.membersCount.toString(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(community.membersCount == 1 ? 'member' : 'members',
                      style: const TextStyle(fontSize: 16, color: Color(0xff898E9E)))
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final myAppBar = AppBar(
      backgroundColor: Colors.transparent,
      leading: IconButton(
        color: Provider
            .of<AmityUIConfiguration>(context)
            .primaryColor,
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: Icon(
          Icons.chevron_left,
          color: Provider
              .of<AmityUIConfiguration>(context)
              .appColors
              .base,
          size: 24,
        ),
      ),
      elevation: 0,
    );
    final bheight =
        mediaQuery.size.height - mediaQuery.padding.top - myAppBar.preferredSize.height;
    if (true) {
      return PopScope(
          canPop: true,
          onPopInvokedWithResult: (_, __){
            Get.delete<ShareOpenMatchesController>(tag: widget.community?.communityId?.toString());
            Get.delete<CommunityRankingsController>(tag: widget.community?.communityId?.toString());
            Get.delete<SocialRankingsController>(tag: widget.community?.communityId?.toString());
            Get.delete<AmericanoRankingsController>(tag: widget.community?.communityId?.toString());
            Get.delete<MexicanoRankingsController>(tag: widget.community?.communityId?.toString());
            Get.delete<TeamRankingsController>(tag: widget.community?.communityId?.toString());
          },
          child: Stack(children: [
            StreamBuilder<AmityCommunity>(
                stream: widget.community.listen.stream,
                initialData: widget.community,
                builder: (context, snapshot) {
                  return AppScaffold(
                    title: '',
                    slivers: [
                      Consumer<CommuFeedVM>(builder: (context, vm, _) {
                        return _StickyHeaderList(
                            index: 0,
                            theme: theme,
                            bheight: bheight,
                            profileSectionWidget: CommunityDetailComponent(
                              community: snapshot.data!,
                              updateLoadingState: (val) {
                                setState(() {
                                  isLoading = val;
                                  vm.isLoading.value = val;
                                });
                                if (!val) {
                                  showCommunityToastMessage(
                                      "Successfully joined the community");
                                }
                              },
                            ));
                      }),
                      _StickyHeaderList(
                        index: 1,
                        theme: theme,
                        bheight: bheight,
                        communityId: widget.community.communityId!,
                      ),
                    ],
                    amityCommunity: snapshot.data!,
                  );
                }),
            Consumer<CommuFeedVM>(
              builder: (context, vm, _) {
                if (vm.isLoading.value == true) {
                  return Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                        child: Container(
                          width: 258,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: CupertinoActivityIndicator(color: Colors.white),
                        )),
                  );
                } else {
                  return const SizedBox();
                }
              },
            )
          ]));
    } else {
      return Scaffold(
        backgroundColor:
        Provider
            .of<AmityUIConfiguration>(context)
            .appColors
            .baseBackground,
      );
    }
  }
}

class EditProfileButton extends StatefulWidget {
  final AmityCommunity community;
  final Function(bool)? updateLoadingState;

  const EditProfileButton({super.key, required this.community, this.updateLoadingState});

  @override
  State<EditProfileButton> createState() => _EditProfileButtonState();
}

class _EditProfileButtonState extends State<EditProfileButton> {

  @override
  Widget build(BuildContext context) {
    return !widget.community.hasPermission(AmityPermission.EDIT_COMMUNITY)
        ? widget.community.isJoined!
        ? const SizedBox()
        : InkWell(
      onTap: () {
        // Navigate to Edit Profile Page or perform an action
        if (widget.community.isJoined != null) {
          if (widget.community.isJoined!) {
            AmitySocialClient.newCommunityRepository()
                .leaveCommunity(widget.community.communityId!)
                .then((value) async {
              if (widget.community.metadata?["channel_id"] != null) {
                await AmityChatClient.newChannelRepository().leaveChannel(
                    widget.community.metadata?["channel_id"]);
              }
              setState(() {
                widget.community.isJoined = !(widget.community.isJoined!);
                var explorePageVM =
                Provider.of<ExplorePageVM>(context, listen: false);
                explorePageVM.getRecommendedCommunities();
                explorePageVM.getTrendingCommunities();
              });
              if(Get.isRegistered<CommunityController>()){
                final communityController = Get.find<CommunityController>();
                Future.delayed(Duration(seconds: 1), () {
                  communityController.getMyCommunities();
                });
              }
            }).onError((error, stackTrace) {
              //handle error
              log(error.toString());
            });
          } else {
            var explorePageVM =
            Provider.of<ExplorePageVM>(context, listen: false);
            explorePageVM.isLoading = true;
            if (widget.updateLoadingState != null) {
              widget.updateLoadingState!(true);
            }

            AmitySocialClient.newCommunityRepository()
                .joinCommunity(widget.community.communityId!)
                .then((value) async {
              if (widget.community.metadata?["channel_id"] != null) {
                await AmityChatClient.newChannelRepository().joinChannel(
                    widget.community.metadata?["channel_id"]);
              }
              setState(() {
                if (widget.updateLoadingState != null) {
                  widget.updateLoadingState!(false);
                }
                widget.community.isJoined = !(widget.community.isJoined!);
                explorePageVM.getRecommendedCommunities();
                explorePageVM.getTrendingCommunities();
                print(">>>>>>>>>>>>>>>callback");

                var myCommunityList =
                Provider.of<MyCommunityVM>(context, listen: false);
                myCommunityList.initMyCommunity();

                for (var i in myCommunityList.amityCommunities) {
                  print(">>>>>>>>>>>>>>>${i.displayName}");
                }
                print(myCommunityList.amityCommunities);

                explorePageVM.isLoading = false;
              });
            }).onError((error, stackTrace) {
              explorePageVM.isLoading = false;
              log(error.toString());
            });
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: Provider
              .of<AmityUIConfiguration>(context)
              .primaryColor,
          border: Border.all(
              color: Provider
                  .of<AmityUIConfiguration>(context)
                  .primaryColor), // Grey border color
          borderRadius: BorderRadius.circular(40), // Rounded corners
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // To wrap the content of the row
          children: <Widget>[
            Icon(
              Icons.add,
              color: Colors.white,
            ),
            SizedBox(width: 8.0), // Space between icon and text
            Text(
              "Join",
              style: TextStyle(
                color: Colors.white, // Text color
              ),
            ),
          ],
        ),
      ),
    )
        : InkWell(
      onTap: () {
        // Navigate to Edit Profile Page or perform an action
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => AmityEditCommunityScreen(widget.community)));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: const Color(0xffA5A9B5),
          ), // Grey border color
          borderRadius: BorderRadius.circular(40), // Rounded corners
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // To wrap the content of the row
          children: <Widget>[
            Provider
                .of<AmityUIConfiguration>(context)
                .iconConfig
                .editIcon(
              color: Provider
                  .of<AmityUIConfiguration>(context)
                  .appColors
                  .base,
            ),
            const SizedBox(width: 8.0), // Space between icon and text
            Text(
              "Edit Profile",
              style: TextStyle(
                color: Provider
                    .of<AmityUIConfiguration>(context)
                    .appColors
                    .base, // Text color
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PedindingButton extends StatelessWidget {
  final AmityCommunity community;

  const PedindingButton({super.key, required this.community});

  @override
  Widget build(BuildContext context) {
    return
      // Provider.of<CommuFeedVM>(context).getCommunityPendingPosts().isEmpty
      InkWell(
        onTap: () {
          // Navigate to Edit Profile Page or perform an action
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  PendingFeddScreen(
                    community: community,
                  )));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: Provider
                .of<AmityUIConfiguration>(context)
                .appColors
                .baseShade4,
            border: Border.all(
              color: Provider
                  .of<AmityUIConfiguration>(context)
                  .appColors
                  .baseShade4,
            ), // Grey border color
            borderRadius: BorderRadius.circular(4), // Rounded corners
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                // To wrap the content of the row
                children: <Widget>[
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: Provider
                        .of<AmityUIConfiguration>(context)
                        .primaryColor,
                  ),
                  const SizedBox(width: 8.0), // Space between icon and text
                  Text(
                    "Pending posts",
                    style: TextStyle(
                      color: Provider
                          .of<AmityUIConfiguration>(context)
                          .appColors
                          .base, // Text color
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                // To wrap the content of the row
                children: <Widget>[
                  Text(
                    !community.hasPermission(AmityPermission.REVIEW_COMMUNITY_POST)
                        ? "Your posts are pending for review"
                        : "${Provider
                        .of<CommuFeedVM>(context)
                        .reviewingPostCount} posts need approval",
                    style: TextStyle(
                      fontSize: 13,
                      color: Provider
                          .of<AmityUIConfiguration>(context)
                          .appColors
                          .base, // Text color
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
  }
}

class CommunityDetailComponent extends StatefulWidget {
  final AmityCommunity community;
  final Function(bool)? updateLoadingState;

  const CommunityDetailComponent(
      {super.key, required this.community, this.updateLoadingState});

  @override
  State<CommunityDetailComponent> createState() => _CommunityDetailComponentState();
}

class _CommunityDetailComponentState extends State<CommunityDetailComponent> {
  Widget communityDescription(AmityCommunity community) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 5.0,
        ),
        Text(
          community.description ?? "",
          style: TextStyle(
            fontSize: 15,
            color: Provider
                .of<AmityUIConfiguration>(context)
                .appColors
                .base,
          ),
        ),
      ],
    );
  }

  Widget communityInfo(AmityCommunity community) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            Column(
              children: [
                Text("${Provider
                    .of<CommuFeedVM>(context)
                    .postCount}",
                    style: TextStyle(
                      fontSize: 16,
                      color: Provider
                          .of<AmityUIConfiguration>(context)
                          .appColors
                          .base,
                    )),
                const Text('posts',
                    style: TextStyle(fontSize: 16, color: Color(0xff898E9E)))
              ],
            ),
            Container(
              color: const Color(0xffE5E5E5), // Divider color
              height: 20,
              width: 1,

              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            GestureDetector(
              onTap: () {
                // Navigate to Members Page or perform an action
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        MemberManagementPage(
                            communityId: widget.community.communityId!,
                            channelId: community.metadata?["channel_id"])));
              },
              child: Column(
                children: [
                  Text(
                    community.membersCount.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Provider
                          .of<AmityUIConfiguration>(context)
                          .appColors
                          .base,
                    ),
                  ),
                  Text(community.membersCount == 1 ? 'member' : 'members',
                      style: const TextStyle(fontSize: 16, color: Color(0xff898E9E)))
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Provider
          .of<AmityUIConfiguration>(context)
          .appColors
          .baseBackground,
      child: Wrap(
        children: [
          Stack(
            alignment: AlignmentDirectional.bottomStart,
            children: [
              widget.community.avatarImage == null &&
                  widget.community.avatarFileId != null
                  ? Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      height: MediaQuery
                          .of(context)
                          .size
                          .width * 0.7,
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(
                                0.4), // Applying a 40% dark filter to the entire container
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
                  : Row(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      height: MediaQuery
                          .of(context)
                          .size
                          .width * 0.7,
                      decoration: BoxDecoration(
                        color: Provider
                            .of<AmityUIConfiguration>(context)
                            .appColors
                            .primaryShade3,
                        image: widget.community.avatarFileId != null
                            ? DecorationImage(
                          image: NetworkImage(widget.community.avatarImage!
                              .getUrl(AmityImageSize.LARGE)),
                          fit: BoxFit.cover,
                        )
                            : const DecorationImage(
                            image: AssetImage("assets/images/IMG_5637.JPG",
                                package: 'amity_uikit_beta_service'),
                            fit: BoxFit.cover),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(
                              0.4), // Applying a 40% dark filter to the entire container
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        widget.community.isPublic!
                            ? const SizedBox()
                            : const Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 16,
                        ),
                        widget.community.isPublic!
                            ? const SizedBox()
                            : const SizedBox(
                          width: 7,
                        ),
                        Text(
                            widget.community.displayName != null
                                ? widget.community.displayName!
                                : "Community",
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        const SizedBox(
                          width: 7,
                        ),
                        widget.community.isOfficial!
                            ? Provider
                            .of<AmityUIConfiguration>(context)
                            .iconConfig
                            .officialIcon(iconSize: 17, color: Colors.white)
                            : const SizedBox(),
                      ],
                    ),
                    widget.community.categories == null
                        ? const SizedBox()
                        : Text(
                        widget.community.displayName != null
                            ? widget.community.categories!.isEmpty
                            ? "no category"
                            : widget.community.categories![0]?.name ?? ""
                            : "",
                        style: const TextStyle(
                            overflow: TextOverflow.ellipsis,
                            fontSize: 16,
                            color: Colors.white)),
                    const SizedBox(
                      height: 16,
                    )
                  ],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                communityInfo(widget.community),
                const SizedBox(
                  height: 16,
                ),
                communityDescription(widget.community),
                const SizedBox(
                  height: 16,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                        child: EditProfileButton(
                          community: widget.community,
                          updateLoadingState: widget.updateLoadingState,
                        )),
                  ],
                ),
                const SizedBox(
                  height: 12,
                ),
                // InkWell(
                //   child: Text("Share"),
                //   onTap: (){
                //     handleShareContent(metadata: {"type": "community", "communityId": widget.community.communityId ?? ""}, title: widget.community.displayName ?? "", description: widget.community.description ?? "");
                //   },
                // ),
                if(widget.community.isJoined == true)
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      if (widget.community.metadata?["channel_id"] != null) {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) =>
                                ChatScreen(
                                  channelId: widget.community.metadata?["channel_id"],
                                  isCommunity: true,
                                )))?.then((res) =>
                            Get.delete<ChatScreenController>(tag: widget.community
                                .metadata?["channel_id"]));
                      } else {
                        final aa = await AmityChatClient
                            .newChannelRepository()
                            .createChannel()
                            .communityType()
                            .withDisplayName(widget.community?.displayName ?? "")
                            .metadata({"type": "community_channel", "avatar": widget
                            .community.avatarImage?.getUrl(AmityImageSize.MEDIUM)})
                            .create();
                        print(aa.channelId);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: HexColor('#A5A9B5'),
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // TODO: Replace with actual icon
                          Image.network(
                              'https://tnyqbaqnugjgefkdvmag.supabase.co/storage/v1/object/public/public_images/assets/comment-processing-outline.png',
                              width: 18, height: 18),
                          SizedBox(width: 8),
                          Text('Chat with members', style: TextStyle(
                              color: HexColor('#292B32'),
                              fontSize: 15, fontWeight: FontWeight.w600
                          ))
                        ],
                      ),
                    ),
                  ),
                !widget.community.isJoined!
                    ? const SizedBox()
                    : !widget.community.isPostReviewEnabled!
                    ? const SizedBox()
                    : Provider
                    .of<CommuFeedVM>(context)
                    .getCommunityPendingPosts()
                    .isEmpty
                    ? const SizedBox(
                  height: 60,
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                        child: PedindingButton(
                          community: widget.community,
                        )),
                  ],
                )
              ],
            ),
          ),

        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    Key? key,
    required this.text,
    required this.builder,
  }) : super(key: key);

  final String text;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: builder)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
      ),
    );
  }
}

class _StickyHeaderList extends StatelessWidget {
  const _StickyHeaderList({
    Key? key,
    this.index,
    this.profileSectionWidget,
    required this.theme,
    required this.bheight,
    this.communityId,
  }) : super(key: key);

  final int? index;
  final Widget? profileSectionWidget;
  final ThemeData theme;
  final double bheight;
  final String? communityId;

  @override
  Widget build(BuildContext context) {
    return SliverStickyHeader(
      header: Header(
        index: index,
        onChangedTab: () {
          Provider
              .of<CommuFeedVM>(context, listen: false)
              .userFeedTabController!
              .index =
          index!;
        },
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, i) {
            if (index == 0) {
              return profileSectionWidget;
            } else {
              return ChangeNotifierProvider<CommuFeedVM>.value(
                value: Provider.of<CommuFeedVM>(context),
                child: Consumer<CommuFeedVM>(
                  builder: (context, vm, _) {
                    Widget buildPrivateAccountWidget(double bheight) {
                      return SingleChildScrollView(
                        child: Container(
                          color: Provider
                              .of<AmityUIConfiguration>(context)
                              .appColors
                              .baseShade4,
                          width: MediaQuery
                              .of(context)
                              .size
                              .width,
                          height: bheight - 300,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/images/privateIcon.png",
                                package: "amity_uikit_beta_service",
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "This account is private",
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff292B32)),
                              ),
                              const Text(
                                "Follow this user to see all posts",
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xffA5A9B5)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    Widget buildNoPostsWidget(double bheight, BuildContext context) {
                      return SingleChildScrollView(
                        child: Container(
                          color: Provider
                              .of<AmityUIConfiguration>(context)
                              .appColors
                              .baseShade4,
                          width: MediaQuery
                              .of(context)
                              .size
                              .width,
                          height: bheight - 300,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/images/noPostYet.png",
                                package: "amity_uikit_beta_service",
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "No post yet",
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xffA5A9B5)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    Widget buildContent(BuildContext context, double bheight) {
                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 0),
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: vm
                            .getCommunityPosts()
                            .length,
                        itemBuilder: (context, index) {
                          return StreamBuilder<AmityPost>(
                              key: Key(vm.getCommunityPosts()[index].postId!),
                              stream: vm.getCommunityPosts()[index].listen.stream,
                              initialData: vm.getCommunityPosts()[index],
                              builder: (context, snapshot) {
                                final metadata = snapshot.data?.metadata;
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
                                      final eventStanding = snapshot1.data?[3] as List<EventStanding>?;

                                      return BlocProvider(
                                        create: (context) => PostItemBloc(),
                                        child: PostItem(
                                          post: snapshot.data!,
                                          match: match,
                                          matchResult: matchResult,
                                          event: event,
                                          eventStanding: eventStanding,
                                          isPostDetail: false,
                                        ),
                                      );
                                    });
                              });
                        },
                      );
                    }

                    Widget buildEventLists(BuildContext context, double bheight) {
                      if (vm
                          .getCommunityEventList()
                          .isEmpty) {
                        return EmptyCommunityEventView();
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 0),
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: vm
                            .getCommunityEventList()
                            .length,
                        itemBuilder: (context, index) {
                          final event = vm.getCommunityEventList()[index];
                          return EventItem(event: event, onEventDeleted: () {
                            if(communityId != null){
                              vm.getUpcomingEvents(communityId!);
                            }
                          });
                        },
                      );
                    }
                        final int _tabIndex = vm.userFeedTabController?.index ?? -1;

                        switch (_tabIndex) {
                          case 0:
                            return buildContent(context, bheight);
                          case 1:
                            return buildEventLists(context, bheight);
                          case 2:
                            if(vm.communityRankingEnabled.value)
                              {
                                return CommunityRankingsScreen(communityId: communityId!,
                                    onViewUpcomingPressed: vm.onSwitchToEventsTab);
                              } else {
                              return CommunityMatchesScreen(
                                communityId: communityId!,
                                isLeagueCommunity: vm.isLeagueCommunity,
                              );
                            }
                          case 3:
                            if(vm.communityRankingEnabled.value){
                              if (communityId != null) {
                                return CommunityMatchesScreen(
                                  communityId: communityId!,
                                  isLeagueCommunity: vm.isLeagueCommunity,
                                );
                              } else {
                                return Container();
                              }
                            } else {
                              return MediaGalleryPage(
                                galleryFeed: GalleryFeed.community,
                                onRefresh: () {},
                              );
                            }
                          default:
                            return MediaGalleryPage(
                              galleryFeed: GalleryFeed.community,
                              onRefresh: () {},
                            );
                        }
                  },
                ),
              );
            }
          },
          childCount: 1,
        ),
      ),
    );
  }
}

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    Key? key,
    required this.title,
    required this.slivers,
    this.reverse = false,
    required this.amityCommunity,
  }) : super(key: key);

  final String title;
  final List<Widget> slivers;
  final bool reverse;
  final AmityCommunity amityCommunity;

  @override
  Widget build(BuildContext context) {
    return DefaultStickyHeaderController(
      child: Scaffold(
        backgroundColor: Provider
            .of<AmityUIConfiguration>(context)
            .appColors
            .baseShade4,
        // floatingActionButton: (amityCommunity.isJoined!)
        //     ? FloatingActionButton(
        //         shape: const CircleBorder(),
        //         onPressed: () async {
        //           await Navigator.of(context).push(MaterialPageRoute(
        //               builder: (context2) => AmityCreatePostV2Screen(
        //                     community: amityCommunity,
        //                     feedType: FeedType.community,
        //                   )));
        //           Provider.of<CommuFeedVM>(context, listen: false)
        //               .getPostCount(amityCommunity);
        //           Provider.of<CommuFeedVM>(context, listen: false)
        //               .getReviewingPostCount(amityCommunity);
        //           Provider.of<CommuFeedVM>(context, listen: false)
        //               .initAmityCommunityFeed(amityCommunity.communityId!);
        //           Provider.of<CommuFeedVM>(context, listen: false)
        //               .initAmityCommunityImageFeed(amityCommunity.communityId!);
        //           Provider.of<CommuFeedVM>(context, listen: false)
        //               .initAmityCommunityVideoFeed(amityCommunity.communityId!);
        //           Provider.of<CommuFeedVM>(context, listen: false)
        //               .initAmityPendingCommunityFeed(
        //                   amityCommunity.communityId!, AmityFeedType.REVIEWING);
        //         },
        //         backgroundColor:
        //             Provider.of<AmityUIConfiguration>(context).primaryColor,
        //         child: Provider.of<AmityUIConfiguration>(context)
        //             .iconConfig
        //             .postIcon(iconSize: 28, color: Colors.white),
        //       )
        //     : null,
        floatingActionButton: amityCommunity.isJoined == true
            ? SpeedDial(
          children: [
            _renderChildButton(
                context: context,
                margin: const EdgeInsets.only(bottom: 10),
                title: "Create Post",
                onPress: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                      builder: (context2) =>
                          AmityCreatePostV2Screen(
                            community: amityCommunity,
                            feedType: FeedType.community,
                          )));
                  Provider.of<CommuFeedVM>(context, listen: false)
                      .getPostCount(amityCommunity);
                  Provider.of<CommuFeedVM>(context, listen: false)
                      .getReviewingPostCount(amityCommunity);
                  Provider.of<CommuFeedVM>(context, listen: false)
                      .initAmityCommunityFeed(amityCommunity.communityId!);
                  Provider.of<CommuFeedVM>(context, listen: false)
                      .initAmityCommunityImageFeed(amityCommunity.communityId!);
                  Provider.of<CommuFeedVM>(context, listen: false)
                      .initAmityCommunityVideoFeed(amityCommunity.communityId!);
                  Provider.of<CommuFeedVM>(context, listen: false)
                      .initAmityPendingCommunityFeed(
                      amityCommunity.communityId!, AmityFeedType.REVIEWING);
                },
                icon: Icons.create_outlined),
            _renderChildButton(
                context: context,
                margin: const EdgeInsets.only(bottom: 0),
                title: "Create Event",
                onPress: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context2) =>
                          CreateEventScreen(
                              communityId: amityCommunity.communityId!,
                              communityLocation: amityCommunity.metadata?['location'],
                          )));
                },
                icon: Icons.event),
            if(!Provider
                .of<CommuFeedVM>(context, listen: false)
                .isLeagueCommunity)_renderChildButton(
                context: context,
                margin: const EdgeInsets.only(bottom: 0),
                title: "Share Open Matches",
                onPress: () {
                  showCommonModalBottomSheet(
                      ShareMatchModal(communityId: amityCommunity.communityId!));
                },
                icon: Icons.ios_share_outlined),
          ],
          childrenButtonSize: const Size(72, 80),
          overlayColor: Colors.black,
          overlayOpacity: 0.85,
          childMargin: const EdgeInsets.only(bottom: 10),
          activeChild: _renderButton(true, context),
          child: _renderButton(false, context),
        )
            : SizedBox(),
        appBar: AppBar(
          scrolledUnderElevation: 0,
          title: Text(title),
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Icon(
              Icons.chevron_left,
              color: Provider
                  .of<AmityUIConfiguration>(context)
                  .appColors
                  .base,
              size: 30,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            // Text(
            //     "${sizeVM.getCommunityDetailSectionSize()}"),
            IconButton(
                onPressed: () {
                  handleShareContent(
                      metadata: {"type": "community", "communityId": amityCommunity.communityId ?? ""},
                      title: amityCommunity.displayName ?? "",
                      description: amityCommunity.description ?? "",
                      shouldShare: true);
                },
                icon: Icon(
                  Icons.ios_share_outlined,
                  color: Provider
                      .of<AmityUIConfiguration>(context)
                      .appColors
                      .base,
                )),
            IconButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context2) =>
                          CommunitySettingPage(
                            community: amityCommunity,
                          )));
                },
                icon: Icon(
                  Icons.more_horiz_rounded,
                  color: Provider
                      .of<AmityUIConfiguration>(context)
                      .appColors
                      .base,
                ))
          ],
        ),
        body: RefreshIndicator(
          color: Provider
              .of<AmityUIConfiguration>(context)
              .primaryColor,
          onRefresh: () async {
            // Call your method to refresh the list here.
            // For example, you might want to refresh the community feed.
            Provider.of<CommuFeedVM>(context, listen: false).getPostCount(amityCommunity);
            Provider.of<CommuFeedVM>(context, listen: false)
                .getReviewingPostCount(amityCommunity);
            await Provider.of<CommuFeedVM>(context, listen: false)
                .initAmityCommunityFeed(amityCommunity.communityId!);
            await Provider.of<CommuFeedVM>(context, listen: false)
                .initAmityPendingCommunityFeed(
                amityCommunity.communityId!, AmityFeedType.REVIEWING);
          },
          child: CustomScrollView(
            controller: Provider
                .of<CommuFeedVM>(context)
                .scrollcontroller,
            slivers: slivers,
            reverse: reverse,
          ),
        ),
      ),
    );
  }

  SpeedDialChild _renderChildButton({required EdgeInsets margin,
    required String title,
    required IconData icon,
    required VoidCallback onPress,
    required BuildContext context}) {
    final primaryColor = Provider
        .of<AmityUIConfiguration>(context)
        .appColors
        .primary;
    return SpeedDialChild(
        elevation: 0,
        backgroundColor: Colors.transparent,
        onTap: onPress,
        labelWidget: Container(
          margin: const EdgeInsets.only(bottom: 5),
          child: Text(
            title,
            style: const TextStyle(
                fontSize: 14, height: 1.71, letterSpacing: -0.28, color: Colors.white),
          ),
        ),
        child: Container(
          margin: margin,
          child: Row(
            children: [
              const SizedBox(width: 10),
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(50),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: primaryColor),
              ),
            ],
          ),
        ));
  }

  Widget _renderButton(isOpen, BuildContext context) {
    final primaryColor = Provider
        .of<AmityUIConfiguration>(context)
        .appColors
        .primary;
    return Container(
      height: 54,
      width: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: primaryColor,
          border: Border.all(color: isOpen ? primaryColor : Colors.white, width: 2),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
                offset: const Offset(-1, 1),
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6),
            BoxShadow(
                offset: const Offset(1, 1),
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6)
          ]),
      child: Transform.rotate(
        angle: isOpen ? math.pi / 2 : 0,
        child: isOpen
            ? const Icon(Icons.close, color: Colors.white)
            : const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header({Key? key,
    this.index,
    this.title,
    this.color = Colors.lightBlue,
    required this.onChangedTab})
      : super(key: key);

  final String? title;
  final int? index;
  final Color color;
  final VoidCallback onChangedTab;

  @override
  Widget build(BuildContext context) {
    return Consumer<CommuFeedVM>(builder: (context, vm, _) {
      return index == 0
          ? const SizedBox()
          : Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                color: Provider
                    .of<AmityUIConfiguration>(context)
                    .appColors
                    .baseBackground,
                child: TabBar(
                  onTap: ((value) {
                    vm.changeTab();
                  }),
                  controller: vm.userFeedTabController,
                  isScrollable: true,
                  dividerColor: HexColor('#6C727540'),
                  tabAlignment: TabAlignment.start,
                  indicatorColor: HexColor('#4E8A6D'),
                  indicatorWeight: 2,
                  indicatorSize: TabBarIndicatorSize.tab,
                  unselectedLabelColor: HexColor('#6C7275'),
                  labelStyle: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF Pro Text',
                      color: HexColor('#4E8A6D')
                  ),
                  tabs: [
                    Tab(text: "Timeline"),
                    Tab(text: "Events"),
                    if(vm.communityRankingEnabled.value)
                      Tab(text: "Rankings"),
                    Tab(text: "Matches"),
                    Tab(text: "Gallery"),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

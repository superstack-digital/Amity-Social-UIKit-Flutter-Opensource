import 'dart:developer';

import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/components/alert_dialog.dart';
import 'package:amity_uikit_beta_service/view/social/select_user_page.dart';
import 'package:amity_uikit_beta_service/view/user/user_profile_v2.dart';
import 'package:amity_uikit_beta_service/viewmodel/community_member_viewmodel.dart';
import 'package:amity_uikit_beta_service/viewmodel/community_viewmodel.dart';
import 'package:amity_uikit_beta_service/viewmodel/configuration_viewmodel.dart';
import 'package:amity_uikit_beta_service/viewmodel/user_feed_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app_padel/features/community/presentation/screens/people_profile_screen.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:mobile_app_padel/shared/widgets/initial_avatar.dart';
import 'package:mobile_app_padel/shared/shared_preferences.dart';

class MemberManagementPage extends StatefulWidget {
  final String communityId;
  final String? channelId;

  const MemberManagementPage({
    Key? key,
    required this.communityId,
    this.channelId
  }) : super(key: key);

  @override
  State<MemberManagementPage> createState() => _MemberManagementPageState();
}

class _MemberManagementPageState extends State<MemberManagementPage> {
  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      final amityReactions = <AmityReaction>[];
      late PagingController<AmityReaction> reactionController;

      void queryPostReaction(String postId) {
        reactionController = PagingController(
          pageFuture: (token) => AmitySocialClient.newPostRepository()
              .getReaction(postId: postId)
              //Optional to query specific reaction, eg. "like"
              .reactionName('like')
              .getPagingData(token: token, limit: 20),
          pageSize: 20,
        )..addListener(
            () {
              if (reactionController.error == null) {
                //handle results, we suggest to clear the previous items
                //and add with the latest _controller.loadedItems
                amityReactions.clear();
                amityReactions.addAll(reactionController.loadedItems);
                //update widgets
              } else {
                //error on pagination controller
                //update widgets
              }
            },
          );
      }

      Provider.of<MemberManagementVM>(context, listen: false).initMember(
        communityId: widget.communityId,
      );
      Provider.of<MemberManagementVM>(context, listen: false).initModerators(
        communityId: widget.communityId,
      );
      Provider.of<MemberManagementVM>(context, listen: false)
          .checkCurrentUserRole(widget.communityId);

      Provider.of<MemberManagementVM>(context, listen: false)
          .initChannelId(widget.channelId);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor:
            Provider.of<AmityUIConfiguration>(context).appColors.baseBackground,
        appBar: AppBar(
          actions: [
            !Provider.of<MemberManagementVM>(context)
                    .currentUserRoles
                    .contains('community-moderator')
                ? const SizedBox()
                : IconButton(
                    icon: Icon(
                      Icons.add,
                      color: Provider.of<AmityUIConfiguration>(context)
                          .appColors
                          .base,
                    ),
                    onPressed: () async {
                      var userList = Provider.of<MemberManagementVM>(context,
                              listen: false)
                          .userList;
                      List<AmityUser> userIdList =
                          userList.map((user) => user.user!).toList();
                      Navigator.of(context)
                          .push<List<AmityUser>>(MaterialPageRoute(
                              builder: (context) => UserListPage(
                                    preSelectMember: userIdList,
                                    onDonePressed: (users) async {
                                      List<String> userIds = users
                                          .map((user) => user.userId!)
                                          .toList();
                                      if (users.isNotEmpty) {
                                        await Provider.of<CommunityVM>(context,
                                                listen: false)
                                            .addMembers(
                                                widget.communityId, userIds);
                                        await Provider.of<MemberManagementVM>(
                                                context,
                                                listen: false)
                                            .initMember(
                                          communityId: widget.communityId,
                                        );
                                        await Provider.of<MemberManagementVM>(
                                                context,
                                                listen: false)
                                            .initModerators(
                                          communityId: widget.communityId,
                                        );
                                        Navigator.of(context).pop();
                                        if(widget.channelId != null){
                                          AmityChatClient.newChannelRepository().addMembers(widget.channelId!, userIds);
                                        }
                                      } else {
                                        log('Failed to add members');
                                      }
                                    },
                                  )));
                    },
                  ),
          ],
          elevation: 0.0,
          iconTheme: const IconThemeData(color: Colors.black),
          backgroundColor: Provider.of<AmityUIConfiguration>(context)
              .appColors
              .baseBackground,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.chevron_left,
                color:
                    Provider.of<AmityUIConfiguration>(context).appColors.base,
                size: 30),
          ),
          title: Text("Community",
              style: Provider.of<AmityUIConfiguration>(context)
                  .titleTextStyle
                  .copyWith(
                    color: Provider.of<AmityUIConfiguration>(context)
                        .appColors
                        .base,
                  )),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(
                48.0), // Provide a height for the AppBar's bottom
            child: TabBar(
              dividerColor: HexColor('#6C727540'),
              indicatorColor: HexColor('#141718'),
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.tab,
              unselectedLabelColor: HexColor('#6C7275'),
              labelStyle: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Text',
                  color: HexColor('#141718')
              ),
              tabs: const [
                Tab(text: "Members"),
                Tab(text: "Moderators"),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            MemberList(), // You need to create a MemberList widget
            ModeratorList(), // You need to create a ModeratorList widget
          ],
        ),
      ),
    );
  }
}
// Import statements remain the same

class MemberList extends StatelessWidget {
  const MemberList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MemberManagementVM>(
      builder: (context, viewModel, child) {
        return ListView.builder(
          controller: viewModel.scrollController,
          itemCount: viewModel.userList.length,
          itemBuilder: (context, index) {
            final avatarUrl = viewModel.userList[index].user?.avatarUrl ?? viewModel.userList[index].user?.avatarCustomUrl;
            return ListTile(
              onTap: () {
                if(int.tryParse(viewModel.userList[index].user?.userId ?? '0') != null){
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                          create: (context) => UserFeedVM(),
                          child: PeopleProfileScreen(
                            userId: int.parse(viewModel.userList[index].user!.userId!),
                          ))));
                }

              },
              leading: avatarUrl ==
                  null ? InitialAvatar(height: 40, width: 40, fullName: viewModel.userList[index].user?.displayName ?? "") : CircleAvatar(
                backgroundColor: Provider.of<AmityUIConfiguration>(context)
                    .appColors
                    .primaryShade3,
                backgroundImage: avatarUrl ==
                        null
                    ? null
                    : NetworkImage(avatarUrl),
                child: avatarUrl != null
                    ? null
                    : const Icon(Icons.person, size: 20, color: Colors.white),
              ),
              title: Text(
                viewModel.userList[index].user?.displayName ?? '',
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Provider.of<AmityUIConfiguration>(context)
                        .appColors
                        .base),
              ),
              trailing: IconButton(
                icon: Icon(Icons.more_horiz_rounded,
                    color: Provider.of<AmityUIConfiguration>(context)
                        .appColors
                        .base),
                onPressed: () {
                  _showOptionsBottomSheet(
                      context, viewModel.userList[index], viewModel,
                      showDemoteButton: false);
                },
              ),
            );
          },
        );
      },
    );
  }
}

class ModeratorList extends StatelessWidget {
  const ModeratorList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MemberManagementVM>(
      builder: (context, viewModel, child) {
        return ListView.builder(
          itemCount: viewModel.moderatorList.length,
          controller: viewModel.scrollControllerForModerator,
          itemBuilder: (context, index) {
            final moderator = viewModel.moderatorList[index];
            final avatarUrl = moderator.user?.avatarUrl;
            return ListTile(
              onTap: () async {
                final userId = int.tryParse(moderator.user?.userId ?? '0');
                final currentUser = await PreferenceUtils().getUserInfo();
                final currentUserId = currentUser?.id;

                if(userId != null && userId != currentUserId){
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                          create: (context) => UserFeedVM(),
                          child: PeopleProfileScreen(
                            userId: int.parse(moderator.user!.userId!),
                          ))));
                }
              },
              leading: avatarUrl == null ? InitialAvatar(height: 40, width: 40, fullName: viewModel.moderatorList[index].user?.displayName ?? "") : CircleAvatar(
                backgroundColor: Provider.of<AmityUIConfiguration>(context)
                    .appColors
                    .primaryShade3,
                backgroundImage:
              NetworkImage(viewModel.moderatorList[index].user!.avatarUrl!),
                child: viewModel.moderatorList[index].user?.avatarUrl != null
                    ? null
                    : const Icon(Icons.person,
                        size: 20,
                        color: Colors
                            .white), // Adjust to use the correct attribute for avatar URL
              ),
              title: Text(
                viewModel.moderatorList[index].user?.displayName ?? '',
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.more_horiz,
                  color: Colors.black,
                ),
                onPressed: () {
                  _showOptionsBottomSheet(
                      context, viewModel.moderatorList[index], viewModel);
                },
              ),
            );
          },
        );
      },
    );
  }
}

void _showOptionsBottomSheet(BuildContext context, AmityCommunityMember member,
    MemberManagementVM viewModel,
    {bool showDemoteButton = true}) {
  bool isModerator = viewModel.currentUserRoles.contains('community-moderator');

  showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext bc) {
        return Container(
          padding: const EdgeInsets.only(top: 20, bottom: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          child: Wrap(
            children: isModerator
                ? [
                    member.roles!.contains('community-moderator') &
                            !showDemoteButton
                        ? const SizedBox()
                        : ListTile(
                            title: Text(
                              member.roles!.contains('community-moderator')
                                  ? 'Dismiss moderator'
                                  : 'Promote to moderator',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            onTap: () async {
                              Navigator.pop(context);
                              if (member.roles!
                                  .contains('community-moderator')) {
                                await viewModel.demoteFromModerator(
                                    viewModel.communityId, [member.userId!]);
                              } else {
                                await viewModel.promoteToModerator(
                                    viewModel.communityId, [member.userId!]);
                              }

                              Future.delayed(Duration(seconds: 3), () async{
                                await viewModel.initModerators(
                                    communityId: viewModel.communityId);
                                await viewModel.initMember(
                                  communityId: viewModel.communityId
                                );
                              });
                            },
                          ),
                    ListTile(
                      title: Text(
                        member.user!.isFlaggedByMe ? "Undo Report" : "Report",
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      onTap: () async {
                        if (member.user!.isFlaggedByMe) {
                          await viewModel.undoReportUser(member.user!);
                        } else {
                          await viewModel.reportUser(member.user!);
                        }
                        await viewModel.initModerators(
                            communityId: viewModel.communityId);
                        await viewModel.initMember(
                          communityId: viewModel.communityId,
                        );
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      title: const Text(
                        'Block User',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      onTap: () {
                        viewModel.blockUser(member.user!);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      title: const Text(
                        'Remove from community',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w500),
                      ),
                      onTap: () async {
                        Navigator.pop(context);
                        await ConfirmationDialog().show(
                          context: context,
                          title: 'Remove user from Community?',
                          detailText:
                              "This user won't no longer be able to search, post and interact in this community",
                          onConfirm: () {
                            viewModel.removeMembers(
                                viewModel.communityId, [member.userId!]);
                            if(viewModel.channelId != null){
                              AmityChatClient.newChannelRepository().removeMembers(viewModel.channelId!, [member.userId!]);
                            }
                          },
                        );
                        await viewModel.initModerators(
                            communityId: viewModel.communityId);
                        await viewModel.initMember(
                          communityId: viewModel.communityId,
                        );
                      },
                    ),
                  ]
                : [
                    ListTile(
                      title: const Text(
                        'Block User',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      onTap: () {
                        viewModel.blockUser(member.user!);
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      title: const Text(
                        'Report',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      onTap: () {
                        viewModel.reportUser(member.user!);
                        Navigator.pop(context);
                      },
                    ),
                  ],
          ),
        );
      });
}

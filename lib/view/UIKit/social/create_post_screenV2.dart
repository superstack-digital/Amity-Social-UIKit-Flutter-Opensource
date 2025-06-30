import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/components/alert_dialog.dart';
import 'package:amity_uikit_beta_service/view/UIKit/social/community_setting/posts/post_cpmponent.dart';
import 'package:amity_uikit_beta_service/viewmodel/community_feed_viewmodel.dart';
import 'package:amity_uikit_beta_service/viewmodel/community_member_viewmodel.dart';
import 'package:amity_uikit_beta_service/viewmodel/configuration_viewmodel.dart';
import 'package:amity_uikit_beta_service/viewmodel/create_postV2_viewmodel.dart';

// import 'package:amity_uikit_beta_service/viewmodel/create_post_viewmodel.dart';
// import 'package:amity_uikit_beta_service/viewmodel/media_viewmodel.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../social/global_feed.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_app_padel/shared/asset_keys.dart';
import 'package:mobile_app_padel/features/community/widgets/share_match_modal.dart';
import 'package:mobile_app_padel/features/community/presentation/controllers/share_open_matches_controller.dart';
import 'package:mobile_app_padel/features/play/presentation/widgets/court_match_item.dart';
import 'package:get/get.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mobile_app_padel/shared/styles.dart';
import 'package:mobile_app_padel/shared/styles.dart';
import 'package:mobile_app_padel/features/community/widgets/create_post_text_field.dart';

class AmityCreatePostV2Screen extends StatefulWidget {
  final AmityCommunity? community;
  final AmityUser? amityUser;
  final bool isFromPostToPage;
  final FeedType? feedType;

  const AmityCreatePostV2Screen({super.key,
    this.community,
    this.amityUser,
    this.isFromPostToPage = false,
    this.feedType});

  @override
  State<AmityCreatePostV2Screen> createState() =>
      _AmityCreatePostV2ScreenState();
}

class _AmityCreatePostV2ScreenState extends State<AmityCreatePostV2Screen> {
  bool hasContent = true;

  @override
  void initState() {
    Provider.of<CreatePostVMV2>(context, listen: false).inits();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<CreatePostVMV2>(builder: (consumerContext, vm, _) {
      return Scaffold(
        backgroundColor:
        Provider
            .of<AmityUIConfiguration>(context)
            .appColors
            .baseBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            widget.community != null
                ? widget.community?.displayName ?? "Community"
                : "My Feed",
            style: Provider
                .of<AmityUIConfiguration>(context)
                .titleTextStyle
                .copyWith(
                color: Provider
                    .of<AmityUIConfiguration>(context)
                    .appColors
                    .base),
          ),
          leading: IconButton(
            icon: Icon(Icons.chevron_left,
                color:
                Provider
                    .of<AmityUIConfiguration>(context)
                    .appColors
                    .base),
            onPressed: () {
              if (hasContent) {
                ConfirmationDialog().show(
                  context: context,
                  title: 'Discard Post?',
                  detailText: 'Do you want to discard your post?',
                  leftButtonText: 'Cancel',
                  rightButtonText: 'Discard',
                  onConfirm: () {
                    Navigator.of(context).pop();
                  },
                );
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: hasContent
                  ? () async {
                if (vm.isUploadComplete) {
                  if (widget.community == null) {
                    //creat post in user Timeline
                    await vm.createPost(context,
                        callback: (isSuccess, error) {
                          if (isSuccess) {
                            Navigator.of(context).pop();
                            if (widget.isFromPostToPage) {
                              Navigator.of(context).pop();
                            }
                          } else {}
                        });
                  } else {
                    //create post in Community
                    await vm.createPost(context,
                        communityId: widget.community?.communityId!,
                        callback: (isSuccess, error) async {
                          if (isSuccess) {
                            var roleVM = Provider.of<MemberManagementVM>(
                                context,
                                listen: false);
                            roleVM.checkCurrentUserRole(
                                widget.community!.communityId!);

                            if (widget.community!.isPostReviewEnabled!) {
                              if (!widget.community!.hasPermission(
                                  AmityPermission.REVIEW_COMMUNITY_POST)) {
                                await AmityDialog().showAlertErrorDialog(
                                    title: "Post submitted",
                                    message:
                                    "Your post has been submitted to the pending list. It will be reviewed by community moderator");
                              }
                            }
                            Navigator.of(context).pop();
                            if (widget.isFromPostToPage) {
                              Navigator.of(context).pop();
                            }
                            if (widget.community!.isPostReviewEnabled!) {
                              Provider.of<CommuFeedVM>(context, listen: false)
                                  .initAmityPendingCommunityFeed(
                                  widget.community!.communityId!,
                                  AmityFeedType.REVIEWING);
                            }

                            // Navigator.of(context).push(MaterialPageRoute(
                            //     builder: (context) => ChangeNotifierProvider(
                            //           create: (context) => CommuFeedVM(),
                            //           child: CommunityScreen(
                            //             isFromFeed: true,
                            //             community: widget.community!,
                            //           ),
                            //         )));
                          }
                        });
                  }
                }
              }
                  : null,
              child: Text("Post",
                  style: TextStyle(
                      color: vm.isPostValid
                          ? Provider
                          .of<AmityUIConfiguration>(context)
                          .primaryColor
                          : Colors.grey)),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // TextField(
                        //   style: TextStyle(
                        //       color: Provider
                        //           .of<AmityUIConfiguration>(context)
                        //           .appColors
                        //           .base),
                        //   onChanged: (value) => vm.updatePostValidity(),
                        //   controller: vm.textEditingController,
                        //   scrollPhysics: const NeverScrollableScrollPhysics(),
                        //   maxLines: null,
                        //   decoration: InputDecoration(
                        //     border: InputBorder.none,
                        //     hintText: "Write something to post",
                        //     hintStyle: TextStyle(
                        //         color:
                        //         Provider
                        //             .of<AmityUIConfiguration>(context)
                        //             .appColors
                        //             .userProfileTextColor),
                        //   ),
                        //   // style: t/1heme.textTheme.bodyText1.copyWith(color: Colors.grey),
                        // ),
                        MentionInput(
                            // style: TextStyle(
                            //     color: Provider
                            //         .of<AmityUIConfiguration>(context)
                            //         .appColors
                            //         .base),
                            onChanged: (value) => vm.updatePostValidity(),
                            controller: vm.textEditingController,
                            onMentionsChanged: vm.onMentionChanged,
                            communityId: widget.community?.communityId ?? "",
                            // decoration: InputDecoration(
                            //   border: InputBorder.none,
                            //   hintText: "Write something to post",
                            //   hintStyle: TextStyle(
                            //       color:
                            //       Provider
                            //           .of<AmityUIConfiguration>(context)
                            //           .appColors
                            //           .userProfileTextColor),
                            // ),
                        ),
                        Consumer<CreatePostVMV2>(
                          builder: (context, vm, _) =>
                              PostMedia(files: vm.files),
                        ),
                        Consumer<CreatePostVMV2>(
                          builder: (context, vm, _) =>
                          vm.match != null
                              ?
                          CourtMatchItem(match: vm.match!,
                              onInvitePlayer: () {},
                              onRemovePress: (){
                                vm.removeMatch();
                              },
                              showRemoveButton: true)
                              : SizedBox(),
                        ),
                        Consumer<CreatePostVMV2>(
                          builder: (context, vm, _) =>
                          vm.hasLink && vm.link != null
                              ?
                              LinkPreview(onPreviewDataFetched: vm.onLinkFetched, previewData: vm.previewData, text: vm.link!, width: Get.width - 32,
      previewBuilder: (context, data) {return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if(vm.previewData?.link != null)
            ...[GestureDetector(
              child: Text(
                vm.previewData!.link!,
                style: TextStyle(
                    color: Styles.green, decoration: TextDecoration.underline),
              ),
            ),
              SizedBox(height: 5)
            ],
          if(vm.previewData?.image?.url != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(imageUrl: vm.previewData!.image!.url, width: Get.width - 32, height: 150, fit: BoxFit.cover
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    onPressed: () {
                      vm.removeLink();
                    },
                    icon: SvgPicture.asset(
                      AssetKeys.closeCircle,
                      height: 24,
                      width: 24,
                      colorFilter: ColorFilter.mode(Styles.gray8B9197, BlendMode.srcIn),
                    ),
                  ),
                )
              ],
            ),
        ],
      );}
                              )
                              : SizedBox(),
                        )

                      ],
                    ),
                  ),
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _iconButton(
                      Icons.camera_alt_outlined,
                      isEnable:
                      vm.availableFileSelectionOptions()[MyFileType.image]!,
                      label: "Photo",
                      // debugingText:
                      //     "${vm2.isNotSelectVideoYet()}&& ${vm2.isNotSelectedFileYet()}",
                      onTap: () {
                        _handleCameraTap(context);
                      },
                    ),
                    _iconButton(
                      Icons.image_outlined,
                      label: "Image",
                      isEnable:
                      vm.availableFileSelectionOptions()[MyFileType.image]!,
                      onTap: () async {
                        _handleImageTap(context);
                      },
                    ),
                    _iconButton(
                      Icons.play_circle_outline,
                      label: "Video",
                      isEnable:
                      vm.availableFileSelectionOptions()[MyFileType.video]!,
                      onTap: () async {
                        _handleVideoTap(context);
                      },
                    ),
                    _iconButton(
                      Icons.attach_file_outlined,
                      label: "File",
                      isEnable:
                      vm.availableFileSelectionOptions()[MyFileType.file]!,
                      onTap: () async {
                        _handleFileTap(context);
                      },
                    ),
                    _iconButton(
                      Icons.more_horiz,
                      isEnable: true,
                      label: "More",
                      onTap: () {
                        // TODO: Implement more options logic
                        _showMoreOptions(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _iconButton(IconData icon,
      {required String label,
        required VoidCallback onTap,
        required bool isEnable,
        String? debugingText, String? svgAsset}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        debugingText == null ? const SizedBox() : Text(debugingText),
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.grey[200],
          child: svgAsset != null ? SvgPicture.asset(
              svgAsset, height: 16.25, width: 16.25) : IconButton(
            icon: Icon(
              icon,
              size: 18,
              color: isEnable ? Colors.black : Colors.grey,
            ),
            onPressed: () {
              if (isEnable) {
                onTap();
              }
            },
          ),
        ),
        // SizedBox(height: 4),
        // Text(label),
      ],
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return Consumer<CreatePostVMV2>(builder: (consumerContext, vm, _) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15.0),
                topRight: Radius.circular(15.0),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0), // Space at the top
                child: Wrap(
                  children: <Widget>[
                    ListTile(
                      leading: _iconButton(Icons.camera_alt_outlined,
                          isEnable: vm.availableFileSelectionOptions()[
                          MyFileType.image]!,
                          label: "Camera",
                          onTap: () {}),
                      title: Text(
                        'Camera',
                        style: TextStyle(
                            color: vm.availableFileSelectionOptions()[
                            MyFileType.image]!
                                ? Colors.black
                                : Colors.grey),
                      ),
                      onTap: () {
                        if (vm.availableFileSelectionOptions()[
                        MyFileType.image]!) {
                          _handleImageTap(context);
                          Navigator.pop(context);
                        }
                      },
                    ),
                    ListTile(
                      leading: _iconButton(Icons.image_outlined,
                          isEnable: vm.availableFileSelectionOptions()[
                          MyFileType.image]!,
                          label: "Photo",
                          onTap: () {}),
                      title: Text(
                        'Photo',
                        style: TextStyle(
                            color: vm.availableFileSelectionOptions()[
                            MyFileType.image]!
                                ? Colors.black
                                : Colors.grey),
                      ),
                      onTap: () {
                        if (vm.availableFileSelectionOptions()[
                        MyFileType.image]!) {
                          _handleImageTap(context);
                          Navigator.pop(context);
                        }
                      },
                    ),
                    ListTile(
                      leading: _iconButton(Icons.attach_file_rounded,
                          isEnable: vm.availableFileSelectionOptions()[
                          MyFileType.file]!,
                          label: "Attachment",
                          onTap: () {}),
                      title: Text(
                        'Attachment',
                        style: TextStyle(
                            color: vm.availableFileSelectionOptions()[
                            MyFileType.file]!
                                ? Colors.black
                                : Colors.grey),
                      ),
                      onTap: () {
                        if (vm.availableFileSelectionOptions()[
                        MyFileType.file]!) {
                          _handleFileTap(context);
                          Navigator.pop(context);
                        }
                      },
                    ),
                    ListTile(
                      leading: _iconButton(
                        Icons.play_circle_outline_outlined,
                        isEnable: vm
                            .availableFileSelectionOptions()[MyFileType.video]!,
                        label: "Video",
                        onTap: () {},
                      ),
                      title: Text(
                        'Video',
                        style: TextStyle(
                            color: vm.availableFileSelectionOptions()[
                            MyFileType.video]!
                                ? Colors.black
                                : Colors.grey),
                      ),
                      onTap: () {
                        if (vm.availableFileSelectionOptions()[
                        MyFileType.video]!) {
                          _handleVideoTap(context);
                          Navigator.pop(context);
                        }
                      },
                    ),
                    ListTile(
                      leading: _iconButton(
                          Icons.play_circle_outline_outlined,
                          isEnable: vm
                              .availableFileSelectionOptions()[MyFileType.video]!,
                          label: "Matches",
                          onTap: () {},
                          svgAsset: AssetKeys.matchIcon
                      ),
                      title: Text(
                        'Matches',
                        style: TextStyle(
                            color: vm.availableFileSelectionOptions()[
                            MyFileType.video]!
                                ? Colors.black
                                : Colors.grey),
                      ),
                      onTap: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (modalContext) =>
                                ShareMatchModal(communityId: '',
                                    title: "Share Matches",
                                    onResult: (match) {
                                      Provider.of<CreatePostVMV2>(context,
                                          listen: false)
                                          .addMatch(match);
                                      Navigator.pop(context);
                                      Navigator.of(modalContext).pop();
                                    })).then((val){
                                      Get.delete<ShareOpenMatchesController>();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text('Discard Post?'),
            content: const Text('Do you want to discard your post?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  Navigator.of(context).pop();
                },
                child: const Text('Discard'),
              ),
            ],
          ),
    );
  }

  Future<void> _handleCameraTap(BuildContext context) async {
    await _pickMedia(context, PickerAction.cameraImage);
  }

  Future<void> _handleImageTap(BuildContext context) async {
    await _pickMedia(context, PickerAction.galleryImage);
  }

  Future<void> _handleVideoTap(BuildContext context) async {
    await _pickMedia(context, PickerAction.galleryVideo);
  }

  Future<void> _handleFileTap(BuildContext context) async {
    await _pickMedia(context, PickerAction.filePicker);
  }

  Future<void> _pickMedia(BuildContext context, PickerAction action) async {
    var createPostVM = Provider.of<CreatePostVMV2>(context, listen: false);
    await createPostVM.pickFile(action);
  }
}

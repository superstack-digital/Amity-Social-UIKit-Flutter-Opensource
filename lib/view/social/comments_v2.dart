import 'dart:developer';

import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/components/alert_dialog.dart';
import 'package:amity_uikit_beta_service/components/post_profile.dart';
import 'package:amity_uikit_beta_service/components/skeleton.dart';
import 'package:amity_uikit_beta_service/view/UIKit/social/general_component.dart';
import 'package:amity_uikit_beta_service/view/social/global_feed.dart';
import 'package:amity_uikit_beta_service/view/social/post_content_widget.dart';
import 'package:amity_uikit_beta_service/viewmodel/amity_viewmodel.dart';
import 'package:amity_uikit_beta_service/viewmodel/reply_viewmodel.dart';
import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../components/custom_user_avatar.dart';
import '../../viewmodel/configuration_viewmodel.dart';
import '../../viewmodel/post_viewmodel.dart';
import '../../viewmodel/edit_comment_viewmodel.dart';
import 'package:mobile_app_padel/features/profile/data/match.dart';
import 'package:mobile_app_padel/shared/widgets/richtext_with_mention.dart';
import 'package:mobile_app_padel/shared/constants.dart';
import 'package:mobile_app_padel/shared/widgets/create_post_text_field.dart';
import 'package:mobile_app_padel/features/community/presentation/screens/people_profile_screen.dart';
import 'package:mobile_app_padel/shared/widgets/mention_text_field.dart';
import 'package:mobile_app_padel/shared/widgets/shadow_avatar.dart';
import 'package:mobile_app_padel/shared/styles.dart';
import 'package:fluttertagger/fluttertagger.dart';
import 'package:mobile_app_padel/features/profile/data/repositories/match_repository.dart';
import 'package:mobile_app_padel/features/community/data/models/event.dart';
import 'package:mobile_app_padel/features/community/data/models/event_standing.dart';
import 'package:mobile_app_padel/features/community/data/repositories/event_repository.dart';
import 'package:amity_uikit_beta_service/v4/social/post/post_item/post_item_updated.dart';
import 'package:amity_uikit_beta_service/v4/social/post/post_item/bloc/post_item_bloc.dart';
import 'package:amity_uikit_beta_service/v4/social/post/common/post_action.dart';
import 'package:mobile_app_padel/features/community/data/models/community_ranking_data.dart';
import 'package:amity_uikit_beta_service/v4/utils/post_data_cache_manager.dart';

class CommentScreenV2 extends StatefulWidget {
  final AmityPost amityPost;
  final ThemeData theme;
  final bool isFromFeed;
  final FeedType feedType;
  final IMatch? match;
  final IMatch? matchResult;
  final Event? event;
  final List<EventStanding>? eventStanding;
  const CommentScreenV2({
    Key? key,
    required this.amityPost,
    required this.theme,
    required this.isFromFeed,
    required this.feedType,
    this.match,
    this.matchResult,
    this.event,
    this.eventStanding
  }) : super(key: key);

  @override
  CommentScreenV2State createState() => CommentScreenV2State();
}

class Comments {
  String image;
  String name;

  Comments(this.image, this.name);
}

class CommentScreenV2State extends State<CommentScreenV2> {
  final _commentTextEditController = TextEditingController();
  final GlobalKey<MentionTextFieldState> commentTextFieldKey = GlobalKey();
  List<CommunityRankingData>? _communityRanking;


  @override
  void initState() {
    Provider.of<ReplyVM>(context, listen: false).clearReply();
    //query comment here
    Provider.of<PostVM>(context, listen: false)
        .getPost(widget.amityPost.postId!, widget.amityPost);

    _loadWeeklyRankingIfNeeded();
    super.initState();
  }

  Future<void> _loadWeeklyRankingIfNeeded() async {
    final metadata = widget.amityPost.metadata;
    if (metadata?['type'] != 'weekly_ranking') return;

    final communityId = metadata?['communityId'] as String?;
    final eventType = metadata?['eventType'] as String?;
    final startDate = metadata?['startDate'] as String?;
    final endDate = metadata?['endDate'] as String?;

    if (communityId != null && eventType != null && startDate != null && endDate != null) {
      final cacheManager = PostDataCacheManager();
      final rankings = await cacheManager.getCommunityRankingData(
        communityId,
        eventType,
        startDate,
        endDate,
      );

      if (mounted) {
        setState(() {
          _communityRanking = rankings;
        });
      }
    }
  }

  bool isMediaPosts() {
    final childrenPosts =
        Provider.of<PostVM>(context, listen: false).amityPost.children;
    if (childrenPosts != null && childrenPosts.isNotEmpty) {
      return true;
    }
    return false;
    // return true;
  }

  Widget mediaPostWidgets() {
    AmityPost parentPost =
        Provider.of<PostVM>(context, listen: false).amityPost;
    List<AmityPost> childrenPosts = parentPost.children ?? [];
    if (childrenPosts.isNotEmpty) {
      return AmityPostWidget(
        childrenPosts,
        true,
        false,
        haveChildrenPost: true,
        widget.feedType,
      );
    }
    // else {
    //   TextData textData = parentPost.data as TextData;
    //   if (textData.text != null) {
    //     return  AmityPostWidget(
    //       [parentPost],
    //       false,
    //       false,
    //       haveChildrenPost: false,
    //       shouldShowTextPost: false,
    //     );
    //   } else {
    //     return Container();
    //   }
    // }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    var postData =
        Provider.of<PostVM>(context, listen: false).amityPost.data as TextData;
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final bHeight = mediaQuery.size.height - mediaQuery.padding.top;

      return Consumer<PostVM>(builder: (context, vm, _) {
        return Stack(
          children: [
            StreamBuilder<AmityPost>(
                key: Key(postData.postId),
                stream: vm.amityPost.listen.stream,
                initialData: vm.amityPost,
                builder: (context, snapshot) {
                  var snapshotPostData = snapshot.data?.data as TextData;
                  var actionSection = Column(
                    children: [
                      Container(
                        color: widget.feedType == FeedType.user
                            ? Provider.of<AmityUIConfiguration>(context)
                            .appColors
                            .userProfileBGColor
                            : Colors.white,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(width: 20), // Spacing between buttons
                            // Like Button
                            GestureDetector(
                              onTap: () {
                                // Logic to handle like action
                              },
                              child: Row(
                                children: [
                                  snapshot.data!.myReactions!.isNotEmpty
                                      ? GestureDetector(
                                    onTap: () {
                                      Provider.of<PostVM>(context,
                                          listen: false)
                                          .removePostReaction(widget.amityPost);
                                    },
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          "assets/Icons/like.svg",
                                          package: 'amity_uikit_beta_service',
                                        ),
                                        const Text(
                                          "Like",
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
                                      log(widget.amityPost.myReactions!
                                          .toString());
                                      Provider.of<PostVM>(context,
                                          listen: false)
                                          .addPostReaction(widget.amityPost);
                                    },
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.thumb_up_off_alt,
                                          color: Colors.grey,
                                          size: 16,
                                        ),
                                        Text(
                                          "Like",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Provider.of<
                                                AmityUIConfiguration>(
                                                context)
                                                .appColors
                                                .baseShade4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20), // Spacing between buttons

                            // Comment Button
                            GestureDetector(
                              onTap: () {
                                // Logic to navigate to comments section
                              },
                              child: const Row(
                                children: [
                                  Icon(Icons.chat_bubble_outline, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text(
                                    "Comment",
                                    // snapshot.data!.commentCount.toString(),
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20), // Spacing between buttons

                            // Share Button
                            // GestureDetector(
                            //   onTap: () {},
                            //   child: const Row(
                            //     children: [
                            //       Icon(Icons.ios_share_outlined, color: Colors.grey),
                            //       SizedBox(width: 4),
                            //       Text(
                            //         "Share",
                            //         style: TextStyle(color: Colors.grey),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ],
                  );

                  return Scaffold(
                    backgroundColor: Provider.of<AmityUIConfiguration>(context)
                        .appColors
                        .baseBackground,
                    body: FadedSlideAnimation(
                      beginOffset: const Offset(0, 0.3),
                      endOffset: const Offset(0, 0),
                      slideCurve: Curves.linearToEaseOut,
                      child: SafeArea(
                        child: Column(
                          children: [
                            Container(
                              alignment: Alignment.topLeft,
                              child: IconButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                icon: Icon(Icons.chevron_left,
                                    color: Provider.of<AmityUIConfiguration>(context)
                                        .appColors
                                        .base,
                                    size: 35),
                              ),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: vm.scrollcontroller,
                                child: Column(
                                  children: [
                                    Stack(
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            FocusScope.of(context).unfocus();
                                          },
                                          // color: isMediaPosts()
                                          //     ? Colors.black
                                          //     : Colors.transparent,
                                          // padding: isMediaPosts()
                                          //     ? const EdgeInsets.only(top: 285)
                                          //     : null,
                                          // // height: (bHeight - 60) * 0.6,

                                          // decoration: BoxDecoration(),
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                            children: [
                                              // Use PostItem from post_item_updated.dart
                                              BlocProvider(
                                                create: (context) => PostItemBloc(),
                                                child: PostItem(
                                                  post: snapshot.data!,
                                                  match: widget.match,
                                                  matchResult: widget.matchResult,
                                                  event: widget.event,
                                                  eventStanding: widget.eventStanding,
                                                  communityRanking: _communityRanking,
                                                  isPostDetail: true,
                                                  action: AmityPostAction(
                                                    onAddReaction: (String) {},
                                                    onRemoveReaction: (String) {},
                                                    onPostDeleted: (AmityPost post) {},
                                                    onPostUpdated: (AmityPost post) {},
                                                  ),
                                                ),
                                              ),

                                              Divider(
                                                color: Colors.grey.withValues(alpha: 0.2),
                                                height: 1,
                                              ),
                                              CommentComponent(
                                                postId: widget.amityPost.postId!,
                                                theme: theme,
                                                feedType: widget.feedType,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Provider.of<ReplyVM>(context).replyToObject == null
                                    ? const SizedBox()
                                    : Container(
                                  color: Colors.grey[200],
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "Replying to ${Provider.of<ReplyVM>(context).replyToObject?.replyingToUser.displayName}",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xff636878)),
                                        ),
                                      ),
                                      GestureDetector(
                                          onTap: () {
                                            Provider.of<ReplyVM>(context,
                                                listen: false)
                                                .clearReplyAndUpdateUI();
                                          },
                                          child: const Icon(Icons.close,
                                              color: Color(0xff636878)))
                                    ],
                                  ),
                                ),
                                CommentTextField(
                                  mentionTextFieldKey: commentTextFieldKey,
                                  postId: snapshot.data!.postId!,
                                  feedType: widget.feedType,
                                  commentTextEditController:
                                  _commentTextEditController,
                                  navigateToFullCommentPage: () {
                                    Navigator.of(context).push(MaterialPageRoute(
                                        builder: (context) => FullCommentPage(
                                          feedType: widget.feedType,
                                          commentTextEditController:
                                          _commentTextEditController,
                                          postId: snapshot.data!.postId!,
                                          postCallback: () async {
                                            Navigator.of(context).pop();
                                            HapticFeedback.heavyImpact();
                                            await Provider.of<PostVM>(context,
                                                listen: false)
                                                .createComment(
                                                snapshot.data!.postId!,
                                                _commentTextEditController
                                                    .text);
                                            _commentTextEditController.clear();
                                          },
                                        )));
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            if(vm.isLoading)
              Container(
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
              )
          ],
        );
      });
  }
}

class CommentTextField extends StatelessWidget {
  const CommentTextField({
    super.key,
    required this.commentTextEditController,
    required this.postId,
    required this.navigateToFullCommentPage,
    required this.feedType,
    required this.mentionTextFieldKey
  });

  final TextEditingController commentTextEditController;
  final String postId;
  final VoidCallback navigateToFullCommentPage;
  final FeedType feedType;
  final GlobalKey<MentionTextFieldState> mentionTextFieldKey;


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Provider.of<AmityUIConfiguration>(context)
              .appColors
              .baseBackground,
          border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)))
         ),
      child: ListTile(
          horizontalTitleGap: 0,
          contentPadding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          title: ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: 200.0, // Maximum height for the text field
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                getAvatarImage(
                    Provider.of<AmityVM>(context).currentamityUser?.avatarUrl ?? Provider.of<AmityVM>(context).currentamityUser?.avatarCustomUrl, fullName: Provider.of<AmityVM>(context).currentamityUser?.displayName),
                const SizedBox(
                  width: 10,
                ),
                Expanded(child: Consumer<PostVM>(builder: (context, vm, _){
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: 300
                    ),
                    child: MentionTextField<AmityCommunityMember>(
                        key: mentionTextFieldKey,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                                color: Styles.grayD1D3D5
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                                color: Styles.grayD1D3D5
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                                color: Styles.grayD1D3D5
                            ),
                          ),
                          hintText: "Say something nice...",
                          hintStyle: Styles.fontSFProRegular(
                            15,
                            lineHeightInPxl: 20,
                            letterSpacing: -0.24,
                            color: Styles.placeholderColor
                          ),
                          contentPadding: const EdgeInsets.only(
                            top: 8,
                            left: 16,
                            bottom: 8,
                            right: 16,
                          ),
                        ),
                        onTextChanged: (text) {
                          commentTextEditController.text = text;
                        },
                        onMentionsChanged: (mentions) {
                          vm.updateMentions(mentions);
                        },
                        overlayPadding: EdgeInsets.only(bottom: 0),
                        mentionListItemBuilder: (member){
                          return Padding(padding: EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  ShadowAvatar(
                                      height: 30,
                                      width: 30,
                                      url: member.user?.avatarCustomUrl ??
                                          member.user?.avatarUrl ??
                                          "",
                                      fullName: member.user?.displayName ?? ""),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(member.user?.displayName ?? "",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Styles.fontInterMedium(16)),
                                  )
                                ],
                              ));
                        },
                        onSearchMentions: (query) async {
                          final res = await AmityCommunityRepository()
                              .membership(
                              (vm.amityPost.target as CommunityTarget).targetCommunity?.communityId ?? "")
                              .searchMembers(
                              query)
                              .getPagingData(limit: 5);
                          return res.data;
                        },
                        onSelectTag: (AmityCommunityMember member) {
                          return CommunityTag(
                              id: member.user?.userId ?? "", name: member.user?.displayName ?? "");
                        }
                    )
                  );
                })),
                TextButton(
                    isSemanticButton: true,
                    onPressed: () async {
                      if (Provider
                          .of<ReplyVM>(context, listen: false)
                          .replyToObject ==
                          null) {
                        HapticFeedback.heavyImpact();
                        await Provider.of<PostVM>(context, listen: false)
                            .createComment(postId, commentTextEditController.text);
                      } else {
                        ///Create Comment with Reply
                        print("reply comment");
                        var replyingComment =
                            Provider
                                .of<ReplyVM>(context, listen: false)
                                .replyToObject
                                ?.replyToComment
                                .commentId;
                        HapticFeedback.heavyImpact();
                        print(replyingComment!);
                        final mentions = Provider.of<PostVM>(context, listen: false).mentions;
                        Provider.of<ReplyVM>(context, listen: false)
                            .createReplyComment(
                            postId: postId,
                            commentId: replyingComment,
                            mentions: mentions,
                            text: commentTextEditController.text);
                      }

                      commentTextEditController.clear();
                      mentionTextFieldKey.currentState?.clear();
                    },
                    child: Text(
                      "Post",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Provider
                              .of<AmityUIConfiguration>(context)
                              .primaryColor),
                    ))
                // Expanded(
                //   child: TextField(
                //     controller: commentTextEditController,
                //     decoration: InputDecoration(
                //       suffixIcon: IconButton(
                //         icon: Stack(
                //           children: [
                //             const Padding(
                //               padding: EdgeInsets.only(left: 10),
                //               child: Icon(
                //                 Icons.arrow_outward_sharp,
                //                 size: 15,
                //                 color: Color(0xffA5A9B5),
                //               ),
                //             ),
                //             Padding(
                //               padding: const EdgeInsets.only(top: 10),
                //               child: Transform(
                //                 alignment: Alignment.center,
                //                 transform: Matrix4.identity()
                //                   ..scale(-1.0, -1.0), // Flips horizontally
                //                 child: const Icon(
                //                   Icons.arrow_outward_sharp,
                //                   size: 15,
                //                   color: Color(0xffA5A9B5),
                //                 ),
                //               ),
                //             ),
                //           ],
                //         ),
                //         onPressed: navigateToFullCommentPage,
                //       ),
                //       hintText: 'Say something nice...',
                //       fillColor:
                //           Colors.grey[300], // Set the background color to grey
                //       filled: true, // Enable the fill color
                //       border: OutlineInputBorder(
                //         borderRadius:
                //             BorderRadius.circular(20.0), // Rounded border
                //         borderSide: BorderSide.none, // No border side
                //       ),
                //       contentPadding: const EdgeInsets.symmetric(
                //           horizontal: 15,
                //           vertical: 10), // Padding inside the text field
                //     ),
                //     keyboardType: TextInputType.multiline,
                //     maxLines: null, // Allows for any number of lines
                //     cursorHeight: 19,
                //     style: const TextStyle(
                //       height: 1.1,
                //     ),
                //   ),
                // ),
              ],
            ),
          )

        // GestureDetector(
        //     onTap: () async {
        //       if (Provider.of<ReplyVM>(context, listen: false).replyToObject ==
        //           null) {
        //         HapticFeedback.heavyImpact();
        //         await Provider.of<PostVM>(context, listen: false)
        //             .createComment(postId, commentTextEditController.text);
        //       } else {
        //         ///Create Comment with Reply
        //         print("reply comment");
        //         var replyingComment =
        //             Provider.of<ReplyVM>(context, listen: false)
        //                 .replyToObject
        //                 ?.replyToComment
        //                 .commentId;
        //         HapticFeedback.heavyImpact();
        //         print(replyingComment!);
        //         Provider.of<ReplyVM>(context, listen: false).createReplyComment(
        //             postId: postId,
        //             commentId: replyingComment,
        //             text: commentTextEditController.text);
        //       }

        //       commentTextEditController.clear();
        //     },
        //     child: Text("Post  ",
        //         style: TextStyle(
        //             fontWeight: FontWeight.bold,
        //             color: Provider.of<AmityUIConfiguration>(context)
        //                 .primaryColor))),

      ),
    );
  }
}

class FullCommentPage extends StatelessWidget {
  final TextEditingController commentTextEditController;
  final String postId;
  final VoidCallback postCallback;
  final FeedType feedType;
  const FullCommentPage({
    super.key,
    required this.commentTextEditController,
    required this.postId,
    required this.postCallback,
    required this.feedType,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Provider.of<AmityUIConfiguration>(context).appColors.baseBackground,
      appBar: AppBar(
        shadowColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: Colors.black,
          ),
          onPressed: () {
            if (true) {
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
        title: Text(
          "Add Comment",
          style: Provider.of<AmityUIConfiguration>(context).titleTextStyle,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              postCallback();
            },
            child: Text(
              'Post',
              style: TextStyle(
                  color:
                      Provider.of<AmityUIConfiguration>(context).primaryColor),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: commentTextEditController,
          keyboardType: TextInputType.multiline,
          maxLines: null, // Allows for any number of lines
          decoration: const InputDecoration(
              hintText: 'Type message', border: InputBorder.none),
        ),
      ),
    );
  }
}

class EditCommentPage extends StatefulWidget {
  final AmityComment comment;
  final VoidCallback postCallback;
  final String initailText;
  final FeedType feedType;
  const EditCommentPage({
    super.key,
    required this.initailText,
    required this.comment,
    required this.postCallback,
    required this.feedType,
  });

  @override
  State<EditCommentPage> createState() => _EditCommentPageState();
}

class _EditCommentPageState extends State<EditCommentPage> {
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    textEditingController.text = widget.initailText;
    final vm = Provider.of<EditCommentVM>(context, listen: false);
    vm.inits(widget.comment);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      Provider.of<AmityUIConfiguration>(context).appColors.baseBackground,
      appBar: AppBar(
        backgroundColor: widget.feedType == FeedType.user
            ? Provider.of<AmityUIConfiguration>(context)
            .appColors
            .userProfileBGColor
            : Colors.white,
        shadowColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Edit Comment",
          style: Provider.of<AmityUIConfiguration>(context).titleTextStyle,
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              print(textEditingController.text);
              HapticFeedback.heavyImpact();
              Provider.of<EditCommentVM>(context, listen: false)
                  .updateComment(widget.comment);
              Navigator.of(context).pop();
              widget.postCallback();
            },
            child: Text(
              'Save',
              style: TextStyle(
                  color:
                  Provider.of<AmityUIConfiguration>(context).primaryColor),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Consumer<EditCommentVM>(builder: (context, vm, _){
          return MentionTextField<AmityCommunityMember>(
              flutterTaggerController: vm.mentionTextFieldController,
              onSearchMentions: (keyword) =>
                  vm.onSearchMentions(keyword: keyword,
                      communityId: (widget.comment.target as CommunityCommentTarget)
                          .communityId ?? ""),
              overlayPosition: OverlayPosition.bottom,
              mentionListItemBuilder: (member) {
                return Padding(padding: EdgeInsets.all(8),
                    child: Row(
                      children: [
                        ShadowAvatar(
                            height: 30,
                            width: 30,
                            url: member.user?.avatarCustomUrl ??
                                member.user?.avatarUrl ??
                                "",
                            fullName: member.user?.displayName ?? ""),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(member.user?.displayName ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Styles.fontInterMedium(16)),
                        )
                      ],
                    ));
              },
              onSelectTag: (tag){
                return CommunityTag(id: tag.user?.userId ?? "", name: tag.user?.displayName ?? "");
              },
              onMentionsChanged: vm.onMentionsChanged,
              onTextChanged: vm.onTextChanged,
              key: vm.textFieldKey);
        }),
      ),
    );
  }
}

class CommentComponent extends StatefulWidget {
  const CommentComponent(
      {Key? key,
      required this.postId,
      required this.theme,
      required this.feedType})
      : super(key: key);
  final FeedType feedType;
  final String postId;
  final ThemeData theme;

  @override
  State<CommentComponent> createState() => _CommentComponentState();
}

class _CommentComponentState extends State<CommentComponent> {
  @override
  void initState() {
    Provider.of<PostVM>(context, listen: false).listenForComments(
        postID: widget.postId,
        refresh: true,
        successCallback: () {
          Provider.of<ReplyVM>(context, listen: false)
              .initReplyComment(widget.postId, context);
        });

    super.initState();
  }

  bool isLiked(AsyncSnapshot<AmityComment> snapshot) {
    var comments = snapshot.data!;
    return comments.myReactions?.isNotEmpty ?? false;
  }

  final _editcommentTextEditController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<PostVM>(builder: (context, vm, _) {
      return vm.amityComments.isEmpty
          ? const SizedBox(
              height: 500,
            )
          : vm.controller.isFetching
              ? SizedBox(height: 500, child: LoadingSkeleton(context: context))
              : ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: vm.amityComments.length,
                  itemBuilder: (context, index) {
                    return StreamBuilder<AmityComment>(
                      key: Key(vm.amityComments[index].commentId!),
                      stream: vm.amityComments[index].listen.stream,
                      initialData: vm.amityComments[index],
                      builder: (context, snapshot) {
                        var comments = snapshot.data!;
                        var commentData = comments.data as CommentTextData;

                        return comments.isDeleted!
                            ? Container(
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(16.0),
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
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(
                                        height: 16,
                                      ),
                                      Container(
                                          padding: const EdgeInsets.only(
                                            left: 16,
                                          ),
                                          child: CustomListTile(
                                              avatarUrl:
                                                  comments.user!.avatarUrl ?? comments.user!.avatarCustomUrl ,
                                              displayName:
                                                  comments.user!.displayName!,
                                              createdAt: comments.createdAt!,
                                              editedAt: comments.editedAt!,
                                              userId: comments.user!.userId!,
                                              user: comments.user!)),
                                      const SizedBox(
                                        height: 4,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        margin: const EdgeInsets.only(
                                            left: 70.0, right: 16),
                                        decoration: BoxDecoration(
                                          color:
                                              Provider.of<AmityUIConfiguration>(
                                                      context)
                                                  .appColors
                                                  .baseShade4,
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(10),
                                            bottomRight: Radius.circular(10),
                                            bottomLeft: Radius.circular(10),
                                          ),
                                        ),
                                        child: RichTextWithMentions(
                                            mentionColor: Styles.green,
                                            fullText: commentData.text!,
                                              mentions: comments.metadata?["mentions"] !=
                                                  null ? (comments.metadata!["mentions"] as List<dynamic>).map((
                                                  e) => Mention.fromJson(e)).toList() : [],
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
                                          textColor: Provider.of<AmityUIConfiguration>(
                                                  context)
                                              .appColors
                                              .base)),
                                      const SizedBox(
                                        height: 8,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 70.0, bottom: 16),
                                        child: Row(
                                          children: [
                                            // Like Button
                                            isLiked(snapshot)
                                                ? GestureDetector(
                                                    onTap: () {
                                                      vm.removeCommentReaction(
                                                          comments);
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Provider.of<AmityUIConfiguration>(
                                                                context)
                                                            .iconConfig
                                                            .likedIcon(
                                                                color: Provider.of<
                                                                            AmityUIConfiguration>(
                                                                        context)
                                                                    .primaryColor),
                                                        Text(
                                                          " ${snapshot.data?.reactionCount ?? 0}",
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Provider.of<
                                                                        AmityUIConfiguration>(
                                                                    context)
                                                                .appColors
                                                                .primary,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : GestureDetector(
                                                    onTap: () {
                                                      vm.addCommentReaction(
                                                          comments);
                                                    },
                                                    child: Row(
                                                      children: [
                                                        Provider.of<AmityUIConfiguration>(
                                                                context)
                                                            .iconConfig
                                                            .likeIcon(
                                                                iconSize: 16),
                                                        snapshot.data!
                                                                    .reactionCount! >
                                                                0
                                                            ? Text(
                                                                " ${snapshot.data!.reactionCount!}",
                                                                style:
                                                                    const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Color(
                                                                      0xff898E9E),
                                                                ),
                                                              )
                                                            : const Text(
                                                                " Like",
                                                                style:
                                                                    TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Color(
                                                                      0xff898E9E),
                                                                ),
                                                              ),
                                                      ],
                                                    )),

                                            const SizedBox(width: 8),
                                            // Reply Button
                                            GestureDetector(
                                              onTap: () {
                                                Provider.of<ReplyVM>(context,
                                                        listen: false)
                                                    .selectReplyComment(
                                                        comment: comments);
                                              },
                                              child: Row(
                                                children: [
                                                  Provider.of<AmityUIConfiguration>(
                                                          context)
                                                      .iconConfig
                                                      .replyIcon(iconSize: 16),
                                                  const SizedBox(
                                                    width: 5,
                                                  ),
                                                  const Text(
                                                    "Reply",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            Color(0xff898E9E),
                                                        fontSize: 15),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            // More Options Button
                                            GestureDetector(
                                              child: const Icon(
                                                Icons.more_horiz,
                                                color: Color(0xff898E9E),
                                              ),
                                              onTap: () {
                                                AmityGeneralCompomemt
                                                    .showOptionsBottomSheet(
                                                        context,
                                                        [
                                                      comments.user?.userId! ==
                                                              AmityCoreClient
                                                                      .getCurrentUser()
                                                                  .userId
                                                          ? const SizedBox()
                                                          : ListTile(
                                                              title: Text(
                                                                comments.isFlaggedByMe
                                                                    ? 'Undo Report'
                                                                    : 'Report',
                                                                style: const TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500),
                                                              ),
                                                              onTap: () async {
                                                                if (!comments
                                                                    .isFlaggedByMe) {
                                                                  vm.flagComment(
                                                                      comments,
                                                                      context);
                                                                } else {
                                                                  vm.unFlagComment(
                                                                      comments,
                                                                      context);
                                                                }
                                                                Navigator.pop(
                                                                    context);
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
                                                                style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500),
                                                              ),
                                                              onTap: () async {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                                Navigator.of(
                                                                        context)
                                                                    .push(MaterialPageRoute(
                                                                        builder: (context) => ChangeNotifierProvider<EditCommentVM>(
                                                                          create: (_) => EditCommentVM(),
                                                                            builder: (context, _) => EditCommentPage(
                                                                              feedType: widget.feedType,
                                                                              initailText: commentData.text!,
                                                                              comment: comments,
                                                                              postCallback: () async {},
                                                                            ))));
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
                                                                style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500),
                                                              ),
                                                              onTap: () async {
                                                                ConfirmationDialog()
                                                                    .show(
                                                                        context:
                                                                            context,
                                                                        title:
                                                                            "Delete this comment",
                                                                        detailText:
                                                                            " This comment will be permanently deleted. You'll no longer to see and find this comment",
                                                                        onConfirm:
                                                                            () {
                                                                          vm.deleteComment(
                                                                              comments);

                                                                          Navigator.pop(
                                                                              context);
                                                                        });
                                                              },
                                                            ),
                                                    ]);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.only(
                                            left: 70, right: 15, top: 0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Provider.of<ReplyVM>(context)
                                                            .amityReplyCommentsMap[
                                                        comments.commentId] ==
                                                    null
                                                ? const SizedBox()
                                                : ListView.builder(
                                                    shrinkWrap: true,
                                                    physics:
                                                        const NeverScrollableScrollPhysics(),
                                                    itemCount: Provider.of<
                                                            ReplyVM>(context)
                                                        .amityReplyCommentsMap[
                                                            comments.commentId]!
                                                        .length,
                                                    itemBuilder:
                                                        (context, index) {
                                                      var replyComment = Provider
                                                                  .of<ReplyVM>(
                                                                      context)
                                                              .amityReplyCommentsMap[
                                                          comments
                                                              .commentId]![index];
                                                      return ReplyCommentComponent(
                                                        comment: replyComment,
                                                        feedType:
                                                            widget.feedType,
                                                      );
                                                    },
                                                  ),
                                            Provider.of<ReplyVM>(context)
                                                    .replyHaveNextPage(
                                                        comments.commentId!)
                                                ? GestureDetector(
                                                    onTap: () {
                                                      HapticFeedback
                                                          .mediumImpact();
                                                      Provider.of<ReplyVM>(
                                                              context,
                                                              listen: false)
                                                          .loadReplynextpage(
                                                        comments.commentId!,
                                                      );
                                                    },
                                                    child: Container(
                                                      margin:
                                                          const EdgeInsets.all(
                                                              12),
                                                      decoration: BoxDecoration(
                                                          color: Provider.of<
                                                                      AmityUIConfiguration>(
                                                                  context)
                                                              .appColors
                                                              .baseShade4,
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .all(Radius
                                                                      .circular(
                                                                          4))),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5.0),
                                                      child: const Wrap(
                                                        crossAxisAlignment:
                                                            WrapCrossAlignment
                                                                .center,
                                                        children: [
                                                          SizedBox(
                                                            width: 14,
                                                          ),
                                                          Icon(
                                                            Icons
                                                                .subdirectory_arrow_right,
                                                            size: 15,
                                                            color: Color(
                                                                0xff636878),
                                                          ),
                                                          SizedBox(
                                                            width: 14,
                                                          ),
                                                          Text(
                                                            "View more replies",
                                                            style: TextStyle(
                                                                color: Color(
                                                                    0xff636878),
                                                                fontSize: 13),
                                                          ),
                                                          SizedBox(
                                                            width: 14,
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                : const SizedBox(),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                   Divider(
                                    height: 1,
                                    color: Colors.grey.withValues(alpha: 0.2),
                                  ),
                                ],
                              );
                      },
                    );
                  },
                );
    });
  }
}

// import 'package:amity_sdk/amity_sdk.dart';
// import 'package:amity_uikit_beta_service/viewmodel/post_viewmodel.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// // Other imports...

// class CommentScreen extends StatefulWidget {
//   final AmityPost amityPost;

//   const CommentScreen({Key? key, required this.amityPost}) : super(key: key);

//   @override
//   CommentScreenState createState() => CommentScreenState();
// }

// class CommentScreenV2State extends State<CommentScreen> {
//   final _commentTextEditController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     // Initialize the post and comments
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<PostVM>(builder: (context, vm, _) {
//       return Scaffold(
//         appBar: AppBar(
//           leading: IconButton(
//             icon: Icon(Icons.arrow_back),
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//           title: Text('Post'),
//         ),
//         body: SingleChildScrollView(
//           child: Column(
//             children: [
//               _buildPostContent(vm.amityPost),
//               _buildCommentSection(vm),
//               _buildCommentInputField(),
//             ],
//           ),
//         ),
//       );
//     });
//   }

//   Widget _buildPostContent(AmityPost post) {
//     TextData textData = post.data as TextData;
//     return Card(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           ListTile(
//             leading: CircleAvatar(
//               backgroundImage: NetworkImage(post.postedUser!.avatarUrl!),
//             ),
//             title: Text(post.postedUser!.displayName!),
//             subtitle: Text(DateFormat.yMMMMEEEEd().format(post.createdAt!)),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Text(textData.text ?? ""),
//           ),
//           ButtonBar(
//             children: [
//               // Like, Comment, and Share buttons
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCommentSection(PostVM vm) {
//     return ListView.builder(
//       shrinkWrap: true,
//       physics: NeverScrollableScrollPhysics(),
//       itemCount: vm.amityComments.length,
//       itemBuilder: (context, index) {
//         var comment = vm.amityComments[index];
//         CommentTextData textData = comment.data as CommentTextData;
//         return ListTile(
//           leading: CircleAvatar(
//             backgroundImage: NetworkImage(comment.user!.avatarUrl!),
//           ),
//           title: Text(comment.user!.displayName!),
//           subtitle: Text(textData.text ?? ""),
//         );
//       },
//     );
//   }

// Widget _buildCommentInputField() {
//   return ListTile(
//     leading: CircleAvatar(
//         // User's avatar
//         ),
//     title: TextField(
//       controller: _commentTextEditController,
//       decoration: InputDecoration(
//         hintText: "Write a comment...",
//         border: InputBorder.none,
//       ),
//     ),
//     trailing: IconButton(
//       icon: Icon(Icons.send),
//       onPressed: () {
//         // Logic to post comment
//       },
//     ),
//   );
// }
// }

class ReplyCommentComponent extends StatelessWidget {
  final AmityComment comment;
  final FeedType feedType;
  const ReplyCommentComponent({
    super.key,
    required this.comment,
    required this.feedType,
  });
  bool isLiked(AsyncSnapshot<AmityComment> snapshot) {
    var comments = snapshot.data!;
    return comments.myReactions?.isNotEmpty ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReplyVM>(builder: (context, vm, _) {
      return StreamBuilder<AmityComment>(
          key: Key(comment.commentId!),
          stream: comment.listen.stream,
          initialData: comment,
          builder: (context, snapshot) {
            var comments = snapshot.data!;
            var commentData = comments.data as CommentTextData;
            print(comments.metadata);

            return comments.isDeleted!
                ? Container(
                    padding: const EdgeInsets.only(left: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                              color: Provider.of<AmityUIConfiguration>(context)
                                  .appColors
                                  .baseShade4,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(4))),
                          padding: const EdgeInsets.all(5.0),
                          child: const Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
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
                                "This reply has been deleted",
                                style: TextStyle(
                                    color: Color(0xff636878), fontSize: 13),
                              ),
                              SizedBox(
                                width: 14,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomListTile(
                            avatarUrl: comments.user!.avatarUrl ?? comments.user!.avatarCustomUrl,
                            displayName: comments.user!.displayName!,
                            createdAt: comments.createdAt!,
                            editedAt: comments.editedAt!,
                            userId: comments.user!.userId!,
                            user: comments.user!),
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          margin: const EdgeInsets.only(left: 50.0, top: 8),
                          decoration: BoxDecoration(
                            color: Provider.of<AmityUIConfiguration>(context)
                                .appColors
                                .baseShade4,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                            ),
                          ),
                          child: RichTextWithMentions(
                              mentionColor: Styles.green,
                              fullText: commentData.text!,
                              mentions: comments.metadata?["mentions"] !=
                                  null ? (comments.metadata!["mentions"] as List<dynamic>).map((
                                  e) => Mention.fromJson(e)).toList() : [],
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
                              textColor: Provider.of<AmityUIConfiguration>(
                                  context)
                                  .appColors
                                  .base),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 50.0, top: 8),
                          child: Row(
                            children: [
                              // Like Button

                              isLiked(snapshot)
                                  ? GestureDetector(
                                      onTap: () {
                                        vm.removeCommentReaction(comment);
                                      },
                                      child: Row(
                                        children: [
                                          Provider.of<AmityUIConfiguration>(
                                                  context)
                                              .iconConfig
                                              .likedIcon(
                                                  color: Provider.of<
                                                              AmityUIConfiguration>(
                                                          context)
                                                      .primaryColor),
                                          Text(
                                            " ${snapshot.data?.reactionCount ?? 0}",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Provider.of<
                                                          AmityUIConfiguration>(
                                                      context)
                                                  .appColors
                                                  .primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : GestureDetector(
                                      onTap: () {
                                        vm.addCommentReaction(comment);
                                      },
                                      child: Row(
                                        children: [
                                          Provider.of<AmityUIConfiguration>(
                                                  context)
                                              .iconConfig
                                              .likeIcon(iconSize: 16),
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
                                      )),

                              // const SizedBox(width: 10),
                              // // Reply Button
                              // Provider.of<AmityUIConfiguration>(context)
                              //     .iconConfig
                              //     .replyIcon(iconSize: 16),

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
                                  AmityGeneralCompomemt.showOptionsBottomSheet(
                                      context, [
                                    comment.user?.userId! ==
                                            AmityCoreClient.getCurrentUser()
                                                .userId
                                        ? const SizedBox()
                                        : ListTile(
                                            title: const Text(
                                              'Report',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            onTap: () async {
                                              Navigator.pop(context);
                                            },
                                          ),

                                    ///check admin
                                    comment.user?.userId! !=
                                            AmityCoreClient.getCurrentUser()
                                                .userId
                                        ? const SizedBox()
                                        : ListTile(
                                            title: const Text(
                                              'Edit Comment',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        Navigator.of(
                                            context)
                                            .push(MaterialPageRoute(
                                            builder: (context) =>
                                                ChangeNotifierProvider<EditCommentVM>(
                                                    create: (_) => EditCommentVM(),
                                                    builder: (context, _) =>
                                                        EditCommentPage(
                                                          initailText: commentData.text!,
                                                          feedType: feedType,
                                                          comment: comments,
                                                          postCallback: () async {},
                                                        ))));
                                      },
                                          ),
                                    comment.user?.userId! !=
                                            AmityCoreClient.getCurrentUser()
                                                .userId
                                        ? const SizedBox()
                                        : ListTile(
                                            title: const Text(
                                              'Delete Comment',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            onTap: () async {
                                              ConfirmationDialog().show(
                                                  context: context,
                                                  title: "Delete this comment",
                                                  detailText:
                                                      " This comment will be permanently deleted. You'll no longer to see and find this comment",
                                                  onConfirm: () {
                                                    vm.deleteComment(comment);
                                                    AmitySuccessDialog
                                                        .showTimedDialog(
                                                            "Success",
                                                            context: context);
                                                    Navigator.pop(context);
                                                  });
                                            },
                                          ),
                                  ]);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                      ],
                    ),
                  );
          });
    });
  }
}

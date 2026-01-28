import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/v4/social/post/common/post_action.dart';
import 'package:amity_uikit_beta_service/v4/utils/compact_string_converter.dart';
import 'package:amity_uikit_beta_service/v4/utils/config_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app_padel/shared/asset_keys.dart';
import 'package:mobile_app_padel/shared/styles.dart';

class PostReactionButton extends StatelessWidget {
  final AmityPost post;
  final AmityPostAction action;
  final bool isReacting;
  final bool showLabel;
  final bool isOptimisticUi;

  const PostReactionButton({
    super.key,
    required this.post,
    required this.action,
    required this.isReacting,
    this.showLabel = false,
    this.isOptimisticUi = false,
  });

  @override
  Widget build(BuildContext context) {
    var reactionIcon = SvgPicture.asset(
      'assets/Icons/heart_outline.svg',
      package: 'amity_uikit_beta_service',
      width: 22,
      height: 22,
    );
    if (post.myReactions?.isNotEmpty ?? false) {
      reactionIcon = post.myReactions!.first == 'like'
          ? SvgPicture.asset(
              'assets/Icons/heart_filled.svg',
              package: 'amity_uikit_beta_service',
              width: 22,
              height: 22,
            )
          : SvgPicture.asset(
              'assets/Icons/heart_outline.svg',
              package: 'amity_uikit_beta_service',
              width: 22,
              height: 22,
            );
    }
    var iconAsset = 'assets/Icons/heart_outline.svg';
    if (post.myReactions?.isNotEmpty ?? false) {
      iconAsset = post.myReactions!.first == 'like'
          ? 'assets/Icons/heart_filled.svg'
          : 'assets/Icons/heart_outline.svg';
    }
    return GestureDetector(
      onTap: () {
        if (!isReacting) {
          if (post.myReactions?.isNotEmpty ?? false) {
            action.onRemoveReaction("like");
          } else {
            action.onAddReaction("like");
          }
          HapticFeedback.lightImpact();
        }
      },
      child: Container(
        height: 44,
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            (isReacting && isOptimisticUi)
                ? Container(
                    alignment: Alignment.center,
                    width: 22,
                    height: 22,
                    child: loadingIndicator(
                        context, !(post.myReactions?.isNotEmpty ?? false)))
                : Container(
                    alignment: Alignment.center,
                    width: 22,
                    height: 22,
                    child: reactionIcon),
            const SizedBox(width: 4),
            (isReacting && isOptimisticUi)
                ? getReactingLabel(context, post, showLabel)
                : getReactionLabel(context, post, showLabel),
          ],
        ),
      ),
    );
  }

  Widget getReactionLabel(
      BuildContext context, AmityPost post, bool showLabel) {
    final appTheme = Provider.of<ConfigProvider>(context).getTheme(null, null);
    bool hasMyReaction = post.myReactions?.isNotEmpty ?? false;
    var text = (post.reactionCount ?? 0).formattedCompactString();
    if (showLabel) {
      text = hasMyReaction ? 'Liked' : 'Like';
    }
    return Text(
      text,
      style: TextStyle(
        // color: hasMyReaction ? appTheme.primaryColor : const Color(0xFF898E9E),
        fontSize: 12,
        height: 1.8,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget getReactingLabel(
      BuildContext context, AmityPost post, bool showLabel) {
    final appTheme = Provider.of<ConfigProvider>(context).getTheme(null, null);
    bool hasMyReaction = post.myReactions?.isNotEmpty ?? false;
    final isAdding = !hasMyReaction;
    var count = post.reactionCount ?? 0;
    if (isAdding) {
      count++;
    } else {
      count--;
    }
    var text = count.formattedCompactString();
    if (showLabel) {
      text = hasMyReaction ? 'Liked' : 'Like';
    }
    return Text(
      text,
      style: TextStyle(
        // color: !hasMyReaction ? appTheme.primaryColor : const Color(0xFF898E9E),
        fontSize: 12,
        height: 1.8,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget loadingIndicator(BuildContext context, bool isAdding) {
    return (isAdding)
        ? Container(
            alignment: Alignment.center,
            height: 44,
            child: SvgPicture.asset(
              'assets/Icons/heart_filled.svg',
              package: 'amity_uikit_beta_service',
              width: 22,
              height: 22,
            ),
          )
        : Container(
            alignment: Alignment.center,
            height: 44,
            child: SvgPicture.asset(
              'assets/Icons/heart_outline.svg',
              package: 'amity_uikit_beta_service',
              width: 22,
              height: 22,
            ),
          );
  }
}

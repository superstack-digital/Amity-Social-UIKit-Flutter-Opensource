import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/native_social_override.dart';
import 'package:amity_uikit_beta_service/v4/core/toast/amity_uikit_toast.dart';
import 'package:amity_uikit_beta_service/v4/core/toast/bloc/amity_uikit_toast_bloc.dart';
import 'package:amity_uikit_beta_service/v4/social/post/common/post_action.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'post_item_events.dart';
part 'post_item_state.dart';

class PostItemBloc extends Bloc<PostItemEvent, PostItemState> {
  /// Records the reaction in Postgres after Amity has accepted it.
  ///
  /// Amity remains canonical for mirrored posts — this follows that write, it does
  /// not replace it. Without it the reaction is correct in Amity but invisible on
  /// the next feed load, because the envelope computes myReactions from
  /// post_reactions, which is empty for mirrored content.
  ///
  /// Failure here is deliberately swallowed. The user's reaction has already
  /// succeeded where it counts; losing the local copy costs them a filled heart
  /// after a refresh, and that is not worth surfacing an error or undoing the
  /// Amity write for. A no-op when the flag is off, which is what keeps this
  /// reversible.
  static Future<void> _mirrorReaction(String? postId, String kind,
      {required bool on}) async {
    final mirror = NativeSocialOverride.reactionMirror;
    if (mirror == null || postId == null) return;
    try {
      await mirror(postId: postId, kind: kind, on: on);
    } catch (e) {
      debugPrint('reaction mirror failed for $postId (Amity write stands): $e');
    }
  }

  PostItemBloc() : super(PostItemStateInitial()) {
    on<PostItemLoading>((event, emit) async {
      var post =
          await AmitySocialClient.newPostRepository().getPost(event.postId);
      emit(PostItemStateLoaded(post: post));
    });

    on<AddReactionToPost>((event, emit) async {
      AmityPost post = event.post;
      // A natively-created post exists only in Postgres, so react() would hand
      // Amity an id it has never seen and the call fails — as would the
      // getPost() refresh below it. Reacting is not wired to Postgres yet, so
      // the honest thing is to do nothing rather than throw. The affordance
      // itself should be hidden for these posts; that is follow-up work.
      if (NativeSocialOverride.isNativePost(post.postId)) {
        debugPrint('native post ${post.postId}: reactions not supported yet');
        emit(PostItemStateLoaded(post: post));
        return;
      }
      emit(PostItemStateReacting(post: post));
      if (post.myReactions?.isNotEmpty ?? false) {
        await post.react().removeReaction(post.myReactions!.first);
      }
      await post.react().addReaction(event.reactionType);
      await _mirrorReaction(post.postId, event.reactionType, on: true);
      var updatedPost = await AmitySocialClient.newPostRepository()
          .getPost(event.post.postId!);
      if (event.action?.onPostUpdated != null) {
        event.action?.onPostUpdated(updatedPost);
      }
      emit(PostItemStateLoaded(post: updatedPost));
    });

    on<RemoveReactionToPost>((event, emit) async {
      AmityPost post = event.post;
      if (NativeSocialOverride.isNativePost(post.postId)) {
        debugPrint('native post ${post.postId}: reactions not supported yet');
        emit(PostItemStateLoaded(post: post));
        return;
      }
      emit(PostItemStateReacting(post: post));
      if (post.myReactions?.isNotEmpty ?? false) {
        await post.react().removeReaction(event.reactionType);
        await _mirrorReaction(post.postId, event.reactionType, on: false);
      }
      var updatedPost = await AmitySocialClient.newPostRepository()
          .getPost(event.post.postId!);
      if (event.action?.onPostUpdated != null) {
        event.action?.onPostUpdated(updatedPost);
      }
      emit(PostItemStateLoaded(post: updatedPost));
    });

    on<PostItemFlag>((event, emit) async {
      final flag = await event.post.report().flag();
      if (flag) {
        event.toastBloc.add(const AmityToastShort(
            message: "Post reported.", icon: AmityToastIcon.success));
        var updatedPost = await AmitySocialClient.newPostRepository()
            .getPost(event.post.postId!);
        emit(PostItemStateLoaded(post: updatedPost));
      }
    });

    on<PostItemUnFlag>((event, emit) async {
      final flag = await event.post.report().unflag();
      if (flag) {
        event.toastBloc.add(const AmityToastShort(
            message: "Post unreported.", icon: AmityToastIcon.success));
        var updatedPost = await AmitySocialClient.newPostRepository()
            .getPost(event.post.postId!);
        emit(PostItemStateLoaded(post: updatedPost));
      }
    });

    on<PostItemDelete>((event, emit) async {
      final delete = await event.post.delete();
      if (delete) {
        event.action?.onPostDeleted(event.post);
        var updatedPost = event.post;
        updatedPost.isDeleted = true;
        emit(PostItemStateLoaded(post: updatedPost));
      }
    });

    on<PostItemLoaded>((event, emit) async {
      AmityPost post = event.post;
      emit(PostItemStateLoaded(post: post));
    });
  }
}

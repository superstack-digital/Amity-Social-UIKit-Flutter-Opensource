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

  /// Applies a reaction to the in-memory post for the native path.
  ///
  /// The Amity path re-fetches with getPost() to pick up the new state, which is
  /// not available for a post Amity has never seen. AmityPost is a plain mutable
  /// class that this pilot constructs itself, so updating it directly is exactly
  /// as truthful as a refetch would be — and post_reactions is already the source
  /// the next feed load reads from.
  ///
  /// The count shown is optimistic. bump_post_counters maintains the real one, and
  /// for native posts it is the only thing that does, since the mirror never
  /// touches them.
  static void _applyReactionLocally(AmityPost post, String kind,
      {required bool on}) {
    final reactions = List<String>.from(post.myReactions ?? const <String>[])
      ..remove(kind);
    if (on) reactions.add(kind);
    post.myReactions = reactions;
    post.reactionCount =
        ((post.reactionCount ?? 0) + (on ? 1 : -1)).clamp(0, 1 << 31);
  }

  PostItemBloc() : super(PostItemStateInitial()) {
    on<PostItemLoading>((event, emit) async {
      var post =
          await AmitySocialClient.newPostRepository().getPost(event.postId);
      emit(PostItemStateLoaded(post: post));
    });

    on<AddReactionToPost>((event, emit) async {
      AmityPost post = event.post;
      // A natively-created post exists only in Postgres. Amity's react() would
      // be handed an id it has never seen, and so would the getPost() refresh
      // below — so this path skips Amity entirely and writes straight to
      // Postgres, then updates the post in place rather than re-fetching.
      if (NativeSocialOverride.isNativePost(post.postId)) {
        emit(PostItemStateReacting(post: post));
        await _mirrorReaction(post.postId, event.reactionType, on: true);
        _applyReactionLocally(post, event.reactionType, on: true);
        event.action?.onPostUpdated(post);
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
        emit(PostItemStateReacting(post: post));
        await _mirrorReaction(post.postId, event.reactionType, on: false);
        _applyReactionLocally(post, event.reactionType, on: false);
        event.action?.onPostUpdated(post);
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

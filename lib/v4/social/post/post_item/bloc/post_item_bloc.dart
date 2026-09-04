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

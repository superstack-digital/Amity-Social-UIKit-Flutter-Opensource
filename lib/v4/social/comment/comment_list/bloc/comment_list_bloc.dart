import 'dart:async';

import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/native_social_override.dart';
import 'package:amity_uikit_beta_service/v4/core/toast/bloc/amity_uikit_toast_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'comment_list_events.dart';
part 'comment_list_state.dart';

class CommentListBloc extends Bloc<CommentListEvent, CommentListState> {
  var commentCount = 0;

  /// Null on the native path — a post that exists only in Postgres has no
  /// Amity live collection to observe.
  CommentLiveCollection? liveCollection;

  StreamSubscription<AmityComment>? _nativeCreatedSub;

  CommentListBloc(
    String referenceId,
    AmityCommentReferenceType referenceType,
    String? parentId,
  ) : super(CommentListStateInitial(
            referenceId: referenceId, referenceType: referenceType)) {
    final isNative = referenceType == AmityCommentReferenceType.POST &&
        NativeSocialOverride.isNativePost(referenceId) &&
        NativeSocialOverride.commentGateway != null;

    if (!isNative) {
      final collection =
          getNewLiveCollection(referenceId, referenceType, parentId);
      liveCollection = collection;

      collection.getStreamController().stream.listen((event) {
        if (!isClosed) {
          commentCount = event.length;
          add(CommentListEventChanged(
              comments: event, isFetching: collection.isFetching));
        }
      });

      collection.observeLoadingState().listen((event) {
        if (!isClosed) {
          add(CommentListEventLoadingStateUpdated(isFetching: event));
        }
      });
    } else {
      // Amity's live collection pushes new comments by itself. The native path
      // has none, and the creating bloc is a sibling rather than an ancestor, so
      // a comment reaches this open thread through the seam's broadcast.
      _nativeCreatedSub =
          NativeSocialOverride.nativeCommentCreated.listen((comment) {
        if (!isClosed &&
            comment.referenceId == referenceId &&
            comment.parentId == parentId) {
          add(CommentListEventChanged(
              comments: [...state.comments, comment], isFetching: false));
        }
      });

      // No initial fetch here: comment_list.dart and reply_list.dart both
      // dispatch CommentListEventRefresh on first build (state is
      // CommentListStateInitial), which already has the native branch below
      // and toasts on failure. A second fetch here would race it.
    }

    on<CommentListEventRefresh>((event, emit) async {
      emit(CommentListStateChanged(
        referenceId: state.referenceId,
        referenceType: state.referenceType,
        comments: const [],
        isFetching: true,
        hasNextPage: true,
        expandedId: const [],
      ));
      try {
        final collection = liveCollection;
        if (collection == null) {
          final comments = await NativeSocialOverride.commentGateway!
              .list(state.referenceId);
          // `post_comment_list` returns a flat list for the whole post —
          // every comment and every reply together, with no server-side
          // parent filter and no reply count. Scope to this thread (parentId
          // == null for the top-level thread, the parent's commentId for a
          // reply thread) and derive childrenNumber from the full flat list
          // so comment_item.dart's "View N replies" affordance still appears
          // for top-level comments that have replies.
          final scoped = comments.where((c) => c.parentId == parentId).toList();
          for (final c in scoped) {
            c.childrenNumber =
                comments.where((x) => x.parentId == c.commentId).length;
          }
          commentCount = scoped.length;
          emit(CommentListStateChanged(
            referenceId: state.referenceId,
            referenceType: state.referenceType,
            comments: scoped,
            isFetching: false,
            hasNextPage: false,
            expandedId: const [],
          ));
          return;
        }
        collection.reset();
        collection.loadNext();
        Future.delayed(const Duration(seconds: 2), () {
          // Workaround after 2 second will emit empty events.
          if (!collection.isFetching && commentCount == 0) {
            add(CommentListEventChanged(
                comments: const [], isFetching: collection.isFetching));
          }
        });
      } catch (e) {
        emit(CommentListStateChanged(
          referenceId: state.referenceId,
          referenceType: state.referenceType,
          comments: const [],
          isFetching: false,
          hasNextPage: false,
          expandedId: const [],
        ));

        event.toastBloc.add(AmityToastShort(message: "Couldn’t load comment"));
      }
    });

    on<CommentListEventChanged>((event, emit) async {
      emit(state.copyWith(
        comments: event.comments,
        isFetching: event.isFetching,
        hasNextPage: liveCollection?.hasNextPage() ?? false,
      ));
    });

    on<CommentListEventExpandItem>((event, emit) async {
      if (!state.expandedId.contains(event.commentId)) {
        emit(
            state.copyWith(expandedId: [...state.expandedId, event.commentId]));
      }
    });

    on<CommentListEventLoadMore>((event, emit) async {
      final collection = liveCollection;
      if (collection == null) {
        // The native list is a single page in v1 — nothing more to load.
        return;
      }
      try {
        await collection.loadNext();
      } catch (e) {
        if (e is AmityException) {
          event.toastBloc
              .add(AmityToastShort(message: "Couldn’t load comment"));
        }
      }
    });

    on<CommentListEventLoadingStateUpdated>((event, emit) async {
      emit(state.copyWith(isFetching: event.isFetching));
    });

    on<CommentListEventDisposed>((event, emit) async {
      _nativeCreatedSub?.cancel();
      liveCollection?.getStreamController().close();
    });
  }

  @override
  Future<void> close() {
    _nativeCreatedSub?.cancel();
    return super.close();
  }

  CommentLiveCollection getNewLiveCollection(String referenceId,
      AmityCommentReferenceType referenceType, String? parentId) {
    if (referenceType == AmityCommentReferenceType.POST) {
      return AmitySocialClient.newCommentRepository()
          .getComments()
          .post(referenceId)
          .parentId(parentId)
          .sortBy(AmityCommentSortOption.LAST_CREATED)
          .dataTypes(null)
          .includeDeleted(false)
          .getLiveCollection();
    }
    if (referenceType == AmityCommentReferenceType.STORY) {
      return AmitySocialClient.newCommentRepository()
          .getComments()
          .story(referenceId)
          .parentId(parentId)
          .sortBy(AmityCommentSortOption.LAST_CREATED)
          .dataTypes(null)
          .includeDeleted(false)
          .getLiveCollection();
    } else {
      return AmitySocialClient.newCommentRepository()
          .getComments()
          .content(referenceId)
          .parentId(parentId)
          .sortBy(AmityCommentSortOption.LAST_CREATED)
          .dataTypes(null)
          .includeDeleted(false)
          .getLiveCollection();
    }
  }
}

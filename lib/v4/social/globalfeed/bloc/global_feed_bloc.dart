import 'package:amity_sdk/amity_sdk.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

import '../../../../native_social_override.dart';

part 'global_feed_event.dart';
part 'global_feed_state.dart';

class GlobalFeedBloc extends Bloc<GlobalFeedEvent, GlobalFeedState> {
  late PagingController<AmityPost> _controller;

  late List<AmityPost> posts = [];
  late List<AmityPost> localCreatedPost = [];

  /// True once the paging controller has reported an in-flight fetch. Guards
  /// hasSettled so a pre-fetch notification cannot look like a finished load.
  bool _fetchStarted = false;

  bool hasInitialized = false;

  final int pageSize = 20;
  GlobalFeedBloc()
      : super(const GlobalFeedState(
          list: [],
          hasMoreItems: true,
          isFetching: true,
        )) {
    _controller = PagingController(
      pageFuture: (token) => AmitySocialClient.newFeedRepository()
          .getCustomRankingGlobalFeed()
          .getPagingData(token: token, limit: pageSize),
      pageSize: pageSize,
    )..addListener(
        () {
          if (_controller.isFetching == true &&
              _controller.loadedItems.isEmpty) {
            _fetchStarted = true;
            emit(state.copyWith(isFetching: true, hasError: false));
          } else if (_controller.error == null) {
            // Distinct post list
            posts.addAll(_controller.loadedItems);

            add(GlobalFeedNotify(posts: []));
          } else {
            // Fetch finished with an error (e.g. the network was down while the
            // initial page loaded). Without this branch isFetching stays true and
            // the UI is stuck on the skeleton forever. Clear it and flag the error
            // so the component drops out of the skeleton and auto-retries on
            // reconnect (see AmityGlobalFeedComponent).
            emit(state.copyWith(
                isFetching: false, hasError: true, hasSettled: true));
          }
        },
      );

    on<GlobalFeedNotify>((event, emit) async {
      List<AmityPost> allPost = [];
      allPost.addAll(localCreatedPost);

      allPost.addAll(posts);

      final postIds = allPost.map((post) => post.postId).toSet();
      allPost.retainWhere((post) => postIds.remove(post.postId));

      emit(state.copyWith(
          list: allPost,
          hasMoreItems: _controller.hasMoreItems,
          isFetching: _controller.isFetching,
          hasError: false,
          // Only settled once a fetch has both begun and ended. A reset()
          // notification arrives with isFetching false and no items, and must
          // not be mistaken for "loaded, and genuinely empty".
          hasSettled: _fetchStarted && !_controller.isFetching));
    });

    on<GlobalFeedAddLocalPost>((event, emit) async {
      final post = event.post;
      localCreatedPost.insert(0, post);
      add(GlobalFeedNotify(posts: []));
    });

    on<GlobalFeedInit>((event, emit) async {
      hasInitialized = true;
      localCreatedPost.clear();
      posts.clear();

      // TPS-0 native social pilot: posts come from our own Postgres. Every
      // widget below this bloc is untouched — only the source changes.
      if (NativeSocialOverride.isActive) {
        emit(state.copyWith(isFetching: true, hasError: false));
        try {
          final native = await NativeSocialOverride.globalFeedFetcher!(limit: pageSize);
          posts.addAll(native);
          emit(state.copyWith(
              list: List<AmityPost>.from(posts),
              hasMoreItems: false,
              isFetching: false,
              hasError: false));
        } catch (e) {
          // Never strand the user on a skeleton: drop the override and fall
          // straight back to Amity for the rest of the session.
          NativeSocialOverride.reset();
          _controller.reset();
          _controller.fetchNextPage();
        }
        return;
      }

      _controller.reset();
      _controller.fetchNextPage();
    });

    on<GlobalFeedFetch>((event, emit) async {
      // Native path currently returns a single page; paging lands with the
      // keyset cursor in the next iteration.
      if (NativeSocialOverride.isActive) return;
      if (_controller.hasMoreItems && !_controller.isFetching) {
        _controller.fetchNextPage();
      }
    });

    on<GlobalFeedReactToPost>((event, emit) async {
      AmityPost post = event.post;
      if (post.myReactions?.isNotEmpty ?? false) {
        await post.react().removeReaction(post.myReactions!.first);
      }
      await post.react().addReaction(event.reactionType);
    });

    on<GlobalFeedReloadThePost>((event, emit) async {
      var updatedPost = event.post;
      List<AmityPost> updatedList = [];
      for (var element in state.list) {
        if (element.postId == updatedPost.postId) {
          updatedList.add(updatedPost);
        } else {
          updatedList.add(element);
        }
      }
      // Only emit once to avoid flickering and lag
      emit(state.copyWith(list: updatedList));
    });
  }
}

import 'package:amity_sdk/amity_sdk.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
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

  /// Keyset cursor for the next native page, or null when the native feed has
  /// no more to give. Only meaningful while NativeSocialOverride.isActive.
  String? _nativeToken;

  /// Guards against the scroll listener firing GlobalFeedFetch repeatedly
  /// while a native page is already in flight.
  bool _nativeFetching = false;

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
          // TPS-0 native social pilot: this listener is wired to Amity's own
          // paging controller, which wraps a live/reactive collection that can
          // push updates (new joins, new posts) via its own socket regardless
          // of whether fetchNextPage() was ever called on it. Without this
          // guard, any such push unconditionally appends Amity data into
          // `posts` even while the native override is active — leaking Amity
          // items into an otherwise all-Postgres feed, out of sort order,
          // since they land via addAll() instead of the query's own ORDER BY.
          if (NativeSocialOverride.isActive) return;
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
      //
      // The host app's install() decides isActive, but it runs deep in the
      // post-login bootstrap chain — a fast tap into Feed right after cold
      // start can fire this Init before install() finishes, read isActive
      // too early, and (since GlobalFeedInit only reruns on error or manual
      // refresh) latch onto Amity for the rest of the session. Give install()
      // a short window to finish first; if it never does, fall through to
      // Amity exactly as before rather than stranding the user.
      await NativeSocialOverride.ready
          .timeout(const Duration(seconds: 3), onTimeout: () {});

      if (NativeSocialOverride.isActive) {
        _nativeToken = null;
        _nativeFetching = false;
        emit(state.copyWith(isFetching: true, hasError: false));
        try {
          final page =
              await NativeSocialOverride.globalFeedFetcher!(limit: pageSize);
          posts.addAll(page.posts);
          _nativeToken = page.nextToken;
          emit(state.copyWith(
              list: List<AmityPost>.from(posts),
              hasMoreItems: page.hasMore,
              isFetching: false,
              hasError: false,
              // Without this a genuinely empty native feed keeps painting the
              // skeleton forever: the builder shows it while hasSettled is
              // false and the list is empty, and nothing else ever sets it on
              // this path.
              hasSettled: true));
        } catch (e) {
          // Never strand the user on a skeleton: drop the override and fall
          // straight back to Amity for the rest of the session. Logged rather
          // than silent — while this catch said nothing, a failing native feed
          // was indistinguishable from one that had never been installed.
          debugPrint('native feed failed, falling back to Amity: $e');
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
      // bloc processes events concurrently by default, and
      // AmityGlobalFeedComponent fires this right after GlobalFeedInit via
      // addPostFrameCallback — the very next frame, well before install()
      // has necessarily run. Without the same ready gate GlobalFeedInit
      // waits on, this read isActive as false, fetched Amity's own page,
      // and appended it into `posts` — and since GlobalFeedInit only
      // clears `posts` once at its own start (already past by the time
      // this ran), the native fetch that lands moments later just appends
      // on top instead of replacing it. Result: Amity's page sits ahead of
      // the native page in the merged list, sorted order be damned.
      await NativeSocialOverride.ready
          .timeout(const Duration(seconds: 3), onTimeout: () {});

      if (NativeSocialOverride.isActive) {
        // Page forward through Postgres. The scroll listener in
        // AmityGlobalFeedComponent fires this on every notification within
        // 500px of the bottom, so without _nativeFetching the same page would
        // be requested several times over and appended more than once.
        if (_nativeToken == null || _nativeFetching) return;
        _nativeFetching = true;
        final token = _nativeToken;
        try {
          final page = await NativeSocialOverride.globalFeedFetcher!(
              limit: pageSize, token: token);
          // Init may have run while this was in flight (a pull-to-refresh
          // mid-scroll), which clears posts and resets the cursor. Appending
          // this page then would splice an old page onto a fresh list.
          if (_nativeToken != token) return;
          posts.addAll(page.posts);
          _nativeToken = page.nextToken;
          emit(state.copyWith(
              list: List<AmityPost>.from(posts),
              hasMoreItems: page.hasMore,
              isFetching: false,
              hasError: false,
              hasSettled: true));
        } catch (e) {
          // A failed page is not worth dropping the whole override for — the
          // posts already on screen are fine. Stop paging and leave it.
          debugPrint('native feed: paging failed, stopping here: $e');
          _nativeToken = null;
          emit(state.copyWith(hasMoreItems: false, isFetching: false));
        } finally {
          _nativeFetching = false;
        }
        return;
      }

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

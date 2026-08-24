part of 'global_feed_bloc.dart';

class GlobalFeedState extends Equatable {
  final List<AmityPost> list;
  final bool hasMoreItems;
  final bool isFetching;
  // True when the last fetch finished with an error (e.g. offline). Used to
  // auto-retry on reconnect without re-fetching a legitimately empty feed.
  final bool hasError;
  // False until a fetch has actually STARTED and then FINISHED. The paging
  // controller reports isFetching == false with zero items both before the
  // first fetch begins (notably right after reset()) and after a real empty
  // result, and those two look identical. Without this flag the feed painted
  // the "no posts" empty state for a frame on every open.
  final bool hasSettled;

  const GlobalFeedState(
      {required this.list,
      required this.hasMoreItems,
      required this.isFetching,
      this.hasError = false,
      this.hasSettled = false});

  GlobalFeedState copyWith({
    List<AmityPost>? list,
    bool? hasMoreItems,
    bool? isFetching,
    bool? hasError,
    bool? hasSettled,
  }) {
    return GlobalFeedState(
      list: list ?? this.list,
      hasMoreItems: hasMoreItems ?? this.hasMoreItems,
      isFetching: isFetching ?? this.isFetching,
      hasError: hasError ?? this.hasError,
      hasSettled: hasSettled ?? this.hasSettled,
    );
  }

  @override
  List<Object> get props =>
      [list, hasMoreItems, isFetching, hasError, hasSettled];
}

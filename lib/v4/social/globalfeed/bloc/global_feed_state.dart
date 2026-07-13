part of 'global_feed_bloc.dart';

class GlobalFeedState extends Equatable {
  final List<AmityPost> list;
  final bool hasMoreItems;
  final bool isFetching;
  // True when the last fetch finished with an error (e.g. offline). Used to
  // auto-retry on reconnect without re-fetching a legitimately empty feed.
  final bool hasError;

  const GlobalFeedState(
      {required this.list,
      required this.hasMoreItems,
      required this.isFetching,
      this.hasError = false});

  GlobalFeedState copyWith({
    List<AmityPost>? list,
    bool? hasMoreItems,
    bool? isFetching,
    bool? hasError,
  }) {
    return GlobalFeedState(
      list: list ?? this.list,
      hasMoreItems: hasMoreItems ?? this.hasMoreItems,
      isFetching: isFetching ?? this.isFetching,
      hasError: hasError ?? this.hasError,
    );
  }

  @override
  List<Object> get props => [list, hasMoreItems, isFetching, hasError];
}

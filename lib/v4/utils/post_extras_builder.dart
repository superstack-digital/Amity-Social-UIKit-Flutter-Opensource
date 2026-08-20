import 'package:flutter/widgets.dart';
import 'package:mobile_app_padel/features/community/data/models/event.dart';
import 'package:mobile_app_padel/features/community/data/models/event_standing.dart';
import 'package:mobile_app_padel/features/community/data/repositories/event_repository.dart';
import 'package:mobile_app_padel/features/profile/data/match.dart';
import 'package:mobile_app_padel/features/profile/data/repositories/match_repository.dart';

/// The padel-domain objects a feed post can reference through its Amity
/// metadata (`matchId`, `eventId`, `matchResultId`, `eventStandingId`).
class PostExtras {
  final IMatch? match;
  final Event? event;
  final IMatch? matchResult;
  final List<EventStanding>? eventStanding;

  const PostExtras({
    this.match,
    this.event,
    this.matchResult,
    this.eventStanding,
  });

  /// The state every post starts in, and the terminal state for posts that
  /// reference nothing (plain text/image posts).
  static const PostExtras empty = PostExtras();
}

typedef PostExtrasWidgetBuilder = Widget Function(
    BuildContext context, PostExtras extras);

/// Resolves a post's match/event side-loads **once** and keeps the result for
/// as long as the list item stays alive.
///
/// The feed used to build these futures inline inside `FutureBuilder(future:
/// Future.wait([...]))`. Because that expression lives in `build()`, every
/// rebuild of the enclosing `Consumer`/`StreamBuilder` created a brand new set
/// of futures and re-issued up to four HTTP requests *per post*. With the feed
/// wrapped in a whole-model `Consumer`, a single `notifyListeners()` therefore
/// cost `posts * 4` requests and forced two render passes per post (null data,
/// then real data).
///
/// This widget keeps the identical two-phase render - [PostExtras.empty] first,
/// then the resolved values - but fetches only when the identifiers actually
/// change. Posts that reference nothing resolve synchronously and never render
/// twice at all.
class PostExtrasBuilder extends StatefulWidget {
  final int? matchId;
  final int? eventId;
  final int? matchResultId;
  final int? eventStandingId;
  final PostExtrasWidgetBuilder builder;

  const PostExtrasBuilder({
    super.key,
    required this.builder,
    this.matchId,
    this.eventId,
    this.matchResultId,
    this.eventStandingId,
  });

  @override
  State<PostExtrasBuilder> createState() => _PostExtrasBuilderState();
}

class _PostExtrasBuilderState extends State<PostExtrasBuilder> {
  PostExtras _extras = PostExtras.empty;

  /// Guards against a late response from a superseded request overwriting a
  /// newer one, and against `setState` after dispose.
  int _requestGeneration = 0;

  bool get _hasNothingToLoad =>
      widget.matchId == null &&
      widget.eventId == null &&
      widget.matchResultId == null &&
      widget.eventStandingId == null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PostExtrasBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matchId != widget.matchId ||
        oldWidget.eventId != widget.eventId ||
        oldWidget.matchResultId != widget.matchResultId ||
        oldWidget.eventStandingId != widget.eventStandingId) {
      _extras = PostExtras.empty;
      _load();
    }
  }

  Future<void> _load() async {
    if (_hasNothingToLoad) {
      // Nothing to fetch: stay on the empty value without burning a frame.
      return;
    }

    final generation = ++_requestGeneration;

    final List<dynamic> results;
    try {
      results = await Future.wait([
        _matchDetails(widget.matchId),
        _eventDetails(widget.eventId),
        _matchDetails(widget.matchResultId),
        _eventStandingDetails(widget.eventStandingId),
      ]);
    } catch (_) {
      // The previous `FutureBuilder` swallowed failures the same way: it read
      // `snapshot.data?[0]`, which is null once the future rejects. Keep the
      // empty value so a failed side-load still renders the bare post.
      return;
    }

    if (!mounted || generation != _requestGeneration) return;

    setState(() {
      _extras = PostExtras(
        match: results[0] as IMatch?,
        event: results[1] as Event?,
        matchResult: results[2] as IMatch?,
        eventStanding: results[3] as List<EventStanding>?,
      );
    });
  }

  Future<IMatch?> _matchDetails(int? matchId) async {
    if (matchId == null) return null;
    return MatchRepository.getInstance().getMatchDetails(matchId);
  }

  Future<Event?> _eventDetails(int? eventId) async {
    if (eventId == null) return null;
    return EventRepository.getInstance().getEventDetails(eventId);
  }

  Future<List<EventStanding>?> _eventStandingDetails(
      int? eventStandingId) async {
    if (eventStandingId == null) return null;
    return EventRepository.getInstance().getEventStandingById(eventStandingId);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _extras);
}

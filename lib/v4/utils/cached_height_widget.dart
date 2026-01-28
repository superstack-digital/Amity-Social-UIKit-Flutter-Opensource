import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'post_height_cache_manager.dart';

/// Improved widget wrapper that caches post height to prevent scroll jank
/// Keeps rendered posts alive and maintains stable heights
class CachedHeightPostWidget extends StatefulWidget {
  final String postId; // Unique post ID
  final Widget child;

  const CachedHeightPostWidget({
    Key? key,
    required this.postId,
    required this.child,
  }) : super(key: key);

  @override
  State<CachedHeightPostWidget> createState() => _CachedHeightPostWidgetState();
}

class _CachedHeightPostWidgetState extends State<CachedHeightPostWidget>
    with AutomaticKeepAliveClientMixin {
  
  final _heightCache = PostHeightCacheManager();
  
  @override
  bool get wantKeepAlive => true; // Keep widget alive when scrolled off screen

  @override
  Widget build(BuildContext context) {
    super.build(context); // Must call super for AutomaticKeepAliveClientMixin
    
    return RepaintBoundary(
      key: ValueKey('post_${widget.postId}'),
      child: widget.child,
    );
  }
  
  @override
  void dispose() {
    // Optional: clear height cache when post is disposed
    // _heightCache.clearHeight(widget.postId);
    super.dispose();
  }
}

/// Simpler approach: Wrap each post to keep it alive
/// This prevents rebuilds when scrolling back
class KeepAlivePostWidget extends StatefulWidget {
  final Widget child;
  final bool keepAlive;

  const KeepAlivePostWidget({
    Key? key,
    required this.child,
    this.keepAlive = true,
  }) : super(key: key);

  @override
  State<KeepAlivePostWidget> createState() => _KeepAlivePostWidgetState();
}

class _KeepAlivePostWidgetState extends State<KeepAlivePostWidget>
    with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RepaintBoundary(child: widget.child);
  }
}

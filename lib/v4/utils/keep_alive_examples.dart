// Example: How to use KeepAlive widgets in your feed

import 'package:flutter/material.dart';
import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/v4/utils/cached_height_widget.dart';

/// Example 1: Simple usage with KeepAlivePostWidget
class SimpleFeedExample extends StatelessWidget {
  final List<AmityPost> posts;

  const SimpleFeedExample({Key? key, required this.posts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Optional: Increase cache extent for smoother scrolling
      cacheExtent: 1000,
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        
        // ✅ Wrap each post with KeepAlivePostWidget
        return KeepAlivePostWidget(
          child: YourPostWidget(post: post),
        );
      },
    );
  }
}

/// Example 2: Conditional keep alive based on content
class SmartFeedExample extends StatelessWidget {
  final List<AmityPost> posts;

  const SmartFeedExample({Key? key, required this.posts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      cacheExtent: 1000,
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        
        // Only keep alive complex posts
        final hasMedia = post.data != null && 
                         (post.data is ImageData || post.data is VideoData);
        
        return KeepAlivePostWidget(
          keepAlive: hasMedia, // ✅ Smart keep alive
          child: YourPostWidget(post: post),
        );
      },
    );
  }
}

/// Example 3: With post ID tracking
class TrackedFeedExample extends StatelessWidget {
  final List<AmityPost> posts;

  const TrackedFeedExample({Key? key, required this.posts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      cacheExtent: 1000,
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        
        return CachedHeightPostWidget(
          postId: post.postId!, // ✅ Track by post ID
          child: YourPostWidget(post: post),
        );
      },
    );
  }
}

/// Example 4: SliverList with keep alive
class SliverFeedExample extends StatelessWidget {
  final List<AmityPost> posts;

  const SliverFeedExample({Key? key, required this.posts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      cacheExtent: 1000,
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final post = posts[index];
              
              return KeepAlivePostWidget(
                child: YourPostWidget(post: post),
              );
            },
            childCount: posts.length,
          ),
        ),
      ],
    );
  }
}

/// Example 5: RefreshIndicator compatible
class RefreshableFeedExample extends StatefulWidget {
  const RefreshableFeedExample({Key? key}) : super(key: key);

  @override
  State<RefreshableFeedExample> createState() => _RefreshableFeedExampleState();
}

class _RefreshableFeedExampleState extends State<RefreshableFeedExample> {
  List<AmityPost> posts = [];
  
  Future<void> _onRefresh() async {
    // Refresh posts
    // Optional: clear height cache on refresh
    // PostHeightCacheManager().clearAllHeights();
    
    setState(() {
      // Update posts
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        cacheExtent: 1000,
        itemCount: posts.length,
        itemBuilder: (context, index) {
          return KeepAlivePostWidget(
            child: YourPostWidget(post: posts[index]),
          );
        },
      ),
    );
  }
}

/// Your actual post widget
class YourPostWidget extends StatelessWidget {
  final AmityPost post;

  const YourPostWidget({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(post.postedUser?.displayName ?? 'Unknown'),
          const SizedBox(height: 8),
          // Your post content here
        ],
      ),
    );
  }
}

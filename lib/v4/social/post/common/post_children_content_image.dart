import 'package:amity_sdk/amity_sdk.dart';
import 'package:amity_uikit_beta_service/v4/core/image_viewer.dart';
import 'package:flutter/material.dart';

class PostContentImage extends StatelessWidget {
  final List<AmityPost> posts;
  const PostContentImage({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return Container();

    Widget backgroundImage(String fileUrl, int index,
        {BorderRadius? borderRadius, double gap = 2.0}) {
      // The grid paints these tiles at anything from a third of the screen
      // (four-up) to full width, but every tile used to be decoded at the
      // source resolution. Decode to the tile's real painted width instead.
      // The tile size comes from AspectRatio/Expanded above, so the decode
      // size cannot affect layout, and allowUpscaling stays off so a source
      // that is already smaller than the tile is left alone.
      return Padding(
        padding: EdgeInsets.all(gap),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            ImageProvider provider = NetworkImage(fileUrl);
            if (maxWidth.isFinite && maxWidth > 0) {
              provider = ResizeImage(
                provider,
                width:
                    (maxWidth * MediaQuery.devicePixelRatioOf(context)).round(),
                allowUpscaling: false,
              );
            }

            return Container(
              padding: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                image: DecorationImage(
                  image: provider,
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      );
    }

    String getURL(AmityPostData postData) {
      if (postData is VideoData) {
        var data = postData;
        return data.thumbnail?.getUrl(AmityImageSize.MEDIUM) ?? "";
      } else if (postData is ImageData) {
        var data = postData;
        return data.image?.getUrl(AmityImageSize.MEDIUM) ?? "";
      } else {
        return "";
      }
    }

    /// Natural aspect ratio of a single attachment, so one image fills the
    /// post width at its own shape instead of being cropped to a square.
    ///
    /// Amity already carries the dimensions in file properties, so this needs
    /// no async measurement and the layout never jumps. Clamped to the same
    /// band Instagram uses -- 4:5 portrait to 1.91:1 landscape -- so a very
    /// tall or very wide upload cannot take over the feed.
    double singleImageRatio(AmityPost post) {
      final data = post.data;
      int? w;
      int? h;
      if (data is ImageData) {
        w = data.image?.getWidth();
        h = data.image?.getHeight();
      } else if (data is VideoData) {
        w = data.thumbnail?.getWidth();
        h = data.thumbnail?.getHeight();
      }
      if (w == null || h == null || w <= 0 || h <= 0) return 1;
      return (w / h).clamp(0.8, 1.91);
    }

    Widget buildSingleImage(List<AmityPost> posts) {
      return AspectRatio(
        aspectRatio: singleImageRatio(posts[0]),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImagePostViewer(
                  posts: posts,
                  initialIndex: 0,
                ),
              ),
            );
          },
          // Full bleed: no inter-tile gap and square corners, so the photo
          // meets both screen edges. Grids below keep their gap and radius.
          child: backgroundImage(getURL(posts[0].data!), 0,
              borderRadius: BorderRadius.zero, gap: 0),
        ),
      );
    }

    Widget buildTwoImages(List<AmityPost> posts) {
      return AspectRatio(
        aspectRatio: 1,
        child: Row(children: [
          Expanded(
              child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImagePostViewer(
                    posts: posts,
                    initialIndex: 0,
                  ),
                ),
              );
            },
            child: backgroundImage(getURL(posts[0].data!), 0,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8))),
          )),
          Expanded(
              child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImagePostViewer(
                    posts: posts,
                    initialIndex: 1,
                  ),
                ),
              );
            },
            child: backgroundImage(getURL(posts[1].data!), 1,
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8))),
          ))
        ]),
      );
    }

    Widget buildThreeImages(List<AmityPost> posts) {
      return AspectRatio(
        aspectRatio: 1,
        child: Column(
          children: [
            Expanded(
                child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImagePostViewer(
                      posts: posts,
                      initialIndex: 0,
                    ),
                  ),
                );
              },
              child: backgroundImage(getURL(posts[0].data!), 0,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8))),
            )),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                      child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImagePostViewer(
                            posts: posts,
                            initialIndex: 1,
                          ),
                        ),
                      );
                    },
                    child: backgroundImage(getURL(posts[1].data!), 1,
                        borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8))),
                  )),
                  Expanded(
                      child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImagePostViewer(
                            posts: posts,
                            initialIndex: 2,
                          ),
                        ),
                      );
                    },
                    child: backgroundImage(getURL(posts[2].data!), 2,
                        borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(8))),
                  )),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget buildFourImages(List<AmityPost> posts) {
      return AspectRatio(
        aspectRatio: 1,
        child: Column(
          children: [
            Expanded(
                child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImagePostViewer(
                      posts: posts,
                      initialIndex: 0,
                    ),
                  ),
                );
              },
              child: backgroundImage(getURL(posts[0].data!), 0,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8))),
            )),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImagePostViewer(
                            posts: posts,
                            initialIndex: 1,
                          ),
                        ),
                      );
                    },
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: backgroundImage(getURL(posts[1].data!), 1,
                          borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8))),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImagePostViewer(
                            posts: posts,
                            initialIndex: 2,
                          ),
                        ),
                      );
                    },
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: backgroundImage(getURL(posts[2].data!), 2),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImagePostViewer(
                            posts: posts,
                            initialIndex: 3,
                          ),
                        ),
                      );
                    },
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: backgroundImage(getURL(posts[3].data!), 3,
                          borderRadius: const BorderRadius.only(
                              bottomRight: Radius.circular(8))),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    Widget buildDefaultImage(List<AmityPost> posts) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(8.0), // Border radius for the entire grid
            // Add other properties like a border or shadow if needed
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                  child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImagePostViewer(
                        posts: posts,
                        initialIndex: 0,
                      ),
                    ),
                  );
                },
                child: backgroundImage(getURL(posts[0].data!), 0,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8))),
              )),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImagePostViewer(
                              posts: posts,
                              initialIndex: 1,
                            ),
                          ),
                        );
                      },
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: backgroundImage(getURL(posts[1].data!), 1,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(8),
                            )),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImagePostViewer(
                              posts: posts,
                              initialIndex: 2,
                            ),
                          ),
                        );
                      },
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: backgroundImage(getURL(posts[2].data!), 2),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImagePostViewer(
                              posts: posts,
                              initialIndex: 3,
                            ),
                          ),
                        );
                      },
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Stack(
                          children: [
                            backgroundImage(getURL(posts[3].data!), 3,
                                borderRadius: const BorderRadius.only(
                                    bottomRight: Radius.circular(8))),
                            // Black filter overlay
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black
                                    .withOpacity(0.3), // Semi-transparent black
                              ),
                            ),
                            // Centered Text "6+"
                            Center(
                              child: Text(
                                "+${posts.length - 3}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      24, // Adjust the font size as needed
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    switch (posts.length) {
      case 1:
        return buildSingleImage(posts);
      case 2:
        return buildTwoImages(posts);
      case 3:
        return buildThreeImages(posts);
      case 4:
        return buildFourImages(posts);
      default:
        return buildDefaultImage(posts);
    }
  }
}

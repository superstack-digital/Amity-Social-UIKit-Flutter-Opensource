import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AmityNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final String placeHolderPath;

  const AmityNetworkImage(
      {super.key, required this.imageUrl, required this.placeHolderPath});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      // Nearly every caller paints this into a small fixed box (32x32 avatars
      // in post headers, comment rows, reaction and member lists) while the
      // source is a full-size Amity avatar. Decoding at the source resolution
      // costs decode time on every scroll-in and a multi-megabyte image-cache
      // entry per avatar. Decode at the size actually painted instead.
      return LayoutBuilder(
        builder: (context, constraints) {
          return Image(
            image: _sizedProvider(context, constraints),
            fit: BoxFit.fill,
            loadingBuilder: (BuildContext context, Widget child,
                ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) {
                return child;
              } else {
                return SvgPicture.asset(
                  placeHolderPath,
                  package: 'amity_uikit_beta_service',
                );
              }
            },
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stackTrace) {
              return SvgPicture.asset(
                placeHolderPath,
                package: 'amity_uikit_beta_service',
              );
            },
          );
        },
      );
    } else {
      return SvgPicture.asset(
        placeHolderPath,
        package: 'amity_uikit_beta_service',
      );
    }
  }

  /// Downscales the decode target to the painted box, but only when the box is
  /// fully bounded - an intrinsically sized image would otherwise change its
  /// layout size along with its decode size. `allowUpscaling: false` keeps
  /// sources that are already smaller than the box untouched, so this can only
  /// ever remove work, never add it.
  ImageProvider _sizedProvider(
      BuildContext context, BoxConstraints constraints) {
    final provider = NetworkImage(imageUrl!);
    if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
      return provider;
    }
    final width = constraints.maxWidth;
    if (width <= 0) return provider;

    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    return ResizeImage(
      provider,
      width: (width * devicePixelRatio).round(),
      allowUpscaling: false,
    );
  }
}

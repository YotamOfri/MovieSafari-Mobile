import 'dart:ui';
import 'package:flutter/material.dart';

class TmdbImage extends StatelessWidget {
  final String? path;
  final String lowResSize;
  final String highResSize;
  final BoxFit fit;
  final double? width;
  final double? height;
  final bool disableBlur;

  const TmdbImage({
    super.key,
    required this.path,
    this.lowResSize = 'w92',
    this.highResSize = 'w500',
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.disableBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    if (path == null) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFF1A1C23),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: disableBlur 
          ? Image.network(
              'https://image.tmdb.org/t/p/$highResSize$path',
              fit: fit,
              cacheWidth: 400, // Hardware downsampling for max scroll FPS
            )
          : Stack(
              fit: StackFit.expand,
              children: [
            // Low res blurred image (using ImageFiltered instead of BackdropFilter for better FPS)
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Image.network(
                'https://image.tmdb.org/t/p/$lowResSize$path',
                fit: fit,
              ),
            ),
            // Slight dark tint over the placeholder
            Container(color: Colors.black.withOpacity(0.1)),
            // High res image fading in
            Image.network(
              'https://image.tmdb.org/t/p/$highResSize$path',
              fit: fit,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) {
                  return child;
                }
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  child: child,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

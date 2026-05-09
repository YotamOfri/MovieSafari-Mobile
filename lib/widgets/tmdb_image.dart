import 'package:flutter/material.dart';

class TmdbImage extends StatelessWidget {
  final String? path;
  final String highResSize;
  final BoxFit fit;
  final double? width;
  final double? height;

  const TmdbImage({
    super.key,
    required this.path,
    this.highResSize = 'w500',
    this.fit = BoxFit.cover,
    this.width,
    this.height,
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

    // Use actual screen width as fallback when width is infinite (e.g. double.infinity),
    // scaled by device pixel ratio so we decode at native resolution — not a fixed 600px.
    final double dpr = MediaQuery.of(context).devicePixelRatio;
    final double screenWidth = MediaQuery.of(context).size.width;
    final int effectiveCacheWidth = (width != null && width!.isFinite)
        ? (width! * dpr).round()
        : (screenWidth * dpr).clamp(1, 1440).round();

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Static dark placeholder — zero GPU cost, no extra texture upload.
            const ColoredBox(color: Color(0xFF1A1C23)),

            // Single high-res image; fades in once decoded.
            // Using one image (instead of the previous low-res + high-res stack)
            // halves the number of GPU texture uploads per card.
            Image.network(
              'https://image.tmdb.org/t/p/$highResSize$path',
              fit: fit,
              cacheWidth: effectiveCacheWidth,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF1A1C23),
                child: const Center(
                  child: Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white10,
                    size: 24,
                  ),
                ),
              ),
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                // Already in cache — show immediately, no fade needed.
                if (wasSynchronouslyLoaded) return child;
                // Fade in once the first frame arrives.
                return AnimatedOpacity(
                  opacity: frame == null ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 500),
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

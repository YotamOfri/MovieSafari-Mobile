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

    // Optimized cache sizes based on common usage
    final int? effectiveCacheWidth = (width != null && width!.isFinite) 
        ? (width! * MediaQuery.of(context).devicePixelRatio).round() 
        : 600;

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: disableBlur 
          ? Image.network(
              'https://image.tmdb.org/t/p/$highResSize$path',
              fit: fit,
              cacheWidth: effectiveCacheWidth,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF1A1C23),
                child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white10, size: 24)),
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
            // Low res blurred image
            Image.network(
              'https://image.tmdb.org/t/p/$lowResSize$path',
              fit: fit,
              cacheWidth: 100, // Small for blur
              errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF1A1C23)),
            ),
            // High res image fading in
            Image.network(
              'https://image.tmdb.org/t/p/$highResSize$path',
              fit: fit,
              cacheWidth: effectiveCacheWidth,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
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

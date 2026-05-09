import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../providers/bookmark_provider.dart';
import '../../../widgets/tmdb_image.dart';
import '../../../widgets/custom_toast.dart';

class DetailsHeader extends StatelessWidget {
  final int id;
  final String type;
  final Map<String, dynamic> details;
  final int? continueSeason;
  final int? continueEpisode;
  final String? heroTag;

  const DetailsHeader({
    super.key,
    required this.id,
    required this.type,
    required this.details,
    this.continueSeason,
    this.continueEpisode,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final String? backdrop = details['backdrop_path'];
    final String title = details['title'] ?? details['name'] ?? 'Unknown';

    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.height * 0.45,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF0F1014),
      surfaceTintColor: Colors.transparent,
      leadingWidth: 70,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.0,
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: BookmarkButton(
            id: id,
            type: type,
            title: title,
            posterPath: details['poster_path'],
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final top = constraints.biggest.height;
          final isCollapsed = top <= kToolbarHeight + MediaQuery.of(context).padding.top + 10;

          return FlexibleSpaceBar(
            centerTitle: true,
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isCollapsed ? 1.0 : 0.0,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (backdrop != null)
                  TmdbImage(path: backdrop, highResSize: 'w1280')
                else
                  Container(color: const Color(0xFF1A1C23)),

                // Optimized glass effect when pinned
                if (isCollapsed)
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1014).withValues(alpha: 0.8),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withValues(alpha: 0.1),
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Cinematic Shadow Dissolve
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.0, 0.4, 0.6, 0.8, 0.95, 1.0],
                    ),
                  ),
                ),
                if (!isCollapsed) ...[
                  // Floating Poster for Hero Animation landing
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Hero(
                      tag: heroTag ?? 'media_${type}_$id',
                      child: Container(
                        width: 100,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: TmdbImage(
                            path: details['poster_path'],
                            highResSize: 'w400',
                          ),
                        ),
                      ),
                    ),
                  ),

                  Center(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        if (type == 'tv') {
                          final s = continueSeason ?? 1;
                          final e = continueEpisode ?? 1;
                          context.push('/player/$type/$id?season=$s&episode=$e');
                        } else {
                          context.push('/player/$type/$id');
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: continueEpisode != null ? 24 : 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(continueEpisode != null ? 32 : 100),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              continueEpisode != null 
                                  ? Icons.play_circle_rounded 
                                  : Icons.play_arrow_rounded,
                              size: continueEpisode != null ? 28 : 64,
                              color: Colors.white,
                            ),
                            if (continueEpisode != null) ...[
                              const SizedBox(width: 12),
                              const Text(
                                'CONTINUE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class BookmarkButton extends ConsumerWidget {
  final int id;
  final String type;
  final String title;
  final String? posterPath;

  const BookmarkButton({
    super.key,
    required this.id,
    required this.type,
    required this.title,
    this.posterPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(bookmarkProvider).any((b) => b.id == id && b.mediaType == type);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1.0,
          ),
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: HugeIcon(
            icon: isBookmarked
                ? HugeIcons.strokeRoundedBookmark02
                : HugeIcons.strokeRoundedBookmark01,
            color: isBookmarked ? Colors.blueAccent : Colors.white,
            size: 18,
          ),
          onPressed: () {
            final bookmark = Bookmark(
              id: id,
              title: title,
              mediaType: type,
              posterPath: posterPath,
            );

            ref.read(bookmarkProvider.notifier).toggleBookmark(bookmark);

            CustomToast.show(
              context: context,
              message: isBookmarked ? 'Removed $title' : 'Added $title to Bookmarks',
              icon: isBookmarked ? Icons.bookmark_remove : Icons.bookmark_add,
              posterPath: posterPath,
              onUndo: () {
                ref.read(bookmarkProvider.notifier).toggleBookmark(bookmark);
              },
            );
          },
        ),
      ),
    );
  }
}

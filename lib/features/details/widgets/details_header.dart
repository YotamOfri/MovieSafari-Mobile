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

  const DetailsHeader({
    super.key,
    required this.id,
    required this.type,
    required this.details,
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
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

                // Glass effect when pinned
                if (isCollapsed)
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
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
                if (!isCollapsed)
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        if (type == 'tv') {
                          context.push('/player/$type/$id?season=1&episode=1');
                        } else {
                          context.push('/player/$type/$id');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
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
        ),
      ),
    );
  }
}

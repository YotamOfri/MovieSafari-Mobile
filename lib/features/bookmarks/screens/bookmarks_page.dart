import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../providers/bookmark_provider.dart';
import '../../../widgets/tmdb_image.dart';
import '../../../widgets/media_context_menu.dart';
import '../../../widgets/pressable_card.dart';
import '../../../widgets/discovery_button.dart';

class BookmarksPage extends ConsumerWidget {
  const BookmarksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarkProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1014),
      body: Stack(
        children: [
          // 1. Dynamic Soft Backdrop
          if (bookmarks.isNotEmpty)
            Positioned.fill(
              child: RepaintBoundary(
                child: Image.network(
                  'https://image.tmdb.org/t/p/w92${bookmarks.first.posterPath}',
                  fit: BoxFit.cover,
                  color: Colors.white.withValues(alpha: 0.3),
                  colorBlendMode: BlendMode.modulate,
                  cacheWidth: 100,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),

          // 2. Cinematic Shadow Overlays
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0F1014).withValues(alpha: 0.4),
                    const Color(0xFF0F1014).withValues(alpha: 0.8),
                    const Color(0xFF0F1014),
                  ],
                  stops: const [0.0, 0.4, 0.8],
                ),
              ),
            ),
          ),

          // 3. Content
          SafeArea(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text(
                'My Bookmarks',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your saved movies & shows',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: bookmarks.isEmpty
                    ? _buildEmptyState(context)
                    : GridView.builder(
                        padding: const EdgeInsets.only(bottom: 120),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2 / 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: bookmarks.length,
                        itemBuilder: (context, index) {
                          final bookmark = bookmarks[index];
                          return _buildBookmarkCard(context, ref, bookmark);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1.0,
                ),
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                size: 64,
                color: Colors.blueAccent.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Your library is empty',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Save movies and series you want to watch later and they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            DiscoveryButton(
              label: 'Explore Movies',
              icon: Icons.explore_rounded,
              onTap: () => context.go('/'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkCard(BuildContext context, WidgetRef ref, Bookmark bookmark) {
    return PressableCard(
      onTap: () {
        context.push('/details/${bookmark.mediaType}/${bookmark.id}');
      },
      onLongPress: () {
        MediaContextMenu.show(
          context,
          ref,
          bookmark.toJson(),
          bookmark.mediaType,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            TmdbImage(
              path: bookmark.posterPath,
              highResSize: 'w400',
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      bookmark.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bookmark.mediaType == 'movie' ? 'Movie' : 'Series',
                      style: TextStyle(
                        fontSize: 11,
                        color: bookmark.mediaType == 'movie'
                            ? Colors.purpleAccent
                            : Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

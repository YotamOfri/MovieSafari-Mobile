import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/bookmark_provider.dart';
import '../providers/watch_history_provider.dart';
import 'tmdb_image.dart';

class MediaContextMenu {
  static void show(BuildContext context, WidgetRef ref,
      Map<String, dynamic> item, String type) {
    final int id = item['id'];
    final String title = item['title'] ?? item['name'] ?? 'Unknown';
    final String? posterPath = item['poster_path'];
    final double rating = (item['vote_average'] as num?)?.toDouble() ?? 0.0;
    final String year = (item['release_date'] ?? item['first_air_date'] ?? '')
        .toString()
        .split('-')[0];
    final String overview = item['overview'] ?? '';

    final bookmarkNotifier = ref.read(bookmarkProvider.notifier);
    final historyNotifier = ref.read(watchHistoryProvider.notifier);
    final isBookmarked = bookmarkNotifier.isBookmarked(id, type);
    
    final entry = historyNotifier.getEntry(id, type);
    final bool isFinished = entry?.isFinished ?? false;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1C23).withOpacity(0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 100,
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: TmdbImage(path: posterPath, highResSize: 'w200'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (year.isNotEmpty) ...[
                              Text(
                                year,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 14),
                              ),
                              const SizedBox(width: 12),
                            ],
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          overview,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                            height: 1.4,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 12),
              _ContextAction(
                icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                label: isBookmarked ? 'Remove Bookmark' : 'Add to Bookmarks',
                color: Colors.blueAccent,
                onTap: () {
                  bookmarkNotifier.toggleBookmark(Bookmark(
                      id: id,
                      title: title,
                      mediaType: type,
                      posterPath: posterPath));
                  Navigator.pop(sheetContext);
                },
              ),
              _ContextAction(
                icon: isFinished ? Icons.check_circle : Icons.check_circle_outline,
                label: isFinished ? 'Mark as Unwatched' : 'Mark as Watched',
                color: Colors.greenAccent,
                onTap: () {
                  historyNotifier.toggleFinished(
                    id: id,
                    mediaType: type,
                    title: title,
                    posterPath: posterPath,
                  );
                  Navigator.pop(sheetContext);
                },
              ),
              _ContextAction(
                icon: Icons.info_outline,
                label: 'View Full Details',
                color: Colors.white70,
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/details/$type/$id');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ContextAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color, size: 22),
      title:
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      onTap: onTap,
    );
  }
}

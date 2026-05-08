import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/bookmark_provider.dart';
import '../../../providers/watch_history_provider.dart';
import '../../../widgets/tmdb_image.dart';

class HorizontalMediaList extends ConsumerWidget {
  final List<dynamic> items;
  final String? defaultType;

  const HorizontalMediaList(
      {super.key, required this.items, this.defaultType});

  void _showContextMenu(BuildContext context, WidgetRef ref, int id,
      String type, String title, String? posterPath, bool isFinished) {
    final bookmarkNotifier = ref.read(bookmarkProvider.notifier);
    final historyNotifier = ref.read(watchHistoryProvider.notifier);
    final isBookmarked = bookmarkNotifier.isBookmarked(id, type);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1C23),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _ContextAction(
              icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              label: isBookmarked ? 'Remove Bookmark' : 'Bookmark',
              color: Colors.blueAccent,
              onTap: () {
                bookmarkNotifier.toggleBookmark(Bookmark(
                    id: id,
                    title: title,
                    mediaType: type,
                    posterPath: posterPath));
                Navigator.pop(context);
              },
            ),
            _ContextAction(
              icon: isFinished
                  ? Icons.check_circle
                  : Icons.check_circle_outline,
              label: isFinished ? 'Mark as Unwatched' : 'Mark as Watched',
              color: Colors.greenAccent,
              onTap: () {
                if (!isFinished) {
                  historyNotifier.markFinished(id: id, mediaType: type);
                }
                Navigator.pop(context);
              },
            ),
            _ContextAction(
              icon: Icons.info_outline,
              label: 'Open Details',
              color: Colors.white70,
              onTap: () {
                Navigator.pop(context);
                context.push('/details/$type/$id');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyNotifier = ref.watch(watchHistoryProvider.notifier);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final String? posterPath = item['poster_path'];
        final int id = item['id'];
        final String type = item['media_type'] ?? defaultType ?? 'tv';
        final String title = item['title'] ?? item['name'] ?? 'Unknown';
        final entry = historyNotifier.getEntry(id, type);
        final bool isFinished = entry?.isFinished ?? false;

        return Padding(
          padding: const EdgeInsets.only(right: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/details/$type/$id'),
                  onLongPress: () => _showContextMenu(
                      context, ref, id, type, title, posterPath, isFinished),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          TmdbImage(path: posterPath, highResSize: 'w400'),
                          // Watched badge
                          if (isFinished) ...[
                            Container(
                                color: Colors.black.withOpacity(0.4)),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.greenAccent.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check,
                                        color: Colors.black, size: 10),
                                    SizedBox(width: 3),
                                    Text('Watched',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          // In-progress blue dot
                          if (entry != null && !isFinished)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

class HorizontalLoadingPlaceholder extends StatelessWidget {
  const HorizontalLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: Container(color: const Color(0xFF1A1C23)),
          ),
        ),
      ),
    );
  }
}

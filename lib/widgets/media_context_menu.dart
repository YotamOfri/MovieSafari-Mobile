import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/bookmark_provider.dart';
import '../providers/watch_history_provider.dart';
import '../providers/api_provider.dart';
import 'tmdb_image.dart';

class MediaContextMenu {
  static void show(BuildContext context, WidgetRef ref,
      Map<String, dynamic> item, String type) {
    HapticFeedback.mediumImpact();
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
        child: Consumer(
          builder: (context, ref, _) {
            // Check if we need to fetch more data
            final bool needsData = item['overview'] == null || item['vote_average'] == null;
            
            AsyncValue<Map<String, dynamic>>? detailsAsync;
            if (needsData) {
              detailsAsync = type == 'movie'
                  ? ref.watch(movieDetailsProvider(id))
                  : ref.watch(tvDetailsProvider(id));
            }

            // Extract display data, prefer details if available
            final data = detailsAsync?.value ?? item;
            final String displayTitle = data['title'] ?? data['name'] ?? title;
            final String? displayPoster = data['poster_path'] ?? posterPath;
            final double displayRating = (data['vote_average'] as num?)?.toDouble() ?? rating;
            final String displayYear = (data['release_date'] ?? data['first_air_date'] ?? year)
                .toString()
                .split('-')[0];
            final String displayOverview = data['overview'] ?? overview;

            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1C23).withValues(alpha: 0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                        color: Colors.white.withValues(alpha: 0.2),
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
                            child: TmdbImage(path: displayPoster, highResSize: 'w200'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (needsData && detailsAsync != null && detailsAsync.isLoading)
                              const SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.blueAccent),
                              )
                            else
                              Row(
                                children: [
                                  if (displayYear.isNotEmpty) ...[
                                    Text(
                                      displayYear,
                                      style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 14),
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  const Icon(Icons.star_rounded,
                                      color: Colors.amber, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    displayRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 12),
                            if (needsData && detailsAsync != null && detailsAsync.isLoading)
                              Container(
                                height: 60,
                                alignment: Alignment.centerLeft,
                                child: Text('Loading description...',
                                    style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.3),
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic)),
                              )
                            else
                              Text(
                                displayOverview,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
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
                      final title = displayTitle;
                      bookmarkNotifier.toggleBookmark(Bookmark(
                          id: id,
                          title: title,
                          mediaType: type,
                          posterPath: displayPoster));
                      
                      Navigator.pop(sheetContext);
                      
                      // Show Premium Toast
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
                          content: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutBack,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: Opacity(
                                  opacity: value.clamp(0.0, 1.0),
                                  child: child,
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 30,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isBookmarked ? Icons.bookmark_remove : Icons.bookmark_add,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          isBookmarked 
                                              ? 'Removed $title' 
                                              : 'Added $title to Bookmarks',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
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
                        title: displayTitle,
                        posterPath: displayPoster,
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
                  if (entry != null) ...[
                    const SizedBox(height: 12),
                    _ContextAction(
                      icon: Icons.history_toggle_off,
                      label: 'Remove from History',
                      color: Colors.redAccent,
                      onTap: () {
                        historyNotifier.removeEntry(id, type);
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ],
                ],
              ),
            );
          },
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
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}

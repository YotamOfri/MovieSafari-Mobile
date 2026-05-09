import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/tmdb_image.dart';
import '../../../widgets/media_context_menu.dart';
import '../../../widgets/pressable_card.dart';

class TopTenMediaList extends ConsumerWidget {
  final List<dynamic> items;
  final String? defaultType;

  const TopTenMediaList({super.key, required this.items, this.defaultType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayItems = items.take(10).toList();

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 16, right: 8),
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final item = displayItems[index];
        final String? posterPath = item['poster_path'];
        final String title = item['title'] ?? item['name'] ?? '';
        final int id = item['id'];
        final String type = item['media_type'] ?? defaultType ?? 'movie';
        final double rating =
            (item['vote_average'] as num?)?.toDouble() ?? 0.0;

        // Rank gradient colors: gold for 1, silver for 2, bronze for 3, white for rest
        final Color rankColor = index == 0
            ? const Color(0xFFFFD700)
            : index == 1
                ? const Color(0xFFC0C0C0)
                : index == 2
                    ? const Color(0xFFCD7F32)
                    : Colors.white.withValues(alpha: 0.6);

        return Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: SizedBox(
            width: 130,
            child: PressableCard(
              onTap: () => context.push('/details/$type/$id'),
              onLongPress: () {
                HapticFeedback.heavyImpact();
                MediaContextMenu.show(context, ref, item, type);
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster + rank overlay
                  Expanded(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Poster card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox.expand(
                            child: TmdbImage(
                              path: posterPath,
                              highResSize: 'w342',
                            ),
                          ),
                        ),
                        // Rank badge — top-left pill
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: rankColor.withValues(alpha: 0.8),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '#${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: rankColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Rating badge — bottom-right
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Colors.amber,
                                  size: 11,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Title below card
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class TopTenLoadingPlaceholder extends StatelessWidget {
  const TopTenLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: 16, right: 8),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(right: 10.0),
        child: SizedBox(
          width: 130,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(color: const Color(0xFF1A1C23)),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 10,
                width: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1C23),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

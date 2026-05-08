import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/watch_history_provider.dart';
import '../../../widgets/tmdb_image.dart';
import '../../../widgets/media_context_menu.dart';
import '../../../widgets/pressable_card.dart';

class HorizontalMediaList extends ConsumerWidget {
  final List<dynamic> items;
  final String? defaultType;

  const HorizontalMediaList(
      {super.key, required this.items, this.defaultType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(watchHistoryProvider);

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final String? posterPath = item['poster_path'];
        final int id = item['id'];
        final String type = item['media_type'] ?? defaultType ?? 'tv';
        final entry = history.cast<WatchedEntry?>().firstWhere(
            (e) => e?.id == id && e?.mediaType == type,
            orElse: () => null);
        final bool isFinished = entry?.isFinished ?? false;

        return Padding(
          padding: const EdgeInsets.only(right: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PressableCard(
                  onTap: () => context.push('/details/$type/$id'),
                  onLongPress: () {
                    HapticFeedback.heavyImpact();
                    MediaContextMenu.show(context, ref, item, type);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          TmdbImage(path: posterPath, highResSize: 'w400'),
                          if (isFinished) ...[
                            Container(color: Colors.black.withOpacity(0.4)),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withOpacity(0.85),
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

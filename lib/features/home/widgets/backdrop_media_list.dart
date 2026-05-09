import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/tmdb_image.dart';
import '../../../widgets/media_context_menu.dart';
import '../../../widgets/pressable_card.dart';

class BackdropMediaList extends ConsumerWidget {
  final List<dynamic> items;
  final String? defaultType;

  const BackdropMediaList({super.key, required this.items, this.defaultType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final String? backdropPath = item['backdrop_path'] ?? item['poster_path'];
        final String title = item['title'] ?? item['name'] ?? 'Unknown';
        final int id = item['id'];
        final String type = item['media_type'] ?? defaultType ?? 'tv';

        return Padding(
          padding: const EdgeInsets.only(right: 14.0),
          child: SizedBox(
            width: 260,
            child: PressableCard(
              onTap: () => context.push('/details/$type/$id'),
              onLongPress: () {
                HapticFeedback.vibrate();
                MediaContextMenu.show(context, ref, item, type);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TmdbImage(path: backdropPath, highResSize: 'w500'),
                    // Gradient overlay for text readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.8),
                          ],
                          stops: const [0.0, 0.6, 1.0],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class BackdropLoadingPlaceholder extends StatelessWidget {
  const BackdropLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(right: 14.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 260,
            color: const Color(0xFF1A1C23),
          ),
        ),
      ),
    );
  }
}

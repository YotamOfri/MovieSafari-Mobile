import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/api_provider.dart';
import '../../../widgets/tmdb_image.dart';
import '../../../widgets/skeleton_loader.dart';

class CastList extends ConsumerWidget {
  final int id;
  final String type;

  const CastList({
    super.key,
    required this.id,
    required this.type,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creditsAsync = ref.watch(mediaCreditsProvider((id, type)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Cast & Crew',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        creditsAsync.when(
          data: (cast) {
            if (cast.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cast.length.clamp(0, 15),
                itemBuilder: (context, index) {
                  final person = cast[index];
                  return Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(45),
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: TmdbImage(
                              path: person['profile_path'],
                              highResSize: 'h632',
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          person['name'] ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          person['character'] ?? '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const SkeletonList(height: 160),
          error: (e, s) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/api_provider.dart';
import '../../../providers/watch_history_provider.dart';
import '../../../widgets/tmdb_image.dart';
import '../../../widgets/skeleton_loader.dart';

class EpisodeSelector extends ConsumerWidget {
  final int id;
  final int selectedSeason;
  final List<dynamic> seasons;
  final Function(int) onSeasonChanged;

  const EpisodeSelector({
    super.key,
    required this.id,
    required this.selectedSeason,
    required this.seasons,
    required this.onSeasonChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validSeasons = seasons.where((s) => s['season_number'] > 0).toList();
    if (validSeasons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Episodes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedSeason,
                dropdownColor: const Color(0xFF1A1C23),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white60),
                isExpanded: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                selectedItemBuilder: (context) => validSeasons.map((season) {
                  return Center(
                    child: Row(
                      children: [
                        Text(
                          season['name'] ?? 'Season ${season['season_number']}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${season['episode_count']} Episodes)',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                items: validSeasons.map((season) {
                  return DropdownMenuItem<int>(
                    value: season['season_number'],
                    child: Text(season['name'] ?? 'Season ${season['season_number']}'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    HapticFeedback.mediumImpact();
                    onSeasonChanged(value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          ref.watch(tvSeasonDetailsProvider((id, selectedSeason))).when(
                data: (seasonData) {
                  final episodes = seasonData['episodes'] as List<dynamic>? ?? [];
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: episodes.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final episode = episodes[index];
                      final int epNumber = episode['episode_number'];
                      final String epName = episode['name'] ?? 'Episode $epNumber';
                      final String? epStill = episode['still_path'];
                      final bool isWatched = ref
                          .read(watchHistoryProvider.notifier)
                          .isEpisodeFinished(id, selectedSeason, epNumber);

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          context.push(
                            '/player/tv/$id?season=$selectedSeason&episode=$epNumber',
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.03)),
                          ),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 120,
                                      height: 70,
                                      child: TmdbImage(path: epStill, highResSize: 'w300'),
                                    ),
                                  ),
                                  if (isWatched)
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.check_circle, color: Colors.greenAccent, size: 24),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$epNumber. $epName',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      episode['overview'] ?? 'No description available',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 11,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const SkeletonLoader(width: double.infinity, height: 200),
                error: (e, s) => const SizedBox.shrink(),
              ),
        ],
      ),
    );
  }
}

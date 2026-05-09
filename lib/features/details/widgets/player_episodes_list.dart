import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../providers/api_provider.dart';
import '../../../providers/watch_history_provider.dart';
import '../../../widgets/tmdb_image.dart';

class PlayerEpisodesList extends ConsumerWidget {
  final int id;
  final int season;
  final int currentEpisode;
  final ScrollController scrollController;

  const PlayerEpisodesList({
    super.key,
    required this.id,
    required this.season,
    required this.currentEpisode,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyNotifier = ref.watch(watchHistoryProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            'Episodes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ref.watch(tvSeasonDetailsProvider((id, season))).when(
            data: (seasonData) {
              final episodes = seasonData['episodes'] as List<dynamic>? ?? [];
              if (episodes.isEmpty) {
                return const Center(
                  child: Text(
                    'No episodes available',
                    style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w600),
                  ),
                );
              }

              return ListView.separated(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                itemCount: episodes.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final episode = episodes[index];
                  final int epNumber = episode['episode_number'];
                  final String epName = episode['name'] ?? 'Episode $epNumber';
                  final String? epStill = episode['still_path'];
                  final int? epRuntime = episode['runtime'];
                  final bool isSelected = currentEpisode == epNumber;
                  final bool isWatched = historyNotifier.isEpisodeFinished(id, season, epNumber);

                  return _EpisodeCard(
                    epNumber: epNumber,
                    epName: epName,
                    epStill: epStill,
                    epRuntime: epRuntime,
                    isSelected: isSelected,
                    isWatched: isWatched,
                    onTap: () {
                      if (!isSelected) {
                        context.pushReplacement('/player/tv/$id?season=$season&episode=$epNumber');
                      }
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
            error: (_, __) => const Center(
              child: Text('Error loading episodes', style: TextStyle(color: Colors.white54)),
            ),
          ),
        ),
      ],
    );
  }
}

class _EpisodeCard extends StatelessWidget {
  final int epNumber;
  final String epName;
  final String? epStill;
  final int? epRuntime;
  final bool isSelected;
  final bool isWatched;
  final VoidCallback onTap;

  const _EpisodeCard({
    required this.epNumber,
    required this.epName,
    required this.epStill,
    required this.epRuntime,
    required this.isSelected,
    required this.isWatched,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image with Dark Overlay
              if (epStill != null)
                TmdbImage(
                  path: epStill,
                  highResSize: 'w300',
                  fit: BoxFit.cover,
                )
              else
                Container(color: Colors.white.withValues(alpha: 0.05)),

              // 1. Dark Overlay (Creates "Lower Opacity" Look)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                ),
              ),

              // 2. Dynamic Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // "Now Playing" or "Watched" Indicator
              if (isSelected || isWatched)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _StatusPill(
                    icon: isSelected ? Icons.play_arrow_rounded : Icons.check_circle_rounded,
                    label: isSelected ? 'Now Playing' : 'Watched',
                    color: isSelected ? Colors.white : Colors.greenAccent,
                  ),
                ),

              // Episode Info
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'EPISODE $epNumber',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        if (epRuntime != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.access_time_rounded,
                            color: Colors.white.withValues(alpha: 0.5),
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${epRuntime}m',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      epName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Play Icon for selection
              if (isSelected)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: const HugeIcon(
                        icon: HugeIcons.strokeRoundedPlayCircle,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 10),
              const SizedBox(width: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

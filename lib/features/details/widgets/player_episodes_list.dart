import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../providers/api_provider.dart';


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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Episodes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ref.watch(tvSeasonDetailsProvider((id, season))).when(
            data: (seasonData) {
              final episodes = seasonData['episodes'] as List<dynamic>? ?? [];
              if (episodes.isEmpty) {
                return const Center(child: Text('No episodes', style: TextStyle(color: Colors.white54)));
              }
              
              return ListView.separated(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                cacheExtent: 1000,
                itemCount: episodes.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final episode = episodes[index];
                  final int epNumber = episode['episode_number'];
                  final String epName = episode['name'] ?? 'Episode $epNumber';
                  final String? epStill = episode['still_path'];
                  final bool isSelected = currentEpisode == epNumber;
                  
                  return GestureDetector(
                    onTap: () {
                      if (!isSelected) {
                        context.pushReplacement('/player/tv/$id?season=$season&episode=$epNumber');
                      }
                    },
                    child: Container(
                      width: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.blueAccent : Colors.transparent,
                          width: 2,
                        ),
                        color: const Color(0xFF1A1C23),
                        image: epStill != null
                            ? DecorationImage(
                                image: ResizeImage(
                                  NetworkImage('https://image.tmdb.org/t/p/w300$epStill'),
                                  width: 400,
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: isSelected ? Colors.blueAccent.withValues(alpha: 0.2) : null,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.9),
                            ],
                            stops: const [0.4, 1.0],
                          ),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (epStill == null)
                              const Center(child: Icon(Icons.tv, color: Colors.white54)),

                            Positioned(
                              bottom: 12,
                              left: 12,
                              right: 12,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (isSelected)
                                    const Text(
                                      'Now Playing',
                                      style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  Text(
                                    '$epNumber. $epName',
                                    style: TextStyle(
                                      color: isSelected ? Colors.blueAccent : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Center(
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedPlayCircle,
                                  color: Colors.blueAccent,
                                  size: 40,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error loading episodes', style: TextStyle(color: Colors.white54))),
          ),
        ),
      ],
    );
  }
}

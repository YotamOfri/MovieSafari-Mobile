import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/api_provider.dart';
import '../../../providers/watch_history_provider.dart';
import '../../../widgets/tmdb_image.dart';
import '../widgets/home_hero_section.dart';
import '../widgets/horizontal_media_list.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(trendingMoviesProvider);
    final seriesAsync = ref.watch(trendingSeriesProvider);
    final history = ref.watch(watchHistoryProvider);
    final continueWatching = ref
        .read(watchHistoryProvider.notifier)
        .continueWatching;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trendingMoviesProvider);
          ref.invalidate(trendingSeriesProvider);
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section
              seriesAsync.when(
                data: (series) {
                  if (series.isEmpty) return const SizedBox.shrink();
                  final heroId = series.first['id'];
                  final detailsAsync = ref.watch(tvDetailsProvider(heroId));
                  return detailsAsync.when(
                    data: (details) => HomeHeroSection(details: details),
                    loading: () => const HeroLoadingPlaceholder(),
                    error: (e, s) => const SizedBox(height: 500),
                  );
                },
                loading: () => const HeroLoadingPlaceholder(),
                error: (e, s) => const SizedBox(height: 500),
              ),

              // Continue Watching Section
              if (continueWatching.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildSectionTitle('Continue Watching'),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: continueWatching.length,
                    itemBuilder: (context, index) {
                      final entry = continueWatching[index];
                      return _ContinueWatchingCard(entry: entry);
                    },
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Trending Movies
              _buildSectionTitle('Trending Movies'),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: moviesAsync.when(
                  data: (movies) => HorizontalMediaList(items: movies),
                  loading: () => const HorizontalLoadingPlaceholder(),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
              ),

              const SizedBox(height: 32),

              // Trending Series
              _buildSectionTitle('Trending Series'),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: seriesAsync.when(
                  data: (series) => HorizontalMediaList(items: series),
                  loading: () => const HorizontalLoadingPlaceholder(),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ContinueWatchingCard extends StatelessWidget {
  final WatchedEntry entry;

  const _ContinueWatchingCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final subtitle = entry.mediaType == 'tv' && entry.lastSeason != null
        ? 'S${entry.lastSeason}E${entry.lastEpisode}'
        : 'Movie';

    return Padding(
      padding: const EdgeInsets.only(right: 14.0),
      child: GestureDetector(
        onTap: () {
          if (entry.mediaType == 'tv') {
            context.push(
                '/player/${entry.mediaType}/${entry.id}?season=${entry.lastSeason}&episode=${entry.lastEpisode}');
          } else {
            context.push('/player/${entry.mediaType}/${entry.id}');
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TmdbImage(path: entry.posterPath, highResSize: 'w400'),
                // Dark gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
                // Play icon
                const Center(
                  child: Icon(
                    Icons.play_circle_filled,
                    color: Colors.white70,
                    size: 36,
                  ),
                ),
                // Bottom label
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

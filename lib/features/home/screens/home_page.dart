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
    final moviesAsync = ref.watch(filteredMoviesProvider);
    final seriesAsync = ref.watch(filteredSeriesProvider);
    final heroSeriesAsync = ref.watch(trendingSeriesProvider); // hero always trending
    final continueWatching =
        ref.read(watchHistoryProvider.notifier).continueWatching;
    final selectedGenre = ref.watch(selectedGenreProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(filteredMoviesProvider);
          ref.invalidate(filteredSeriesProvider);
          ref.invalidate(trendingSeriesProvider);
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Section (always trending, genre doesn't affect hero)
              heroSeriesAsync.when(
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

              // Genre Filter Chips
              const SizedBox(height: 20),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _GenreChip(
                        label: 'All',
                        isSelected: selectedGenre == null,
                        onTap: () => ref
                            .read(selectedGenreProvider.notifier)
                            .select(null)),
                    ...tmdbGenres.entries.map((entry) => _GenreChip(
                          label: entry.value,
                          isSelected: selectedGenre == entry.key,
                          onTap: () => ref
                              .read(selectedGenreProvider.notifier)
                              .select(entry.key),
                        )),
                  ],
                ),
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

              // Movies Section
              _buildSectionTitle(selectedGenre == null
                  ? 'Trending Movies'
                  : '${tmdbGenres[selectedGenre]} Movies'),
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

              // Series Section
              _buildSectionTitle(selectedGenre == null
                  ? 'Trending Series'
                  : '${tmdbGenres[selectedGenre]} Series'),
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

class _GenreChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenreChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent
              : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

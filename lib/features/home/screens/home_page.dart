import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../providers/api_provider.dart';
import '../../../providers/watch_history_provider.dart';
import '../../../widgets/tmdb_image.dart';
import '../widgets/home_hero_carousel.dart';
import '../widgets/horizontal_media_list.dart';
import '../widgets/backdrop_media_list.dart';
import '../widgets/top_ten_media_list.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heroAsync = ref.watch(heroCarouselProvider);
    final moviesAsync = ref.watch(filteredMoviesProvider);
    final seriesAsync = ref.watch(filteredSeriesProvider);
    final topRatedMoviesAsync = ref.watch(topRatedMoviesProvider);
    final upcomingMoviesAsync = ref.watch(upcomingMoviesProvider);
    final topRatedSeriesAsync = ref.watch(topRatedSeriesProvider);
    final airingTodayAsync = ref.watch(airingTodaySeriesProvider);
    final continueWatching =
        ref.read(watchHistoryProvider.notifier).continueWatching;
    final selectedGenre = ref.watch(selectedGenreProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(heroCarouselProvider);
          ref.invalidate(filteredMoviesProvider);
          ref.invalidate(filteredSeriesProvider);
          ref.invalidate(topRatedMoviesProvider);
          ref.invalidate(upcomingMoviesProvider);
          ref.invalidate(topRatedSeriesProvider);
          ref.invalidate(airingTodaySeriesProvider);
          ref.invalidate(trendingMoviesProvider);
          ref.invalidate(trendingSeriesProvider);
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Hero Carousel ────────────────────────────────────
              heroAsync.when(
                data: (items) => HomeHeroCarousel(items: items),
                loading: () => const HeroLoadingPlaceholder(),
                error: (e, s) => const SizedBox(height: 600),
              ),

              // ── 2. Continue Watching — personal content always first ─
              if (continueWatching.isNotEmpty) ...[
                const SizedBox(height: 36),
                _SectionHeader(
                  title: 'Continue Watching',
                  hugeIcon: HugeIcons.strokeRoundedPlayCircle,
                  iconColor: Colors.white70,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 195,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: continueWatching.length,
                    itemBuilder: (context, index) =>
                        _ContinueWatchingCard(entry: continueWatching[index]),
                  ),
                ),
              ],

              // ── 3. Discover Block ────────────────────────────────────
              // Genre chips live HERE — immediately above the two rows
              // they affect, making the relationship obvious to the user.
              const SizedBox(height: 40),

              // "Discover" header + fire icon for the Movies sub-row
              _DiscoverHeader(
                selectedGenre: selectedGenre,
                onSelectGenre: (id) =>
                    ref.read(selectedGenreProvider.notifier).select(id),
              ),

              // Movies sub-header
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedFire,
                      color: Colors.deepOrangeAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      selectedGenre == null
                          ? 'Trending Movies'
                          : '${tmdbGenres[selectedGenre]} Movies',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 195,
                child: moviesAsync.when(
                  data: (movies) =>
                      HorizontalMediaList(items: movies, defaultType: 'movie'),
                  loading: () => const HorizontalLoadingPlaceholder(),
                  error: (e, s) => _ErrorWidget(message: '$e'),
                ),
              ),

              // Genre-filtered Series row — smaller sub-header, same block
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedTv01,
                      color: Colors.blueAccent,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      selectedGenre == null
                          ? 'Trending Series'
                          : '${tmdbGenres[selectedGenre]} Series',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 195,
                child: seriesAsync.when(
                  data: (series) =>
                      HorizontalMediaList(items: series, defaultType: 'tv'),
                  loading: () => const HorizontalLoadingPlaceholder(),
                  error: (e, s) => _ErrorWidget(message: '$e'),
                ),
              ),

              // ── 4. Curated / Static Sections ────────────────────────
              // These never change with genre selection.

              // Top 10 Movies
              const SizedBox(height: 44),
              _SectionHeader(
                title: 'Top 10 Movies This Week',
                hugeIcon: HugeIcons.strokeRoundedMedalFirstPlace,
                iconColor: Colors.amber,
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 230,
                child: topRatedMoviesAsync.when(
                  data: (movies) =>
                      TopTenMediaList(items: movies, defaultType: 'movie'),
                  loading: () => const TopTenLoadingPlaceholder(),
                  error: (e, s) => _ErrorWidget(message: '$e'),
                ),
              ),

              // Coming Soon
              const SizedBox(height: 36),
              _SectionHeader(
                title: 'Coming Soon',
                hugeIcon: HugeIcons.strokeRoundedCalendar01,
                iconColor: Colors.purpleAccent,
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 160,
                child: upcomingMoviesAsync.when(
                  data: (movies) =>
                      BackdropMediaList(items: movies, defaultType: 'movie'),
                  loading: () => const BackdropLoadingPlaceholder(),
                  error: (e, s) => _ErrorWidget(message: '$e'),
                ),
              ),

              // Airing Today
              const SizedBox(height: 36),
              _SectionHeader(
                title: 'Airing Today',
                hugeIcon: HugeIcons.strokeRoundedLiveStreaming01,
                iconColor: Colors.greenAccent,
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 160,
                child: airingTodayAsync.when(
                  data: (series) =>
                      BackdropMediaList(items: series, defaultType: 'tv'),
                  loading: () => const BackdropLoadingPlaceholder(),
                  error: (e, s) => _ErrorWidget(message: '$e'),
                ),
              ),

              // Top 10 Series
              const SizedBox(height: 36),
              _SectionHeader(
                title: 'Top 10 Series This Week',
                hugeIcon: HugeIcons.strokeRoundedRanking,
                iconColor: Colors.amber,
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 230,
                child: topRatedSeriesAsync.when(
                  data: (series) =>
                      TopTenMediaList(items: series, defaultType: 'tv'),
                  loading: () => const TopTenLoadingPlaceholder(),
                  error: (e, s) => _ErrorWidget(message: '$e'),
                ),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Discover Header ────────────────────────────────────────────────────────
// Combines the "Discover" section title, fire icon for movies, and the
// scrollable genre chips all in one cohesive block.
class _DiscoverHeader extends StatelessWidget {
  final int? selectedGenre;
  final void Function(int?) onSelectGenre;

  const _DiscoverHeader({
    required this.selectedGenre,
    required this.onSelectGenre,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // "Discover" section title
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Discover',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Genre chips — the active filter control
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _GenreChip(
                label: 'All',
                isSelected: selectedGenre == null,
                onTap: () => onSelectGenre(null),
              ),
              ...tmdbGenres.entries.map((entry) => _GenreChip(
                    label: entry.value,
                    isSelected: selectedGenre == entry.key,
                    onTap: () => onSelectGenre(entry.key),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final List<List<dynamic>>? hugeIcon;
  final Color? iconColor;

  const _SectionHeader({required this.title, this.hugeIcon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          if (hugeIcon != null) ...[
            HugeIcon(
              icon: hugeIcon!,
              color: iconColor ?? Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error Widget ───────────────────────────────────────────────────────────
class _ErrorWidget extends StatelessWidget {
  final String message;
  const _ErrorWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Error: $message',
        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
      ),
    );
  }
}

// ── Continue Watching Card ─────────────────────────────────────────────────
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
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
                const Center(
                  child: Icon(
                    Icons.play_circle_filled,
                    color: Colors.white70,
                    size: 36,
                  ),
                ),
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

// ── Genre Chip ─────────────────────────────────────────────────────────────
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
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blueAccent
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.blueAccent
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white60,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

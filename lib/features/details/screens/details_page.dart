import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../providers/api_provider.dart';
import '../../../providers/bookmark_provider.dart';
import '../../../providers/watch_history_provider.dart';
import '../../../widgets/tmdb_image.dart';
import '../../home/widgets/horizontal_media_list.dart';
import '../widgets/video_player_view.dart';

class DetailsPage extends ConsumerStatefulWidget {
  final String type; // 'movie' or 'tv'
  final int id;

  const DetailsPage({super.key, required this.type, required this.id});

  @override
  ConsumerState<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends ConsumerState<DetailsPage> {
  int _selectedSeason = 1;

  @override
  Widget build(BuildContext context) {
    final detailsAsync = widget.type == 'movie'
        ? ref.watch(movieDetailsProvider(widget.id))
        : ref.watch(tvDetailsProvider(widget.id));

    final recommendationsAsync = widget.type == 'movie'
        ? ref.watch(movieRecommendationsProvider(widget.id))
        : ref.watch(tvRecommendationsProvider(widget.id));

    return Scaffold(
      backgroundColor: const Color(0xFF0F1014),
      body: detailsAsync.when(
        data: (details) {
          final String? backdrop = details['backdrop_path'];
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: false,
                backgroundColor: const Color(0xFF0F1014),
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  _BookmarkButton(
                    id: widget.id,
                    type: widget.type,
                    title: details['title'] ?? details['name'] ?? 'Unknown',
                    posterPath: details['poster_path'],
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Backdrop Image
                      if (backdrop != null)
                        TmdbImage(path: backdrop, highResSize: 'w1280')
                      else
                        Container(color: const Color(0xFF1A1C23)),

                      // Gradient to blend into background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF0F1014).withOpacity(0.5),
                              const Color(0xFF0F1014),
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                      ),

                      // Giant Play Button
                      Center(
                        child: IconButton(
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedPlayCircle,
                            size: 80,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            // If it's a TV show, default to S1E1
                            if (widget.type == 'tv') {
                              context.push(
                                '/player/${widget.type}/${widget.id}?season=1&episode=1',
                              );
                            } else {
                              context.push(
                                '/player/${widget.type}/${widget.id}',
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailsInfo(details),

                    const SizedBox(height: 32),

                    // Suggestions Section
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Suggestions',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: recommendationsAsync.when(
                        data: (recommendations) {
                          if (recommendations.isEmpty) {
                            return const Center(
                              child: Text(
                                'No suggestions available',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }
                          final List<dynamic> mappedRecs = recommendations.map((
                            item,
                          ) {
                            final Map<String, dynamic> itemMap =
                                Map<String, dynamic>.from(item);
                            if (!itemMap.containsKey('media_type'))
                              itemMap['media_type'] = widget.type;
                            return itemMap;
                          }).toList();

                          return HorizontalMediaList(items: mappedRecs);
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Center(child: Text('Error: $e')),
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
        error: (e, s) => Center(
          child: Text(
            'Error loading details',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsInfo(Map<String, dynamic> details) {
    final String title = details['title'] ?? details['name'] ?? 'Unknown';
    final String? tagline = details['tagline'];
    final String? overview = details['overview'];
    final double rating = (details['vote_average'] as num?)?.toDouble() ?? 0.0;
    final String? firstAirDate =
        details['first_air_date'] ?? details['release_date'];
    final List<dynamic> genres = details['genres'] ?? [];
    final List<dynamic> seasons = details['seasons'] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          if (tagline != null && tagline.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              tagline,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.blueAccent.shade100,
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Metadata Row
          Row(
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedStar,
                color: Colors.amber,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              if (firstAirDate != null)
                Text(
                  firstAirDate.split('-')[0],
                  style: const TextStyle(color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Genre Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: genres.map((genre) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  genre['name'],
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Overview
          if (overview != null && overview.isNotEmpty) ...[
            const Text(
              'Storyline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              overview,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
                height: 1.5,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Season and Episode Picker (for TV Shows)
          if (widget.type == 'tv' && seasons.isNotEmpty)
            _buildTvSelectors(seasons),
        ],
      ),
    );
  }

  Widget _buildTvSelectors(List<dynamic> seasons) {
    // Filter out specials (usually season 0)
    final validSeasons = seasons.where((s) => s['season_number'] > 0).toList();
    if (validSeasons.isEmpty) return const SizedBox.shrink();

    return Column(
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

        // Seasons Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedSeason,
              dropdownColor: const Color(0xFF1A1C23),
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              isExpanded: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: validSeasons.map((season) {
                return DropdownMenuItem<int>(
                  value: season['season_number'],
                  child: Text(
                    season['name'] ?? 'Season ${season['season_number']}',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedSeason = value;
                  });
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Episode List for Selected Season
        ref
            .watch(tvSeasonDetailsProvider((widget.id, _selectedSeason)))
            .when(
              data: (seasonData) {
                final episodes = seasonData['episodes'] as List<dynamic>? ?? [];
                if (episodes.isEmpty) {
                  return const Text(
                    'No episodes found.',
                    style: TextStyle(color: Colors.grey),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: episodes.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final episode = episodes[index];
                    final int epNumber = episode['episode_number'];
                    final String epName =
                        episode['name'] ?? 'Episode $epNumber';
                    final String? epStill = episode['still_path'];
                    final String? overview = episode['overview'];
                    final String? airDate = episode['air_date'];
                    final bool isWatched = ref
                        .read(watchHistoryProvider.notifier)
                        .isEpisodeFinished(
                            widget.id, _selectedSeason, epNumber);

                    return GestureDetector(
                      onTap: () {
                        context.push(
                          '/player/tv/${widget.id}?season=$_selectedSeason&episode=$epNumber',
                        );
                      },
                      child: Container(
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            14,
                          ), // slightly less to fit inside border
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Background Image
                              if (epStill != null)
                                TmdbImage(
                                  path: epStill,
                                  highResSize:
                                      'w780', // Get a high quality image
                                )
                              else
                                Container(
                                  color: const Color(0xFF1A1C23),
                                  child: const Icon(
                                    Icons.tv,
                                    color: Colors.grey,
                                    size: 48,
                                  ),
                                ),

                              // Gradient Overlay
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.6),
                                      Colors.black.withOpacity(0.95),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                ),
                              ),

                              // Watched dimming overlay
                              if (isWatched)
                                Container(
                                    color: Colors.black.withOpacity(0.35)),

                              // Watched badge (top-right)
                              if (isWatched)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.greenAccent.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check,
                                            color: Colors.black, size: 12),
                                        SizedBox(width: 4),
                                        Text(
                                          'Watched',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              Positioned(
                                bottom: 16,
                                left: 16,
                                right: 16,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$epNumber. $epName',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (episode['runtime'] != null) ...[
                                          const HugeIcon(
                                            icon:
                                                HugeIcons.strokeRoundedClock01,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${episode['runtime']} min',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        if (airDate != null) ...[
                                          const HugeIcon(
                                            icon: HugeIcons
                                                .strokeRoundedCalendar01,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            airDate,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (overview != null &&
                                        overview.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        overview,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.7),
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
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
              error: (e, s) =>
                  Center(child: Text('Error loading episodes: $e')),
            ),
      ],
    );
  }
}

class _BookmarkButton extends ConsumerWidget {
  final int id;
  final String type;
  final String title;
  final String? posterPath;

  const _BookmarkButton({
    required this.id,
    required this.type,
    required this.title,
    this.posterPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarkProvider);
    final isBookmarked = ref
        .read(bookmarkProvider.notifier)
        .isBookmarked(id, type);

    return IconButton(
      icon: HugeIcon(
        icon: isBookmarked
            ? HugeIcons.strokeRoundedBookmark02
            : HugeIcons.strokeRoundedBookmark01,
        color: isBookmarked ? Colors.blueAccent : Colors.white,
      ),
      onPressed: () {
        ref.read(bookmarkProvider.notifier).toggleBookmark(
              Bookmark(
                id: id,
                title: title,
                mediaType: type,
                posterPath: posterPath,
              ),
            );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBookmarked ? 'Removed from bookmarks' : 'Added to bookmarks',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF1A1C23),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../providers/api_provider.dart';
import '../../../providers/bookmark_provider.dart';
import '../../../providers/watch_history_provider.dart';
import '../../../widgets/tmdb_image.dart';
import '../../../widgets/skeleton_loader.dart';
import '../../home/widgets/horizontal_media_list.dart';
import '../widgets/video_player_view.dart';
import '../../../widgets/custom_toast.dart';

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
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.45,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFF0F1014),
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
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
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
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
                              Colors.transparent,
                              const Color(0xFF0F1014).withOpacity(0.8),
                              const Color(0xFF0F1014),
                            ],
                            stops: const [0.0, 0.4, 0.8, 1.0],
                          ),
                        ),
                      ),

                      // Giant Play Button
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
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
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
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

                    // Cast Section
                    _CastList(id: widget.id, type: widget.type),

                    const SizedBox(height: 32),

                    // Suggestions Section
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Suggestions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    recommendationsAsync.when(
                      data: (recommendations) {
                        if (recommendations.isEmpty) return const SizedBox.shrink();
                        final List<dynamic> mappedRecs = recommendations.map((item) {
                          final Map<String, dynamic> itemMap = Map<String, dynamic>.from(item);
                          if (!itemMap.containsKey('media_type')) itemMap['media_type'] = widget.type;
                          return itemMap;
                        }).toList();

                        return SizedBox(
                          height: 200,
                          child: HorizontalMediaList(items: mappedRecs),
                        );
                      },
                      loading: () => const SkeletonList(height: 200),
                      error: (e, s) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: SkeletonLoader(width: double.infinity, height: double.infinity),
        ),
        error: (e, s) => const Center(
          child: Text('Error loading details', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildDetailsInfo(Map<String, dynamic> details) {
    final String title = details['title'] ?? details['name'] ?? 'Unknown';
    final String? tagline = details['tagline'];
    final String? overview = details['overview'];
    final double rating = (details['vote_average'] as num?)?.toDouble() ?? 0.0;
    final String? date = details['first_air_date'] ?? details['release_date'];
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
              letterSpacing: -0.5,
            ),
          ),
          if (tagline != null && tagline.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              tagline,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Metadata Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (date != null)
                Text(
                  date.split('-')[0],
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                ),
              const SizedBox(width: 12),
              if (widget.type == 'movie' && details['runtime'] != null)
                Text(
                  '${details['runtime']} min',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Genre Tags
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: genres.map((genre) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Text(
                    genre['name'],
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                  ),
                );
              }).toList(),
            ),
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
                color: Colors.white.withOpacity(0.6),
                height: 1.6,
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
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedSeason,
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
                  setState(() => _selectedSeason = value);
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Episode List
        ref.watch(tvSeasonDetailsProvider((widget.id, _selectedSeason))).when(
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
                        .isEpisodeFinished(widget.id, _selectedSeason, epNumber);

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        context.push(
                          '/player/tv/${widget.id}?season=$_selectedSeason&episode=$epNumber',
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
    );
  }
}

class _CastList extends ConsumerWidget {
  final int id;
  final String type;

  const _CastList({required this.id, required this.type});

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
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          person['character'] ?? '',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
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
    final isBookmarked = ref.watch(bookmarkProvider.notifier).isBookmarked(id, type);

    return IconButton(
      icon: HugeIcon(
        icon: isBookmarked
            ? HugeIcons.strokeRoundedBookmark02
            : HugeIcons.strokeRoundedBookmark01,
        color: isBookmarked ? Colors.blueAccent : Colors.white,
      ),
      onPressed: () {
        final bookmark = Bookmark(
          id: id,
          title: title,
          mediaType: type,
          posterPath: posterPath,
        );

        ref.read(bookmarkProvider.notifier).toggleBookmark(bookmark);
        
        CustomToast.show(
          context: context,
          message: isBookmarked ? 'Removed $title' : 'Added $title to Bookmarks',
          icon: isBookmarked ? Icons.bookmark_remove : Icons.bookmark_add,
          posterPath: posterPath,
          onUndo: () {
            ref.read(bookmarkProvider.notifier).toggleBookmark(bookmark);
          },
        );
      },
    );
  }
}

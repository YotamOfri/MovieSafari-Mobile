import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/api_provider.dart';
import '../../../providers/watch_history_provider.dart';
import '../../../widgets/skeleton_loader.dart';
import '../../../widgets/tmdb_image.dart';
import '../../home/widgets/horizontal_media_list.dart';
import '../widgets/details_header.dart';
import '../widgets/details_info.dart';
import '../widgets/episode_selector.dart';
import '../widgets/cast_list.dart';

class DetailsPage extends ConsumerStatefulWidget {
  final String type; // 'movie' or 'tv'
  final int id;

  const DetailsPage({super.key, required this.type, required this.id});

  @override
  ConsumerState<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends ConsumerState<DetailsPage> {
  int _selectedSeason = 1;
  int? _lastWatchedEpisode;

  @override
  void initState() {
    super.initState();
    // Pre-select last watched season
    final history = ref.read(watchHistoryProvider);
    final entry = history.where((e) => e.id == widget.id && e.mediaType == widget.type).firstOrNull;
    if (entry != null && entry.lastSeason != null) {
      _selectedSeason = entry.lastSeason!;
      _lastWatchedEpisode = entry.lastEpisode;
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = widget.type == 'movie'
        ? ref.watch(movieDetailsProvider(widget.id))
        : ref.watch(tvDetailsProvider(widget.id));

    final recommendationsAsync = widget.type == 'movie'
        ? ref.watch(movieRecommendationsProvider(widget.id))
        : ref.watch(tvRecommendationsProvider(widget.id));

    return Scaffold(
      backgroundColor: Colors.black,
      body: detailsAsync.when(
        data: (details) {
          final List<dynamic> seasons = details['seasons'] ?? [];
          final String? backdrop = details['backdrop_path'];

          return Stack(
            children: [
              // 1. Dynamic Soft Backdrop
              if (backdrop != null)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: Image.network(
                      'https://image.tmdb.org/t/p/w45$backdrop',
                      fit: BoxFit.cover,
                      color: Colors.white.withValues(alpha: 0.4),
                      colorBlendMode: BlendMode.modulate,
                      cacheWidth: 20,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              
              // 2. Dark Overlay for Contrast
                // Cinematic Shadow Dissolve
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.5),
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.4, 0.6, 0.8, 0.95, 1.0],
                    ),
                  ),
                ),// 3. Main Content
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  DetailsHeader(
                    id: widget.id,
                    type: widget.type,
                    details: details,
                    continueSeason: _selectedSeason,
                    continueEpisode: _lastWatchedEpisode,
                  ),
                  
                  // 4. Smooth Transition Bridge
                  SliverToBoxAdapter(
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.black.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DetailsInfo(
                            details: details,
                            type: widget.type,
                          ),

                        if (widget.type == 'tv' && seasons.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          EpisodeSelector(
                            id: widget.id,
                            selectedSeason: _selectedSeason,
                            seasons: seasons,
                            onSeasonChanged: (season) {
                              setState(() => _selectedSeason = season);
                            },
                          ),
                        ],

                        const SizedBox(height: 32),
                        CastList(id: widget.id, type: widget.type),
                        const SizedBox(height: 32),

                        // Suggestions Section
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: Text(
                            'Suggestions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.2,
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
                ),
              ],
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
}

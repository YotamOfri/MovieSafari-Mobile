import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/api_provider.dart';
import '../../../widgets/skeleton_loader.dart';
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
          final List<dynamic> seasons = details['seasons'] ?? [];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              DetailsHeader(
                id: widget.id,
                type: widget.type,
                details: details,
              ),
              SliverToBoxAdapter(
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
}

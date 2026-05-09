import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../providers/api_provider.dart';
import '../../../providers/search_history_provider.dart';
import '../../../providers/watch_history_provider.dart';
import '../../../widgets/tmdb_image.dart';
import '../../../widgets/media_context_menu.dart';
import '../../../widgets/pressable_card.dart';
import '../../../widgets/skeleton_loader.dart';
import '../../home/widgets/horizontal_media_list.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _submitSearch(String value) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).addQuery(trimmed);
    }
    ref.read(searchQueryProvider.notifier).updateQuery(trimmed);
  }

  void _applyHistoryQuery(String query) {
    HapticFeedback.mediumImpact();
    _controller.text = query;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    _submitSearch(query);
  }

  void _clearSearch() {
    HapticFeedback.mediumImpact();
    _controller.clear();
    ref.read(searchQueryProvider.notifier).updateQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final searchHistory = ref.watch(searchHistoryProvider);
    final trendingAllAsync = ref.watch(trendingAllProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1014),
      body: Stack(
        children: [
          // 1. Dynamic Soft Backdrop
          trendingAllAsync.when(
            data: (items) {
              if (items.isEmpty) return const SizedBox.shrink();
              final String? backdrop = items.first['backdrop_path'];
              if (backdrop == null) return const SizedBox.shrink();

              return Positioned.fill(
                child: RepaintBoundary(
                  child: Image.network(
                    'https://image.tmdb.org/t/p/w92$backdrop',
                    fit: BoxFit.cover,
                    color: Colors.white.withValues(alpha: 0.3),
                    colorBlendMode: BlendMode.modulate,
                    cacheWidth: 100,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
          ),

          // 2. Cinematic Shadow Overlays
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0F1014).withValues(alpha: 0.4),
                    const Color(0xFF0F1014).withValues(alpha: 0.8),
                    const Color(0xFF0F1014),
                  ],
                  stops: const [0.0, 0.4, 0.8],
                ),
              ),
            ),
          ),

          // 3. Content
          SafeArea(
            bottom: false,
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Glassmorphic Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Movies, TV shows or genres...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontWeight: FontWeight.w500),
                        prefixIcon: const UnconstrainedBox(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedSearch01,
                            color: Colors.white60,
                            size: 20,
                          ),
                        ),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white60, size: 20),
                                onPressed: _clearSearch,
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onChanged: (value) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(const Duration(milliseconds: 600), () {
                          _submitSearch(value);
                        });
                      },
                      onSubmitted: _submitSearch,
                    ),
                  ),
                ),
              ),
            ),

            // Results / Empty State
            Expanded(
              child: searchQuery.trim().isEmpty
                  ? _buildEmptyState(searchHistory, trendingAllAsync)
                  : searchResultsAsync.when(
                      data: (results) {
                        if (results.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedSearch01,
                                  size: 48,
                                  color: Colors.white24,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No results for "$searchQuery"',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return _buildResultsGrid(results);
                      },
                      loading: () => const SkeletonGrid(),
                      error: (e, s) => Center(
                        child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    ],
  ),
);
}

  Widget _buildEmptyState(List<String> history, AsyncValue<List<dynamic>> trendingAll) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (history.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Searches',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(searchHistoryProvider.notifier).clearAll(),
                    child: Text(
                      'Clear all',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final query = history[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: GestureDetector(
                      onTap: () => _applyHistoryQuery(query),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.history_rounded, color: Colors.white.withValues(alpha: 0.4), size: 16),
                            const SizedBox(width: 8),
                            Text(
                              query,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
          ],

          // Categories Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Categories',
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
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryCard(
                  label: 'Action',
                  icon: HugeIcons.strokeRoundedSword01,
                  color: Colors.redAccent,
                  onTap: () => _applyHistoryQuery('Action'),
                ),
                _CategoryCard(
                  label: 'Comedy',
                  icon: HugeIcons.strokeRoundedChampion,
                  color: Colors.orangeAccent,
                  onTap: () => _applyHistoryQuery('Comedy'),
                ),
                _CategoryCard(
                  label: 'Horror',
                  icon: HugeIcons.strokeRoundedStar,
                  color: Colors.purpleAccent,
                  onTap: () => _applyHistoryQuery('Horror'),
                ),
                _CategoryCard(
                  label: 'Sci-Fi',
                  icon: HugeIcons.strokeRoundedUfo01,
                  color: Colors.blueAccent,
                  onTap: () => _applyHistoryQuery('Sci-Fi'),
                ),
                _CategoryCard(
                  label: 'Drama',
                  icon: HugeIcons.strokeRoundedRanking,
                  color: Colors.greenAccent,
                  onTap: () => _applyHistoryQuery('Drama'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // Trending Now Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(width: 0),
                Text(
                  'Trending Now',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          trendingAll.when(
            data: (items) => SizedBox(
              height: 195,
              child: HorizontalMediaList(items: items),
            ),
            loading: () => const SkeletonList(height: 195),
            error: (e, s) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 40),
          // Discover More (Popular Series)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(width: 0),
                Text(
                  'Popular Series',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ref.watch(trendingSeriesProvider).when(
            data: (items) => SizedBox(
              height: 195,
              child: HorizontalMediaList(items: items),
            ),
            loading: () => const SkeletonList(height: 195),
            error: (e, s) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 100), // Account for floating navbar
        ],
      ),
    );
  }

  Widget _buildResultsGrid(List<dynamic> results) {
    final history = ref.watch(watchHistoryProvider);

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        final String title = item['title'] ?? item['name'] ?? 'Unknown';
        final String? posterPath = item['poster_path'];
        final String mediaType = item['media_type'] ?? 'tv';
        final int id = item['id'];
        final displayType = mediaType == 'movie' ? 'Movie' : 'Series';
        final icon = mediaType == 'movie' ? HugeIcons.strokeRoundedPlayCircle : HugeIcons.strokeRoundedTv01;
        final Color accentColor = mediaType == 'movie' ? Colors.purpleAccent : Colors.blueAccent;

        final entry = history.cast<WatchedEntry?>().firstWhere((e) => e?.id == id && e?.mediaType == mediaType, orElse: () => null);
        final bool isFinished = entry?.isFinished ?? false;

        return PressableCard(
          onTap: () => context.push('/details/$mediaType/$id'),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            MediaContextMenu.show(context, ref, item, mediaType);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                TmdbImage(path: posterPath, highResSize: 'w500'),

                // Watched badge (Optimized)
                if (isFinished)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4), width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, color: Colors.greenAccent, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'WATCHED',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Content Overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                          Colors.black,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            HugeIcon(icon: icon, size: 14, color: accentColor),
                            const SizedBox(width: 6),
                            Text(
                              displayType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: accentColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final dynamic icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 110,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(icon: icon, color: color, size: 32),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
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

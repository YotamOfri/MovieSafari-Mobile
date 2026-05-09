import 'dart:async';
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

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Movies, TV shows or genres...',
                  hintStyle:
                      TextStyle(color: Colors.white.withOpacity(0.4)),
                  prefixIcon: const UnconstrainedBox(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: Colors.white60, size: 20),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16),
                ),
                onChanged: (value) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce =
                      Timer(const Duration(milliseconds: 600), () {
                    _submitSearch(value);
                  });
                },
                onSubmitted: _submitSearch,
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
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No results for "$searchQuery"',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return _buildResultsGrid(results);
                    },
                    loading: () => const SkeletonGrid(),
                    error: (e, s) =>
                        Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(List<String> history, AsyncValue<List<dynamic>> trendingAll) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (history.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Searches',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  TextButton(
                    onPressed: () =>
                        ref.read(searchHistoryProvider.notifier).clearAll(),
                    child: const Text('Clear all',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final query = history[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => _applyHistoryQuery(query),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.history,
                                color: Colors.grey, size: 14),
                            const SizedBox(width: 8),
                            Text(query,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],

          // Trending Now Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedFire,
                  color: Colors.deepOrangeAccent,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text('Trending Now',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
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
          
          const SizedBox(height: 32),
          // Discover More (Popular Series)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedTv01,
                  color: Colors.blueAccent,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text('Popular Series',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
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
        ],
      ),
    );
  }

  Widget _buildResultsGrid(List<dynamic> results) {
    final history = ref.watch(watchHistoryProvider);

    return GridView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2 / 3,
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
        final icon = mediaType == 'movie'
            ? HugeIcons.strokeRoundedPlayCircle
            : HugeIcons.strokeRoundedStar;
        final Color badgeColor =
            mediaType == 'movie' ? Colors.purpleAccent : Colors.blueAccent;

        final entry = history.cast<WatchedEntry?>().firstWhere(
            (e) => e?.id == id && e?.mediaType == mediaType,
            orElse: () => null);
        final bool isFinished = entry?.isFinished ?? false;

        return PressableCard(
          onTap: () => context.push('/details/$mediaType/$id'),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            MediaContextMenu.show(context, ref, item, mediaType);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                TmdbImage(path: posterPath, highResSize: 'w400'),

                // Watched badge (top-right)
                if (isFinished)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: Colors.black, size: 10),
                          SizedBox(width: 3),
                          Text('Watched',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              )),
                        ],
                      ),
                    ),
                  )
                else if (entry != null)
                  // In-progress blue dot
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),

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
                          Colors.black.withOpacity(0.7),
                          Colors.black,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            HugeIcon(icon: icon, size: 14, color: badgeColor),
                            const SizedBox(width: 4),
                            Text(displayType,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: badgeColor,
                                )),
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

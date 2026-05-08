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
    _controller.text = query;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    _submitSearch(query);
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).updateQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final searchHistory = ref.watch(searchHistoryProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search movies, tv shows...',
                  hintStyle:
                      TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: const UnconstrainedBox(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSearch01,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const UnconstrainedBox(
                            child: Icon(Icons.clear,
                                color: Colors.grey, size: 20),
                          ),
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
                      Timer(const Duration(milliseconds: 500), () {
                    _submitSearch(value);
                  });
                },
                onSubmitted: _submitSearch,
              ),
            ),

            const SizedBox(height: 20),

            // Results / Empty State
            Expanded(
              child: searchQuery.trim().isEmpty
                  ? _buildEmptyState(searchHistory)
                  : searchResultsAsync.when(
                      data: (results) {
                        if (results.isEmpty) {
                          return Center(
                            child: Text(
                              'No results found for "$searchQuery"',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          );
                        }
                        return _buildResultsGrid(results);
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: Colors.blueAccent),
                      ),
                      error: (e, s) =>
                          Center(child: Text('Error: $e')),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(List<String> history) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text('Find your favorite titles',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: history.map((query) {
            return GestureDetector(
              onTap: () => _applyHistoryQuery(query),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history,
                        color: Colors.grey, size: 15),
                    const SizedBox(width: 8),
                    Text(query,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => ref
                          .read(searchHistoryProvider.notifier)
                          .removeQuery(query),
                      child: const Icon(Icons.close,
                          color: Colors.grey, size: 14),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultsGrid(List<dynamic> results) {
    final historyNotifier = ref.watch(watchHistoryProvider.notifier);

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

        final entry = historyNotifier.getEntry(id, mediaType);
        final bool isFinished = entry?.isFinished ?? false;

        return PressableCard(
          onTap: () => context.push('/details/$mediaType/$id'),
          onLongPress: () {
            HapticFeedback.heavyImpact();
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

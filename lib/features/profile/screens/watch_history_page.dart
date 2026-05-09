import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../providers/watch_history_provider.dart';
import '../../../widgets/tmdb_image.dart';
import '../../../widgets/pressable_card.dart';

class WatchHistoryPage extends ConsumerStatefulWidget {
  const WatchHistoryPage({super.key});

  @override
  ConsumerState<WatchHistoryPage> createState() => _WatchHistoryPageState();
}

class _WatchHistoryPageState extends ConsumerState<WatchHistoryPage> {
  String _filter = 'All'; // 'All', 'Completed', 'Watching'

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(watchHistoryProvider);
    
    final filteredHistory = history.where((item) {
      if (_filter == 'Completed') return item.isFinished;
      if (_filter == 'Watching') return !item.isFinished;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F1014),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1014),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Watch History',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
        ),
        actions: [
          if (history.isNotEmpty)
            TextButton(
              onPressed: () => _showClearAllDialog(context, ref),
              child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _filter == 'All',
                  onTap: () => setState(() => _filter = 'All'),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: 'Completed',
                  isSelected: _filter == 'Completed',
                  onTap: () => setState(() => _filter = 'Completed'),
                ),
                const SizedBox(width: 10),
                _FilterChip(
                  label: 'In Progress',
                  isSelected: _filter == 'Watching',
                  onTap: () => setState(() => _filter = 'Watching'),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: filteredHistory.isEmpty
                ? _buildEmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.68,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 20,
                    ),
                    itemCount: filteredHistory.length,
                    itemBuilder: (context, index) {
                      final entry = filteredHistory[index];
                      return _buildHistoryCard(context, entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedPlay,
            size: 64,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            _filter == 'All' ? 'No history found' : 'No results for $_filter',
            style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Movies and shows you watch will appear here",
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, dynamic entry) {
    final subtitle = entry.mediaType == 'tv' ? 'S${entry.lastSeason} E${entry.lastEpisode}' : 'Movie';

    return PressableCard(
      onTap: () {
        if (entry.mediaType == 'tv') {
          context.push('/player/${entry.mediaType}/${entry.id}?season=${entry.lastSeason}&episode=${entry.lastEpisode}');
        } else {
          context.push('/player/${entry.mediaType}/${entry.id}');
        }
      },
      onLongPress: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  TmdbImage(
                    path: entry.posterPath,
                    highResSize: 'w400',
                  ),
                  if (entry.isFinished)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.black, size: 14),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            entry.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C23),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All History?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('This will remove all items from your watch history permanently.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              ref.read(watchHistoryProvider.notifier).clearAll();
              Navigator.pop(context);
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

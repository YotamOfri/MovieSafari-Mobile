import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../providers/watch_history_provider.dart';
import '../../../widgets/tmdb_image.dart';
import '../../../widgets/pressable_card.dart';
import '../../../widgets/media_context_menu.dart';
import '../../../widgets/discovery_button.dart';

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
                ? _buildEmptyState(context)
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1.0,
                    ),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: Colors.blueAccent.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No watch history',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Movies and series you watch will appear here so you can easily resume them.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            DiscoveryButton(
              label: 'Start Watching',
              icon: Icons.play_arrow_rounded,
              onTap: () => context.go('/'),
            ),
          ],
        ),
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
      onLongPress: () {
        MediaContextMenu.show(context, ref, entry.toJson(), entry.mediaType);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Image
            TmdbImage(
              path: entry.posterPath,
              highResSize: 'w400',
            ),
            
            // 2. Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black,
                    ],
                    stops: const [0.0, 0.4, 0.8, 1.0],
                  ),
                ),
              ),
            ),
            
            // 3. Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 0.5),
                    ),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 4. Completed Indicator
            if (entry.isFinished)
              Positioned(
                top: 12,
                right: 12,
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../providers/watch_history_provider.dart';
import '../../../providers/bookmark_provider.dart';
import '../../../providers/search_history_provider.dart';
import '../../../widgets/pressable_card.dart';
import '../../../widgets/tmdb_image.dart';
import '../../../widgets/media_context_menu.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(watchHistoryProvider);
    final bookmarks = ref.watch(bookmarkProvider);
    final searchHistory = ref.watch(searchHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1014),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // Header
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.blueAccent, Colors.purpleAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Guest User',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Text('${history.length} watched · ${bookmarks.length} bookmarks',
                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Stats Row
              Row(
                children: [
                  _StatCard(label: 'Watched', value: '${history.length}',
                      icon: Icons.play_circle_outline, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  _StatCard(label: 'Bookmarks', value: '${bookmarks.length}',
                      icon: Icons.bookmark_border, color: Colors.purpleAccent),
                  const SizedBox(width: 12),
                  _StatCard(label: 'Finished', value: '${history.where((e) => e.isFinished).length}',
                      icon: Icons.check_circle_outline, color: Colors.greenAccent),
                ],
              ),

              const SizedBox(height: 32),

              // Watch History Section
              _SectionHeader(
                title: 'Watch History',
                onClear: history.isEmpty ? null : () {
                  // Clear all history
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1C23),
                      title: const Text('Clear History',
                          style: TextStyle(color: Colors.white)),
                      content: const Text('Remove all watch history?',
                          style: TextStyle(color: Colors.grey)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel',
                              style: TextStyle(color: Colors.grey)),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(watchHistoryProvider.notifier).clearAll();
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('Clear',
                              style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text('Nothing watched yet',
                      style: TextStyle(color: Colors.grey)),
                )
              else
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final entry = history[index];
                      final subtitle = entry.mediaType == 'tv' &&
                              entry.lastSeason != null
                          ? 'S${entry.lastSeason}E${entry.lastEpisode}'
                          : 'Movie';

                      return PressableCard(
                        onTap: () {
                          if (entry.mediaType == 'tv') {
                            context.push(
                                '/player/${entry.mediaType}/${entry.id}?season=${entry.lastSeason}&episode=${entry.lastEpisode}');
                          } else {
                            context
                                .push('/player/${entry.mediaType}/${entry.id}');
                          }
                        },
                        onLongPress: () {
                          HapticFeedback.heavyImpact();
                          MediaContextMenu.show(
                            context,
                            ref,
                            entry.toJson(),
                            entry.mediaType,
                          );
                        },
                        child: Container(
                          width: 110,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      TmdbImage(
                                          path: entry.posterPath,
                                          highResSize: 'w200'),
                                      if (entry.isFinished)
                                        Container(
                                          color: Colors.black.withOpacity(0.3),
                                          alignment: Alignment.topRight,
                                          padding: const EdgeInsets.all(6),
                                          child: const Icon(Icons.check_circle,
                                              color: Colors.greenAccent,
                                              size: 16),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(entry.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                              Text(subtitle,
                                  style: const TextStyle(
                                      color: Colors.blueAccent, fontSize: 10)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 28),

              // Settings Section
              _SectionHeader(title: 'Settings'),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.history,
                label: 'Clear Search History',
                subtitle: '${searchHistory.length} saved queries',
                onTap: () {
                  ref.read(searchHistoryProvider.notifier).clearAll();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Search history cleared'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: Icons.bookmark_remove_outlined,
                label: 'Clear Bookmarks',
                subtitle: '${bookmarks.length} items saved',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1C23),
                      title: const Text('Clear Bookmarks',
                          style: TextStyle(color: Colors.white)),
                      content: const Text('Remove all bookmarks?',
                          style: TextStyle(color: Colors.grey)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel',
                              style: TextStyle(color: Colors.grey)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            // Note: bulk clear is not implemented in bookmark provider
                            // For now, show a message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Remove bookmarks individually from the Bookmarks page'),
                                  behavior: SnackBarBehavior.floating),
                            );
                          },
                          child: const Text('OK',
                              style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onClear;

  const _SectionHeader({required this.title, this.onClear});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        if (onClear != null)
          TextButton(
            onPressed: onClear,
            child: const Text('Clear',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
      title: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing:
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}

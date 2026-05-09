import 'dart:ui';
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
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F1014),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium App Bar with Profile Info
          SliverAppBar(
            expandedHeight: 280,
            collapsedHeight: 80,
            pinned: false,
            stretch: true,
            backgroundColor: const Color(0xFF0F1014),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cinematic Poster Banner Background
                  Image.asset(
                    'assets/PosterBanner.png',
                    fit: BoxFit.cover,
                  ),
                  // Blur + Darkening Overlay
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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
                        ),
                      ),
                    ),
                  ),
                  
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar with Glow
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundColor: Color(0xFF1A1C23),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedUserCircle,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Movie Explorer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'PREMIUM MEMBER',
                          style: TextStyle(
                            color: Colors.blueAccent.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  
                  // Statistics Grid
                  Row(
                    children: [
                      _CompactStatTile(
                        label: 'Watched',
                        value: history.length.toString(),
                        icon: HugeIcons.strokeRoundedPlay,
                        color: Colors.blueAccent,
                      ),
                      const SizedBox(width: 16),
                      _CompactStatTile(
                        label: 'Bookmarks',
                        value: bookmarks.length.toString(),
                        icon: HugeIcons.strokeRoundedBookmark01,
                        color: Colors.purpleAccent,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Watch History Section
                  _ModernSectionHeader(
                    title: 'Recently Watched',
                    trailing: history.isNotEmpty ? 'View All' : null,
                    onTrailingTap: () => context.push('/history'),
                  ),
                  const SizedBox(height: 16),
                  _buildHistoryList(history, context, ref),
                  
                  const SizedBox(height: 32),
                  
                  // Quick Actions
                  const _ModernSectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 16),
                  _ActionTile(
                    icon: HugeIcons.strokeRoundedSettings01,
                    title: 'App Settings',
                    subtitle: 'Player preferences, theme & quality',
                    onTap: () {},
                  ),
                  _ActionTile(
                    icon: HugeIcons.strokeRoundedDelete02,
                    title: 'Clear Cache',
                    subtitle: 'Free up local storage space',
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Cache cleared successfully'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.blueAccent.withValues(alpha: 0.9),
                        ),
                      );
                    },
                  ),
                  _ActionTile(
                    icon: HugeIcons.strokeRoundedHelpCircle,
                    title: 'Help & Support',
                    subtitle: 'FAQs and contact us',
                    onTap: () {},
                  ),
                  _ActionTile(
                    icon: HugeIcons.strokeRoundedLogout01,
                    title: 'Sign Out',
                    isDestructive: true,
                    onTap: () {},
                  ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<dynamic> history, BuildContext context, WidgetRef ref) {
    if (history.isEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedPlay,
              color: Colors.white.withValues(alpha: 0.1),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'No history yet',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: history.length,
        clipBehavior: Clip.none,
        itemBuilder: (context, index) {
          final entry = history[index];
          final subtitle = entry.mediaType == 'tv' 
              ? 'S${entry.lastSeason} E${entry.lastEpisode}' 
              : 'Movie';

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: PressableCard(
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
              child: SizedBox(
                width: 140,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Background Image
                      TmdbImage(path: entry.posterPath, highResSize: 'w400'),
                      
                      // 2. Gradient Overlay for text readability
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.1),
                                Colors.black.withValues(alpha: 0.8),
                                Colors.black,
                              ],
                              stops: const [0.0, 0.4, 0.8, 1.0],
                            ),
                          ),
                        ),
                      ),
                      
                      // 3. Content Overlaid
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
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 0.5),
                              ),
                              child: Text(
                                subtitle,
                                style: const TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 4. Completed Indicator (if applicable)
                      if (entry.isFinished)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.check, color: Colors.black, size: 10),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CompactStatTile extends StatelessWidget {
  final String label;
  final String value;
  final dynamic icon;
  final Color color;

  const _CompactStatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: HugeIcon(icon: icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  label,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernSectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingTap;

  const _ModernSectionHeader({required this.title, this.trailing, this.onTrailingTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
        ),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(
              trailing!,
              style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressableCard(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isDestructive ? Colors.redAccent : Colors.blueAccent).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HugeIcon(
                  icon: icon,
                  color: isDestructive ? Colors.redAccent : Colors.white70,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDestructive ? Colors.redAccent : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.2), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

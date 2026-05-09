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
          // Premium Glassmorphic Header
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
                  // Cinematic Backdrop
                  Image.asset(
                    'assets/PosterBanner.png',
                    fit: BoxFit.cover,
                  ),
                  // Deep Glass Blur Overlay
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF0F1014).withValues(alpha: 0.3),
                              const Color(0xFF0F1014).withValues(alpha: 0.7),
                              const Color(0xFF0F1014),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Avatar with Halo Glow
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withValues(alpha: 0.2),
                              blurRadius: 40,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              child: const HugeIcon(
                                icon: HugeIcons.strokeRoundedUserCircle,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Movie Explorer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2), width: 1),
                            ),
                            child: const Text(
                              'PREMIUM MEMBER',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
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
                  
                  // Glassmorphic Statistics
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
                  
                  const SizedBox(height: 40),
                  
                  // Watch History Section
                  _ModernSectionHeader(
                    title: 'Recently Watched',
                    trailing: history.isNotEmpty ? 'View All' : null,
                    onTrailingTap: () => context.push('/history'),
                  ),
                  const SizedBox(height: 20),
                  _buildHistoryList(history, context, ref),
                  
                  const SizedBox(height: 40),
                  
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
                  
                  const SizedBox(height: 120),
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
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
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
                const SizedBox(height: 12),
                Text(
                  'No history yet',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: history.length,
        clipBehavior: Clip.none,
        itemBuilder: (context, index) {
          final entry = history[index];
          final String subtitle = entry.mediaType == 'tv' 
              ? 'S${entry.lastSeason} E${entry.lastEpisode}' 
              : 'MOVIE';

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
                width: 145,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Background Image
                      TmdbImage(path: entry.posterPath, highResSize: 'w400'),
                      
                      // 2. Modern Multi-stage Gradient
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
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 0.8),
                                  ),
                                  child: Text(
                                    subtitle,
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // 4. Watched Pill (Glassmorphic)
                      if (entry.isFinished)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4), width: 1),
                                ),
                                child: const Icon(Icons.check_rounded, color: Colors.greenAccent, size: 10),
                              ),
                            ),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
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
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(
              trailing!.toUpperCase(),
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isDestructive ? Colors.redAccent : Colors.white).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (isDestructive ? Colors.redAccent : Colors.white).withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: HugeIcon(
                      icon: icon,
                      color: isDestructive ? Colors.redAccent : Colors.white,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.2), size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

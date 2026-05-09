import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/server_constants.dart';
import '../../../providers/api_provider.dart';
import '../../../providers/watch_history_provider.dart';
import '../../../widgets/tmdb_image.dart';
import '../../../widgets/mini_toast.dart';
import '../widgets/player_about_section.dart';
import '../widgets/player_episodes_list.dart';
import '../widgets/player_servers_list.dart';
import '../widgets/video_player_view.dart';

class PlayerPage extends ConsumerStatefulWidget {
  final String type;
  final int id;
  final int season;
  final int episode;

  const PlayerPage({
    super.key,
    required this.type,
    required this.id,
    this.season = 1,
    this.episode = 1,
  });

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  int _selectedServerIndex = 0;
  late final ScrollController _episodesScrollController;

  int? _prevSeason;
  int? _prevEpisode;

  Timer? _finishTimer;
  bool _autoFinished = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _prevSeason = widget.season;
    _prevEpisode = widget.episode;

    final double initialOffset = (widget.episode - 1) * 256.0;
    _episodesScrollController = ScrollController(
      initialScrollOffset: initialOffset,
    );
  }

  @override
  void didUpdateWidget(PlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.episode != widget.episode ||
        oldWidget.season != widget.season) {
      _prevSeason = oldWidget.season;
      _prevEpisode = oldWidget.episode;

      if (_episodesScrollController.hasClients) {
        _episodesScrollController.animateTo(
          (widget.episode - 1) * 256.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }

      _finishTimer?.cancel();
      _autoFinished = false;
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _finishTimer?.cancel();
    _episodesScrollController.dispose();
    super.dispose();
  }

  void _onPlayPressed(Map<String, dynamic> details) {
    final title = details['title'] ?? details['name'] ?? 'Unknown';
    final posterPath = details['poster_path'] as String?;

    ref
        .read(watchHistoryProvider.notifier)
        .markStarted(
          id: widget.id,
          mediaType: widget.type,
          title: title,
          posterPath: posterPath,
          season: widget.season,
          episode: widget.episode,
          prevSeason: _prevSeason,
          prevEpisode: _prevEpisode,
        );

    _startFinishTimer(details);
  }

  void _startFinishTimer(Map<String, dynamic> details) {
    _finishTimer?.cancel();
    _autoFinished = false;

    int? runtimeMinutes;
    if (widget.type == 'movie') {
      runtimeMinutes = details['runtime'] as int?;
    }
    runtimeMinutes ??= (widget.type == 'tv' ? 20 : null);

    if (runtimeMinutes == null || runtimeMinutes <= 0) return;

    final threshold = Duration(minutes: (runtimeMinutes * 0.75).round());

    _finishTimer = Timer(threshold, () {
      if (mounted && !_autoFinished) {
        _autoFinished = true;
        ref
            .read(watchHistoryProvider.notifier)
            .markFinished(
              id: widget.id,
              mediaType: widget.type,
              season: widget.season,
              episode: widget.episode,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final servers = widget.type == 'tv'
        ? ServerConstants.getTvServers(widget.id, widget.season, widget.episode)
        : ServerConstants.getMovieServers(widget.id);
    final currentServerUrl = servers[_selectedServerIndex];

    final detailsAsync = widget.type == 'movie'
        ? ref.watch(movieDetailsProvider(widget.id))
        : ref.watch(tvDetailsProvider(widget.id));

    final historyEntry = ref.watch(watchHistoryProvider).where(
      (e) => e.id == widget.id && e.mediaType == widget.type,
    ).firstOrNull;

    final isCurrentFinished = widget.type == 'movie'
        ? (historyEntry?.isFinished ?? false)
        : (historyEntry?.isEpisodeFinished(widget.season, widget.episode) ??
              false);

    return Scaffold(
      backgroundColor: Colors.black,
      body: detailsAsync.when(
        data: (details) {
          final String? backdrop = details['backdrop_path'];

          return Stack(
            children: [
              if (backdrop != null)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.3,
                    child: TmdbImage(
                      path: backdrop,
                      highResSize: 'w780',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              // Cinematic Gradient Overlay (Instead of heavy blur)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black.withValues(alpha: 0.4),
                        Colors.black.withValues(alpha: 0.8),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),

              SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PlayerTopBar(
                      title: widget.type == 'tv'
                          ? '${details['name'] ?? 'Playing'} · S${widget.season}E${widget.episode}'
                          : details['title'] ?? 'Playing',
                    ),

                    VideoPlayerView(
                      serverUrl: currentServerUrl,
                      thumbnailPath:
                          details['backdrop_path'] as String? ??
                          details['poster_path'] as String?,
                      onPlayPressed: () => _onPlayPressed(details),
                      allServers: servers,
                      currentServerIndex: _selectedServerIndex,
                      onServerSwitch: (index) {
                        setState(() => _selectedServerIndex = index);
                      },
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),

                            _PlayerControlsRow(
                              isFinished: isCurrentFinished,
                              type: widget.type,
                              details: details,
                              episode: widget.episode,
                              season: widget.season,
                              id: widget.id,
                            ),

                            const SizedBox(height: 24),

                            PlayerServersList(
                              servers: servers,
                              selectedIndex: _selectedServerIndex,
                              onSelected: (index) {
                                setState(() => _selectedServerIndex = index);
                              },
                            ),

                            const SizedBox(height: 32),

                            if (widget.type == 'tv') ...[
                              PlayerEpisodesList(
                                id: widget.id,
                                season: widget.season,
                                currentEpisode: widget.episode,
                                scrollController: _episodesScrollController,
                              ),
                              const SizedBox(height: 32),
                            ],

                            PlayerAboutSection(details: details),
                            const SizedBox(height: 48),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
        error: (e, s) => Center(
          child: Text(
            'Error loading player',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }
}

class _PlayerTopBar extends StatelessWidget {
  final String title;

  const _PlayerTopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _GlassButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerControlsRow extends ConsumerWidget {
  final bool isFinished;
  final String type;
  final Map<String, dynamic> details;
  final int episode;
  final int season;
  final int id;

  const _PlayerControlsRow({
    required this.isFinished,
    required this.type,
    required this.details,
    required this.episode,
    required this.season,
    required this.id,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasons = details['seasons'] as List<dynamic>? ?? [];
    final currentSeasonData = seasons.firstWhere(
      (s) => s['season_number'] == season,
      orElse: () => null,
    );
    final totalEpisodes = currentSeasonData?['episode_count'] as int? ?? 0;
    final bool hasNextInSeason = episode < totalEpisodes;
    
    final int currentIndex = seasons.indexWhere((s) => s['season_number'] == season);
    Map<String, dynamic>? nextSeasonData;
    if (currentIndex != -1) {
      for (int i = currentIndex + 1; i < seasons.length; i++) {
        if ((seasons[i]['episode_count'] ?? 0) > 0) {
          nextSeasonData = seasons[i];
          break;
        }
      }
    }
    
    final bool hasNextSeason = nextSeasonData != null;
    final bool shouldShowNext = type == 'tv' && (hasNextInSeason || hasNextSeason);
    
    final int? nextS = (hasNextInSeason || hasNextSeason) 
        ? (hasNextInSeason ? season : (nextSeasonData?['season_number'] as int?))
        : null;
    final int? nextE = (hasNextInSeason || hasNextSeason)
        ? (hasNextInSeason ? episode + 1 : 1)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (shouldShowNext) ...[
            Expanded(
              child: _GlassActionChip(
                icon: isFinished
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                label: isFinished ? 'Watched' : 'Mark Watched',
                color: isFinished ? Colors.greenAccent : Colors.white,
                onTap: () {
                  ref.read(watchHistoryProvider.notifier).toggleFinished(
                    id: id,
                    mediaType: type,
                    season: season,
                    episode: episode,
                  );
                  
                  if (!isFinished && nextS != null && nextE != null) {
                    ref.read(watchHistoryProvider.notifier).markFinished(
                      id: id,
                      mediaType: type,
                      season: season,
                      episode: episode,
                      nextSeason: nextS,
                      nextEpisode: nextE,
                    );
                  }
                  
                  final isNowWatched = !isFinished;
                  MiniToast.show(
                    context: context,
                    message: isNowWatched 
                        ? (type == 'tv' ? 'Episode marked as watched' : 'Movie marked as watched')
                        : (type == 'tv' ? 'Episode unmarked' : 'Movie unmarked'),
                    icon: isNowWatched ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
                    color: isNowWatched ? Colors.greenAccent : Colors.white70,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            _NextEpisodeButton(
              details: details,
              currentSeason: season,
              currentEpisode: episode,
              id: id,
              isExpanded: true,
            ),
          ] else ...[
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: _GlassActionChip(
                icon: isFinished
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                label: isFinished ? 'Watched' : 'Mark Watched',
                color: isFinished ? Colors.greenAccent : Colors.white,
                onTap: () {
                  ref.read(watchHistoryProvider.notifier).toggleFinished(
                    id: id,
                    mediaType: type,
                    season: season,
                    episode: episode,
                  );
                  
                  final isNowWatched = !isFinished;
                  MiniToast.show(
                    context: context,
                    message: isNowWatched 
                        ? (type == 'tv' ? 'Episode marked as watched' : 'Movie marked as watched')
                        : (type == 'tv' ? 'Episode unmarked' : 'Movie unmarked'),
                    icon: isNowWatched ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
                    color: isNowWatched ? Colors.greenAccent : Colors.white70,
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _GlassActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _GlassActionChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextEpisodeButton extends ConsumerWidget {
  final Map<String, dynamic> details;
  final int currentSeason;
  final int currentEpisode;
  final int id;
  final bool isExpanded;

  const _NextEpisodeButton({
    required this.details,
    required this.currentSeason,
    required this.currentEpisode,
    required this.id,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasons = details['seasons'] as List<dynamic>? ?? [];
    final currentSeasonData = seasons.firstWhere(
      (s) => s['season_number'] == currentSeason,
      orElse: () => null,
    );
    final totalEpisodes = currentSeasonData?['episode_count'] as int? ?? 0;
    final bool hasNextInSeason = currentEpisode < totalEpisodes;

    final int currentIndex = seasons.indexWhere(
      (s) => s['season_number'] == currentSeason,
    );

    Map<String, dynamic>? nextSeasonData;
    if (currentIndex != -1) {
      for (int i = currentIndex + 1; i < seasons.length; i++) {
        final s = seasons[i];
        if ((s['episode_count'] ?? 0) > 0) {
          nextSeasonData = s;
          break;
        }
      }
    }

    final bool hasNextSeason = nextSeasonData != null;
    if (!hasNextInSeason && !hasNextSeason) return const SizedBox();
    final bool isNextSeason = !hasNextInSeason && hasNextSeason;
    final String label = isNextSeason ? 'Next Season' : 'Next Episode';
    final int targetSeason = isNextSeason
        ? (nextSeasonData?['season_number'] ?? currentSeason + 1)
        : currentSeason;
    final int targetEpisode = isNextSeason ? 1 : currentEpisode + 1;

    void navigateToNext() {
      ref.read(watchHistoryProvider.notifier).markFinished(
        id: id,
        mediaType: 'tv',
        season: currentSeason,
        episode: currentEpisode,
        nextSeason: targetSeason,
        nextEpisode: targetEpisode,
      );

      context.pushReplacement(
        '/player/tv/$id?season=$targetSeason&episode=$targetEpisode',
      );
    }

    if (isExpanded) {
      return Expanded(
        child: Material(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: navigateToNext,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isNextSeason
                        ? Icons.keyboard_double_arrow_right_rounded
                        : Icons.skip_next_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return _GlassButton(
      icon: isNextSeason
          ? Icons.keyboard_double_arrow_right_rounded
          : Icons.skip_next_rounded,
      onTap: navigateToNext,
    );
  }
}

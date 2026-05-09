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
    
    final double initialOffset = (widget.episode - 1) * 232.0;
    _episodesScrollController =
        ScrollController(initialScrollOffset: initialOffset);
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
          (widget.episode - 1) * 232.0,
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

    ref.read(watchHistoryProvider.notifier).markStarted(
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
        ref.read(watchHistoryProvider.notifier).markFinished(
              id: widget.id,
              mediaType: widget.type,
              season: widget.season,
              episode: widget.episode,
            );
      }
    });
  }

  void _manualMarkFinished() {
    _finishTimer?.cancel();
    _autoFinished = true;
    ref.read(watchHistoryProvider.notifier).markFinished(
          id: widget.id,
          mediaType: widget.type,
          season: widget.season,
          episode: widget.episode,
        );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final servers = widget.type == 'tv'
        ? ServerConstants.getTvServers(
            widget.id, widget.season, widget.episode)
        : ServerConstants.getMovieServers(widget.id);
    final currentServerUrl = servers[_selectedServerIndex];

    final detailsAsync = widget.type == 'movie'
        ? ref.watch(movieDetailsProvider(widget.id))
        : ref.watch(tvDetailsProvider(widget.id));

    final historyEntry = ref
        .watch(watchHistoryProvider.notifier)
        .getEntry(widget.id, widget.type);

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
              // 1. Immersive Blurred Backdrop
              if (backdrop != null)
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                    child: Opacity(
                      opacity: 0.4,
                      child: TmdbImage(
                        path: backdrop,
                        highResSize: 'w780',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              
              // 2. Cinematic Shadow Dissolve (Matched to Details Page)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.6),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.4, 0.6, 0.8, 0.95, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. Main Content
              SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Glassmorphic Top Bar
                    _PlayerTopBar(
                      title: widget.type == 'tv'
                          ? '${details['name'] ?? 'Playing'} · S${widget.season}E${widget.episode}'
                          : details['title'] ?? 'Playing',
                      isFinished: isCurrentFinished,
                      type: widget.type,
                      details: details,
                      episode: widget.episode,
                      season: widget.season,
                      id: widget.id,
                      onMarkFinished: _manualMarkFinished,
                    ),

                    // Video Player
                    VideoPlayerView(
                      serverUrl: currentServerUrl,
                      thumbnailPath: details['backdrop_path'] as String? ??
                          details['poster_path'] as String?,
                      onPlayPressed: () => _onPlayPressed(details),
                      allServers: servers,
                      currentServerIndex: _selectedServerIndex,
                      onServerSwitch: (index) {
                        setState(() => _selectedServerIndex = index);
                      },
                    ),

                    // Content Below Player
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),

                            // Servers Section
                            PlayerServersList(
                              servers: servers,
                              selectedIndex: _selectedServerIndex,
                              onSelected: (index) {
                                setState(() => _selectedServerIndex = index);
                              },
                            ),

                            const SizedBox(height: 32),

                            // TV Episodes
                            if (widget.type == 'tv') ...[
                              PlayerEpisodesList(
                                id: widget.id,
                                season: widget.season,
                                currentEpisode: widget.episode,
                                scrollController: _episodesScrollController,
                              ),
                              const SizedBox(height: 32),
                            ],

                            // About Section
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
          child: Text('Error loading player', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
        ),
      ),
    );
  }
}

class _PlayerTopBar extends StatelessWidget {
  final String title;
  final bool isFinished;
  final String type;
  final Map<String, dynamic> details;
  final int episode;
  final int season;
  final int id;
  final VoidCallback onMarkFinished;

  const _PlayerTopBar({
    required this.title,
    required this.isFinished,
    required this.type,
    required this.details,
    required this.episode,
    required this.season,
    required this.id,
    required this.onMarkFinished,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Glass Back Button
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
          
          const SizedBox(width: 8),
          
          // Mark Done Button
          _GlassActionChip(
            icon: isFinished ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
            label: isFinished ? 'Watched' : 'Mark Done',
            color: isFinished ? Colors.greenAccent : Colors.white,
            onTap: isFinished ? null : onMarkFinished,
          ),

          if (type == 'tv') ...[
            const SizedBox(width: 8),
            _NextEpisodeButton(
              details: details,
              currentSeason: season,
              currentEpisode: episode,
              id: id,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withValues(alpha: 0.08),
          child: InkWell(
            onTap: onTap,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withValues(alpha: 0.08),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
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
        ),
      ),
    );
  }
}

class _NextEpisodeButton extends StatelessWidget {
  final Map<String, dynamic> details;
  final int currentSeason;
  final int currentEpisode;
  final int id;

  const _NextEpisodeButton({
    required this.details,
    required this.currentSeason,
    required this.currentEpisode,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    final seasons = details['seasons'] as List<dynamic>? ?? [];
    final currentSeasonData = seasons.firstWhere(
      (s) => s['season_number'] == currentSeason,
      orElse: () => null,
    );
    final totalEpisodes = currentSeasonData?['episode_count'] as int? ?? 0;
    final hasNext = currentEpisode < totalEpisodes;

    if (!hasNext) return const SizedBox();

    return _GlassButton(
      icon: Icons.skip_next_rounded,
      onTap: () {
        context.pushReplacement(
          '/player/tv/$id?season=$currentSeason&episode=${currentEpisode + 1}',
        );
      },
    );
  }
}

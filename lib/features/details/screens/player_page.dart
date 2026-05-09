import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/server_constants.dart';
import '../../../providers/api_provider.dart';
import '../../../providers/watch_history_provider.dart';
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

  // Track the episode that was playing BEFORE the user switches
  int? _prevSeason;
  int? _prevEpisode;

  // 75% auto-finish timer
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
      // Store previous episode before updating
      _prevSeason = oldWidget.season;
      _prevEpisode = oldWidget.episode;

      if (_episodesScrollController.hasClients) {
        _episodesScrollController.animateTo(
          (widget.episode - 1) * 232.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }

      // Reset auto-finish state for new episode
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

  // Called when the user taps the play gate button
  void _onPlayPressed(Map<String, dynamic> details) {
    final title = details['title'] ?? details['name'] ?? 'Unknown';
    final posterPath = details['poster_path'] as String?;

    // Save to watch history
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

    // Start 75% timer using runtime from API
    _startFinishTimer(details);
  }

  void _startFinishTimer(Map<String, dynamic> details) {
    _finishTimer?.cancel();
    _autoFinished = false;

    int? runtimeMinutes;
    if (widget.type == 'movie') {
      runtimeMinutes = details['runtime'] as int?;
    }
    // For TV, runtime comes from episode data — handled in PlayerEpisodesList
    // Fall back to 20 mins for TV if no episode runtime available
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Marked as finished ✓',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1C23),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
      backgroundColor: const Color(0xFF0F1014),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                ),
                Expanded(
                  child: detailsAsync.when(
                    data: (details) => Text(
                      widget.type == 'tv'
                          ? '${details['name'] ?? 'Playing'} · S${widget.season}E${widget.episode}'
                          : details['title'] ?? 'Playing',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ),
                // Mark as Finished button
                detailsAsync.maybeWhen(
                  data: (details) => TextButton.icon(
                    onPressed: isCurrentFinished ? null : _manualMarkFinished,
                    icon: Icon(
                      isCurrentFinished
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: isCurrentFinished
                          ? Colors.greenAccent
                          : Colors.white54,
                      size: 18,
                    ),
                    label: Text(
                      isCurrentFinished ? 'Watched' : 'Mark Done',
                      style: TextStyle(
                        color: isCurrentFinished
                            ? Colors.greenAccent
                            : Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  orElse: () => const SizedBox(),
                ),
                // Next Episode button (TV only)
                if (widget.type == 'tv')
                  detailsAsync.maybeWhen(
                    data: (details) {
                      final seasons = details['seasons'] as List<dynamic>? ?? [];
                      final currentSeasonData = seasons.firstWhere(
                        (s) => s['season_number'] == widget.season,
                        orElse: () => null,
                      );
                      final totalEpisodes =
                          currentSeasonData?['episode_count'] as int? ?? 0;
                      final hasNext = widget.episode < totalEpisodes;
                      if (!hasNext) return const SizedBox();
                      return IconButton(
                        tooltip: 'Next Episode',
                        icon: const Icon(Icons.skip_next_rounded,
                            color: Colors.white, size: 26),
                        onPressed: () {
                          context.pushReplacement(
                            '/player/tv/${widget.id}?season=${widget.season}&episode=${widget.episode + 1}',
                          );
                        },
                      );
                    },
                    orElse: () => const SizedBox(),
                  ),
              ],
            ),

            // Player with play gate
            detailsAsync.when(
              data: (details) => VideoPlayerView(
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
              loading: () => const AspectRatio(
                aspectRatio: 16 / 9,
                child: Center(
                    child:
                        CircularProgressIndicator(color: Colors.blueAccent)),
              ),
              error: (_, __) => const AspectRatio(
                aspectRatio: 16 / 9,
                child: Center(
                    child: Text('Error', style: TextStyle(color: Colors.grey))),
              ),
            ),

            // Scrollable content below player
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Servers
                    PlayerServersList(
                      servers: servers,
                      selectedIndex: _selectedServerIndex,
                      onSelected: (index) {
                        setState(() => _selectedServerIndex = index);
                      },
                    ),

                    const SizedBox(height: 24),

                    // TV Episodes
                    if (widget.type == 'tv') ...[
                      PlayerEpisodesList(
                        id: widget.id,
                        season: widget.season,
                        currentEpisode: widget.episode,
                        scrollController: _episodesScrollController,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // About
                    detailsAsync.when(
                      data: (details) =>
                          PlayerAboutSection(details: details),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

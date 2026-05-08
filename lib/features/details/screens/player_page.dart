import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/server_constants.dart';
import '../../../providers/api_provider.dart';
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

  @override
  void initState() {
    super.initState();
    final double initialOffset = (widget.episode - 1) * 232.0;
    _episodesScrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void didUpdateWidget(PlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.episode != widget.episode) {
      if (_episodesScrollController.hasClients) {
        _episodesScrollController.animateTo(
          (widget.episode - 1) * 232.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _episodesScrollController.dispose();
    super.dispose();
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

    return Scaffold(
      backgroundColor: const Color(0xFF0F1014),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Bar overlapping or above the player
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
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
                      details['title'] ?? details['name'] ?? 'Playing',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ),
              ],
            ),
            
            // Player
            VideoPlayerView(serverUrl: currentServerUrl),
            
            // Rest of content
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
                        setState(() {
                          _selectedServerIndex = index;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 24),

                    // TV Episodes horizontal list
                    if (widget.type == 'tv') ...[
                      PlayerEpisodesList(
                        id: widget.id,
                        season: widget.season,
                        currentEpisode: widget.episode,
                        scrollController: _episodesScrollController,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Info Section
                    detailsAsync.when(
                      data: (details) => PlayerAboutSection(details: details),
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

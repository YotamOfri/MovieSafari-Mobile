import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../widgets/tmdb_image.dart';

class VideoPlayerView extends StatefulWidget {
  final String serverUrl;
  final String? thumbnailPath;
  final VoidCallback? onPlayPressed;
  final List<String>? allServers;   // for quick-switch fallback
  final int? currentServerIndex;
  final ValueChanged<int>? onServerSwitch;

  const VideoPlayerView({
    super.key,
    required this.serverUrl,
    this.thumbnailPath,
    this.onPlayPressed,
    this.allServers,
    this.currentServerIndex,
    this.onServerSwitch,
  });

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late WebViewController _controller;
  bool _isLoading = false;
  bool _isPlaying = false;
  bool _loadFailed = false;

  @override
  void didUpdateWidget(covariant VideoPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serverUrl != widget.serverUrl && _isPlaying) {
      _controller.loadRequest(Uri.parse(widget.serverUrl));
      setState(() {
        _isLoading = true;
        _loadFailed = false;
      });
    }
    if (oldWidget.serverUrl != widget.serverUrl && !_isPlaying) {
      setState(() {
        _loadFailed = false;
      });
    }
  }

  void _startPlaying() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();
            if (url.contains('vidsrc') ||
                url.contains('multiembed') ||
                url.contains('moviesapi') ||
                url.contains('vidfast') ||
                url.contains('streamingnow')) {
              return NavigationDecision.navigate;
            }
            debugPrint('Blocked ad popup/redirect: $url');
            return NavigationDecision.prevent;
          },
          onPageFinished: (String url) {
            if (mounted) setState(() { _isLoading = false; _loadFailed = false; });
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() { _isLoading = false; _loadFailed = true; });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.serverUrl));

    setState(() {
      _isPlaying = true;
      _isLoading = true;
    });

    widget.onPlayPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_isPlaying) WebViewWidget(controller: _controller),
          if (!_isPlaying) _buildPlayGate(),
          if (_isPlaying && _isLoading)
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
            ),
          // Server failed banner
          if (_isPlaying && _loadFailed) _buildFailedBanner(),
        ],
      ),
    );
  }

  Widget _buildFailedBanner() {
    final servers = widget.allServers;
    final currentIdx = widget.currentServerIndex ?? 0;
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          border: Border(top: BorderSide(color: Colors.red.withOpacity(0.4))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orangeAccent, size: 16),
                SizedBox(width: 8),
                Text(
                  'This server may be down. Try another:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
            if (servers != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: List.generate(servers.length, (i) {
                  if (i == currentIdx) return const SizedBox.shrink();
                  final label = _serverLabel(servers[i]);
                  return GestureDetector(
                    onTap: () => widget.onServerSwitch?.call(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.blueAccent.withOpacity(0.5)),
                      ),
                      child: Text(label,
                          style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _serverLabel(String url) {
    if (url.contains('vidfast')) return 'VidFast';
    if (url.contains('moviesapi')) return 'MoviesAPI';
    if (url.contains('multiembed')) return 'MultiEmbed';
    if (url.contains('vidsrc')) return 'VidSrc';
    return 'Server';
  }

  Widget _buildPlayGate() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail background
        if (widget.thumbnailPath != null)
          TmdbImage(path: widget.thumbnailPath, highResSize: 'w780')
        else
          Container(color: const Color(0xFF1A1C23)),

        // Dark overlay
        Container(color: Colors.black.withOpacity(0.55)),

        // Premium Play Button (Matches Details Page)
        Center(
          child: GestureDetector(
            onTap: _startPlaying,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 64,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

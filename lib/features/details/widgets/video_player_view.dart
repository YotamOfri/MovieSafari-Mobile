import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../widgets/tmdb_image.dart';

class VideoPlayerView extends StatefulWidget {
  final String serverUrl;
  final String? thumbnailPath; // poster/backdrop path for the gate screen
  final VoidCallback? onPlayPressed; // called when user taps play

  const VideoPlayerView({
    super.key,
    required this.serverUrl,
    this.thumbnailPath,
    this.onPlayPressed,
  });

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late WebViewController _controller;
  bool _isLoading = false;
  bool _isPlaying = false; // false = show play gate

  @override
  void didUpdateWidget(covariant VideoPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When server changes while already playing, reload immediately
    if (oldWidget.serverUrl != widget.serverUrl && _isPlaying) {
      _controller.loadRequest(Uri.parse(widget.serverUrl));
      setState(() => _isLoading = true);
    }
    // When episode changes (new serverUrl) reset gate so user re-taps play
    if (oldWidget.serverUrl != widget.serverUrl && !_isPlaying) {
      setState(() {}); // rebuild gate with new thumbnail
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
            if (mounted) setState(() => _isLoading = false);
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
          // Always render WebView underneath if playing
          if (_isPlaying) WebViewWidget(controller: _controller),

          // Play Gate — shown until user taps play
          if (!_isPlaying) _buildPlayGate(),

          // Loading spinner on top of WebView
          if (_isPlaying && _isLoading)
            Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.blueAccent),
              ),
            ),
        ],
      ),
    );
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

        // Play button
        Center(
          child: GestureDetector(
            onTap: _startPlaying,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.5),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 40),
            ),
          ),
        ),
      ],
    );
  }
}

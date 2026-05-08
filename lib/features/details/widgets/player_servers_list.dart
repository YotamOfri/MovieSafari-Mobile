import 'package:flutter/material.dart';

class PlayerServersList extends StatelessWidget {
  final List<String> servers;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const PlayerServersList({
    super.key,
    required this.servers,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Servers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            children: List.generate(servers.length, (index) {
              final isSelected = selectedIndex == index;
              final serverUrl = servers[index];
              
              String serverName = 'Server ${index + 1}';
              String? tag;
              Color baseColor = Colors.blueAccent;

              if (serverUrl.contains('vidfast')) {
                serverName = 'VidFast';
                tag = 'New';
                baseColor = Colors.orangeAccent;
              } else if (serverUrl.contains('moviesapi')) {
                serverName = 'MoviesAPI';
                tag = null;
                baseColor = Colors.purpleAccent;
              } else if (serverUrl.contains('multiembed')) {
                serverName = 'MultiEmbed';
                tag = 'Quality';
                baseColor = Colors.greenAccent;
              } else if (serverUrl.contains('vidsrc')) {
                serverName = 'VidSrc';
                tag = 'Reliable';
                baseColor = Colors.cyanAccent;
              }

              return GestureDetector(
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? baseColor.withValues(alpha: 0.15) 
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                          ? baseColor.withValues(alpha: 0.8) 
                          : Colors.white.withValues(alpha: 0.05),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_circle_fill,
                        size: 16,
                        color: isSelected ? baseColor : Colors.white54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        serverName,
                        style: TextStyle(
                          color: isSelected ? baseColor : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      if (tag != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: baseColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: baseColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: baseColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

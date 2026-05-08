import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../widgets/tmdb_image.dart';

class PlayerAboutSection extends StatelessWidget {
  final Map<String, dynamic> details;

  const PlayerAboutSection({
    super.key,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final overview = details['overview'];
    final rating = (details['vote_average'] as num?)?.toDouble() ?? 0.0;
    final String? posterPath = details['poster_path'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background Poster
            if (posterPath != null)
              Positioned.fill(
                child: TmdbImage(
                  path: posterPath,
                  highResSize: 'w780',
                ),
              ),
              
            // Gradient Overlay for text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0F1014).withValues(alpha: 0.95),
                      const Color(0xFF0F1014).withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedStar, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      if (details['first_air_date'] != null || details['release_date'] != null)
                        Text(
                          details['first_air_date'] ?? details['release_date'],
                          style: const TextStyle(color: Colors.white54),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (overview != null && overview.isNotEmpty)
                    Text(
                      overview,
                      style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

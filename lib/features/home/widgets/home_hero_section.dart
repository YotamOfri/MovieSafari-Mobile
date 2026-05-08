import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/tmdb_image.dart';

class HomeHeroSection extends StatelessWidget {
  final Map<String, dynamic> details;
  final bool showBackButton;

  const HomeHeroSection({
    super.key,
    required this.details,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final String title = details['title'] ?? details['name'] ?? 'Unknown';
    final String? backdropPath = details['backdrop_path'];
    final String? tagline = details['tagline'];
    final String? overview = details['overview'];
    final double rating = (details['vote_average'] as num?)?.toDouble() ?? 0.0;
    final int? seasons = details['number_of_seasons'];
    final String? firstAirDate = details['first_air_date'] ?? details['release_date'];
    final List<dynamic> genres = details['genres'] ?? [];
    final int id = details['id'] ?? 0;
    // Derive type: if it has 'name' and 'first_air_date', it's tv. Otherwise movie.
    final String type = details['media_type'] ?? (details.containsKey('first_air_date') ? 'tv' : 'movie');

    return Stack(
      children: [
        // Background Image
        TmdbImage(
          path: backdropPath,
          highResSize: 'original',
          height: 600,
          width: double.infinity,
        ),
        // Gradient Overlay
        Container(
          height: 600,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                const Color(0xFF0F1014).withOpacity(0.3),
                const Color(0xFF0F1014).withOpacity(0.8),
                const Color(0xFF0F1014),
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        ),
        if (showBackButton)
          Positioned(
            top: 48,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
        // Content
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                if (tagline != null && tagline.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    tagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.blueAccent.shade100,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Metadata Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedStar, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    if (seasons != null) ...[
                      Text(
                        '$seasons Seasons',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (firstAirDate != null)
                      Text(
                        firstAirDate.split('-')[0],
                        style: const TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Genre Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: genres.take(3).map((genre) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Text(
                        genre['name'],
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // Description
                if (overview != null && overview.isNotEmpty)
                  Text(
                    overview,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        context.push('/player/$type/$id');
                      },
                      icon: const HugeIcon(icon: HugeIcons.strokeRoundedPlayCircle, color: Colors.black, size: 24),
                      label: const Text('Play', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.push('/details/$type/$id');
                      },
                      icon: const Icon(Icons.info_outline, color: Colors.white),
                      label: const Text('More Info', style: TextStyle(color: Colors.white, fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24, width: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.white.withOpacity(0.05),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HeroLoadingPlaceholder extends StatelessWidget {
  const HeroLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      width: double.infinity,
      color: const Color(0xFF1A1C23),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.blueAccent),
      ),
    );
  }
}

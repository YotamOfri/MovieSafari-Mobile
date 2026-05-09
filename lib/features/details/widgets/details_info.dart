import 'package:flutter/material.dart';

class DetailsInfo extends StatelessWidget {
  final Map<String, dynamic> details;
  final String type;

  const DetailsInfo({
    super.key,
    required this.details,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final String title = details['title'] ?? details['name'] ?? 'Unknown';
    final String? tagline = details['tagline'];
    final String? overview = details['overview'];
    final double rating = (details['vote_average'] as num?)?.toDouble() ?? 0.0;
    final String? date = details['first_air_date'] ?? details['release_date'];
    final List<dynamic> genres = details['genres'] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          if (tagline != null && tagline.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              tagline,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (date != null)
                Text(
                  date.split('-')[0],
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                ),
              const SizedBox(width: 12),
              if (type == 'movie' && details['runtime'] != null)
                Text(
                  '${details['runtime']} min',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: genres.map((genre) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Text(
                    genre['name'],
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          if (overview != null && overview.isNotEmpty) ...[
            const Text(
              'Storyline',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              overview,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

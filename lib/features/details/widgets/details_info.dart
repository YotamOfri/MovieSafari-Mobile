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
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          
          // 1. Title & Tagline
          Text(
            title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ),
          if (tagline != null && tagline.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              tagline,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
                letterSpacing: 0.2,
              ),
            ),
          ],
          
          const SizedBox(height: 20),

          // 2. Metadata Row (Rating, Year, Runtime)
          Row(
            children: [
              // Rating Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.amber,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Year
              if (date != null)
                _MetadataIcon(
                  icon: Icons.calendar_today_rounded,
                  label: date.split('-')[0],
                ),
              
              const SizedBox(width: 16),
              
              // Runtime
              if (type == 'movie' && details['runtime'] != null)
                _MetadataIcon(
                  icon: Icons.timer_outlined,
                  label: '${details['runtime']}m',
                ),
            ],
          ),
          
          const SizedBox(height: 24),

          // 3. Genre Pills (Glassmorphic)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: genres.map((genre) {
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    genre['name'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 0.3,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 32),

          // 4. Storyline
          if (overview != null && overview.isNotEmpty) ...[
            const Text(
              'Storyline',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              overview,
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.6,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetadataIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetadataIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

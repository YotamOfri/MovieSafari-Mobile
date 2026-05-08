import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/tmdb_image.dart';

class HorizontalMediaList extends StatelessWidget {
  final List<dynamic> items;
  final String? defaultType;

  const HorizontalMediaList({super.key, required this.items, this.defaultType});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final String? posterPath = item['poster_path'];
        final int id = item['id'];
        final String type = item['media_type'] ?? defaultType ?? 'tv';

        return Padding(
          padding: const EdgeInsets.only(right: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.push('/details/$type/$id');
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: TmdbImage(
                        path: posterPath,
                        highResSize: 'w400',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class HorizontalLoadingPlaceholder extends StatelessWidget {
  const HorizontalLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: Container(color: const Color(0xFF1A1C23)),
          ),
        ),
      ),
    );
  }
}

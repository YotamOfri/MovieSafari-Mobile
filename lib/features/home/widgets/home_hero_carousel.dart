import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/tmdb_image.dart';
import '../../../providers/api_provider.dart'; // For tmdbGenres

class HomeHeroCarousel extends StatefulWidget {
  final List<dynamic> items;

  const HomeHeroCarousel({super.key, required this.items});

  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < widget.items.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const HeroLoadingPlaceholder();
    }

    return SizedBox(
      height: 600,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return _HeroItem(item: item);
            },
          ),
          
          // Page Indicators
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.items.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: _currentPage == index ? 24 : 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroItem extends StatelessWidget {
  final Map<String, dynamic> item;

  const _HeroItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final String title = item['title'] ?? item['name'] ?? 'Unknown';
    final String? backdropPath = item['backdrop_path'] ?? item['poster_path'];
    final String? overview = item['overview'];
    final double rating = (item['vote_average'] as num?)?.toDouble() ?? 0.0;
    final String? firstAirDate = item['first_air_date'] ?? item['release_date'];
    final List<dynamic> genreIds = item['genre_ids'] ?? [];
    final int id = item['id'] ?? 0;
    final String type = item['media_type'] ?? (item.containsKey('first_air_date') ? 'tv' : 'movie');

    // Resolve genre names
    final List<String> genreNames = genreIds
        .map((id) => tmdbGenres[id])
        .where((name) => name != null)
        .cast<String>()
        .toList();

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
                const Color(0xFF0F1014).withOpacity(0.4),
                const Color(0xFF0F1014).withOpacity(0.9),
                const Color(0xFF0F1014),
              ],
              stops: const [0.0, 0.4, 0.7, 1.0],
            ),
          ),
        ),
        
        // Content
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Metadata Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const HugeIcon(icon: HugeIcons.strokeRoundedStar, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(width: 12),
                    if (firstAirDate != null && firstAirDate.isNotEmpty)
                      Text(
                        firstAirDate.split('-')[0],
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Genre Tags
                if (genreNames.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: genreNames.take(3).map((genre) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Text(
                          genre,
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                
                // Description
                if (overview != null && overview.isNotEmpty)
                  Text(
                    overview,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                      height: 1.4,
                    ),
                  ),
                const SizedBox(height: 24),
                
                // Buttons (Smaller and sleeker)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Sleek circular Play Button with label
                    InkWell(
                      onTap: () => context.push('/player/$type/$id'),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
                            SizedBox(width: 6),
                            Text(
                              'Play',
                              style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // More Info Button
                    InkWell(
                      onTap: () => context.push('/details/$type/$id'),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.info_outline_rounded, color: Colors.white, size: 22),
                            SizedBox(width: 6),
                            Text(
                              'Info',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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

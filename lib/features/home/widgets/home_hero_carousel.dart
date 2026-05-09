import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/tmdb_image.dart';
import '../../../providers/api_provider.dart';

class HomeHeroCarousel extends StatefulWidget {
  final List<dynamic> items;

  const HomeHeroCarousel({super.key, required this.items});

  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  static const int _infiniteFactor = 10000;

  @override
  void initState() {
    super.initState();
    // Start in the middle of a very large range to simulate infinity
    final int initialPage = widget.items.length * (_infiniteFactor ~/ 2);
    _currentPage = initialPage;
    _pageController = PageController(initialPage: initialPage);
    
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextPage();
      }
    });

    _progressController.forward();
  }

  void _nextPage() {
    if (_pageController.hasClients) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _resetTimer() {
    _progressController.reset();
    _progressController.forward();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const HeroLoadingPlaceholder();
    }

    final int realCount = widget.items.length;

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
              _resetTimer();
            },
            itemCount: realCount * _infiniteFactor,
            itemBuilder: (context, index) {
              final item = widget.items[index % realCount];
              return _HeroItem(
                item: item,
                pageController: _pageController,
                index: index,
              );
            },
          ),
          
          // Page Indicators (Modern Progress Dots)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                realCount,
                (index) {
                  final bool isCurrent = (_currentPage % realCount) == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      height: 6,
                      width: isCurrent ? 32 : 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: isCurrent
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: AnimatedBuilder(
                                animation: _progressController,
                                builder: (context, child) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      height: 6,
                                      width: 32 * _progressController.value,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withValues(alpha: 0.3),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : null,
                    ),
                  );
                },
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
  final PageController pageController;
  final int index;

  const _HeroItem({
    required this.item,
    required this.pageController,
    required this.index,
  });

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

    return AnimatedBuilder(
      animation: pageController,
      builder: (context, child) {
        double value = 0;
        if (pageController.position.haveDimensions) {
          value = index.toDouble() - (pageController.page ?? 0);
        }
        
        // Clamping value for fade/slide
        final double opacity = (1 - (value.abs() * 0.8)).clamp(0.0, 1.0);
        final double slideOffset = value * 100;

        return Stack(
          children: [
            // Background Image (Parallax effect)
            Transform.translate(
              offset: Offset(value * 150, 0),
              child: TmdbImage(
                path: backdropPath,
                highResSize: 'original',
                height: 600,
                width: double.infinity,
              ),
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
                    const Color(0xFF0F1014).withValues(alpha: 0.4),
                    const Color(0xFF0F1014).withValues(alpha: 0.9),
                    const Color(0xFF0F1014),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
            
            // Content
            Positioned(
              bottom: 70,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: opacity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Title (Slightly faster slide)
                      Transform.translate(
                        offset: Offset(slideOffset * 0.5, 0),
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Metadata Row
                      Transform.translate(
                        offset: Offset(slideOffset * 0.4, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (firstAirDate != null && firstAirDate.isNotEmpty)
                              Text(
                                firstAirDate.split('-')[0],
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Description (Slightly slower slide)
                      Transform.translate(
                        offset: Offset(slideOffset * 0.3, 0),
                        child: overview != null && overview.isNotEmpty
                            ? Text(
                                overview,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  height: 1.5,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 16),

                      // Genre Tags
                      Transform.translate(
                        offset: Offset(slideOffset * 0.2, 0),
                        child: genreNames.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: Wrap(
                                  spacing: 8,
                                  alignment: WrapAlignment.center,
                                  children: genreNames.take(3).map((genre) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                                      ),
                                      child: Text(
                                        genre,
                                        style: const TextStyle(fontSize: 10, color: Colors.white70),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      
                      // Buttons
                      Transform.translate(
                        offset: Offset(slideOffset * 0.1, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _PrimaryButton(
                              label: 'Watch Now',
                              icon: Icons.play_arrow_rounded,
                              onTap: () => context.push('/player/$type/$id'),
                            ),
                            const SizedBox(width: 16),
                            _SecondaryButton(
                              label: 'Details',
                              icon: Icons.info_outline_rounded,
                              onTap: () => context.push('/details/$type/$id'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Colors.black, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _SecondaryButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
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

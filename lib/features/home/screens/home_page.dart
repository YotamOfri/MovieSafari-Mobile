import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Import Riverpod
import '../../../providers/api_provider.dart'; // 2. Import your provider
import '../widgets/home_hero_section.dart';
import '../widgets/horizontal_media_list.dart';

// Change StatelessWidget to ConsumerWidget
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  // Add WidgetRef ref to the build method
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(trendingMoviesProvider);
    final seriesAsync = ref.watch(trendingSeriesProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trendingMoviesProvider);
          ref.invalidate(trendingSeriesProvider);
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Section (Shows the first trending SERIES with details)
              seriesAsync.when(
                data: (series) {
                  if (series.isEmpty) return const SizedBox.shrink();
                  final heroId = series.first['id'];
                  final detailsAsync = ref.watch(tvDetailsProvider(heroId));

                  return detailsAsync.when(
                    data: (details) => HomeHeroSection(details: details),
                    loading: () => const HeroLoadingPlaceholder(),
                    error: (e, s) => const SizedBox(
                      height: 500,
                      child: Center(child: Text('Error loading hero')),
                    ),
                  );
                },
                loading: () => const HeroLoadingPlaceholder(),
                error: (e, s) => const SizedBox(height: 500),
              ),

              const SizedBox(height: 32),

              // 2. Trending Movies Section
              _buildSectionTitle('Trending Movies'),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: moviesAsync.when(
                  data: (movies) => HorizontalMediaList(items: movies),
                  loading: () => const HorizontalLoadingPlaceholder(),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
              ),

              const SizedBox(height: 32),

              // 3. Trending Series Section
              _buildSectionTitle('Trending Series'),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: seriesAsync.when(
                  data: (series) => HorizontalMediaList(items: series),
                  loading: () => const HorizontalLoadingPlaceholder(),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
              ),

              const SizedBox(height: 120), // Space for floating navbar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}

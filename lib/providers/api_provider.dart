import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

// Trending Movies
final trendingMoviesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.dio.get('/trending/movie/week?language=en-US');
  return response.data['results'] as List<dynamic>;
});

// Trending Series
final trendingSeriesProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.dio.get('/trending/tv/week?language=en-US');
  return response.data['results'] as List<dynamic>;
});

// Movie Details
final movieDetailsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.dio.get('/movie/$id?language=en-US');
  return response.data as Map<String, dynamic>;
});

// TV Series Details
final tvDetailsProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.dio.get('/tv/$id?language=en-US');
  return response.data as Map<String, dynamic>;
});

// TV Season Details
final tvSeasonDetailsProvider =
    FutureProvider.family<Map<String, dynamic>, (int, int)>((ref, params) async {
  final api = ref.watch(apiServiceProvider);
  final id = params.$1;
  final seasonNumber = params.$2;
  final response = await api.dio.get('/tv/$id/season/$seasonNumber?language=en-US');
  return response.data as Map<String, dynamic>;
});

// Movie Recommendations
final movieRecommendationsProvider =
    FutureProvider.family<List<dynamic>, int>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.dio.get('/movie/$id/recommendations?language=en-US&page=1');
  return response.data['results'] as List<dynamic>;
});

// TV Series Recommendations
final tvRecommendationsProvider =
    FutureProvider.family<List<dynamic>, int>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.dio.get('/tv/$id/recommendations?language=en-US&page=1');
  return response.data['results'] as List<dynamic>;
});

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }
}

// Search Query State
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

// Search Results
final searchResultsProvider = FutureProvider<List<dynamic>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) {
    return [];
  }
  
  final api = ref.watch(apiServiceProvider);
  final response = await api.dio.get('/search/multi?query=${Uri.encodeComponent(query)}&include_adult=false&language=en-US&page=1');
  
  final results = response.data['results'] as List<dynamic>;
  // Filter out 'person' media types as requested
  return results.where((item) => item['media_type'] != 'person').toList();
});

// Genre filter state: null = show all (trending)
class _GenreNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? genreId) => state = genreId;
}

final selectedGenreProvider = NotifierProvider<_GenreNotifier, int?>(
  _GenreNotifier.new,
);

// TMDB genre map (movie genres — TV shares most)
const tmdbGenres = {
  28: 'Action',
  35: 'Comedy',
  18: 'Drama',
  27: 'Horror',
  878: 'Sci-Fi',
  10749: 'Romance',
  16: 'Animation',
  53: 'Thriller',
};

// Genre-filtered movies
final filteredMoviesProvider = FutureProvider<List<dynamic>>((ref) async {
  final genreId = ref.watch(selectedGenreProvider);
  final api = ref.watch(apiServiceProvider);
  if (genreId == null) {
    final response = await api.dio.get('/trending/movie/week?language=en-US');
    return response.data['results'] as List<dynamic>;
  }
  final response = await api.dio.get(
      '/discover/movie?with_genres=$genreId&sort_by=popularity.desc&language=en-US&page=1');
  return response.data['results'] as List<dynamic>;
});

// Genre-filtered series
final filteredSeriesProvider = FutureProvider<List<dynamic>>((ref) async {
  final genreId = ref.watch(selectedGenreProvider);
  final api = ref.watch(apiServiceProvider);
  if (genreId == null) {
    final response = await api.dio.get('/trending/tv/week?language=en-US');
    return response.data['results'] as List<dynamic>;
  }
  final response = await api.dio.get(
      '/discover/tv?with_genres=$genreId&sort_by=popularity.desc&language=en-US&page=1');
  return response.data['results'] as List<dynamic>;
});

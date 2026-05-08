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

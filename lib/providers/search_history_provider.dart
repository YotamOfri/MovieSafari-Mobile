import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryNotifier extends Notifier<List<String>> {
  static const String _key = 'search_history';
  static const int _maxItems = 10;

  @override
  List<String> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_key) ?? [];
  }

  Future<void> addQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final updated = [
      trimmed,
      ...state.where((q) => q.toLowerCase() != trimmed.toLowerCase()),
    ].take(_maxItems).toList();
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, updated);
  }

  Future<void> removeQuery(String query) async {
    state = state.where((q) => q != query).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state);
  }

  Future<void> clearAll() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<String>>(
        SearchHistoryNotifier.new);

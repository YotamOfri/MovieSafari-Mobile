import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WatchedEntry {
  final int id;
  final String mediaType; // 'movie' or 'tv'
  final String title;
  final String? posterPath;

  // TV-specific
  final int? lastSeason;
  final int? lastEpisode;

  // Finished tracking
  final bool isFinished; // movie fully watched OR last episode of series watched

  // Set of "season_episode" keys for finished TV episodes e.g. "1_3"
  final Set<String> finishedEpisodes;

  const WatchedEntry({
    required this.id,
    required this.mediaType,
    required this.title,
    this.posterPath,
    this.lastSeason,
    this.lastEpisode,
    this.isFinished = false,
    this.finishedEpisodes = const {},
  });

  String get _episodeKey => '${lastSeason}_$lastEpisode';

  bool isEpisodeFinished(int season, int episode) =>
      finishedEpisodes.contains('${season}_$episode');

  WatchedEntry copyWith({
    int? lastSeason,
    int? lastEpisode,
    bool? isFinished,
    Set<String>? finishedEpisodes,
  }) {
    return WatchedEntry(
      id: id,
      mediaType: mediaType,
      title: title,
      posterPath: posterPath,
      lastSeason: lastSeason ?? this.lastSeason,
      lastEpisode: lastEpisode ?? this.lastEpisode,
      isFinished: isFinished ?? this.isFinished,
      finishedEpisodes: finishedEpisodes ?? this.finishedEpisodes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'media_type': mediaType,
        'title': title,
        'poster_path': posterPath,
        'last_season': lastSeason,
        'last_episode': lastEpisode,
        'is_finished': isFinished,
        'finished_episodes': finishedEpisodes.toList(),
      };

  factory WatchedEntry.fromJson(Map<String, dynamic> json) => WatchedEntry(
        id: json['id'],
        mediaType: json['media_type'],
        title: json['title'],
        posterPath: json['poster_path'],
        lastSeason: json['last_season'],
        lastEpisode: json['last_episode'],
        isFinished: json['is_finished'] ?? false,
        finishedEpisodes:
            Set<String>.from(json['finished_episodes'] as List? ?? []),
      );
}

class WatchHistoryNotifier extends Notifier<List<WatchedEntry>> {
  static const String _storageKey = 'watch_history';

  @override
  List<WatchedEntry> build() {
    _load();
    return [];
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    state = raw.map((s) => WatchedEntry.fromJson(jsonDecode(s))).toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _storageKey, state.map((e) => jsonEncode(e.toJson())).toList());
  }

  // Called when user presses Play. Records the media as "started" / updates last position.
  Future<void> markStarted({
    required int id,
    required String mediaType,
    required String title,
    String? posterPath,
    int? season,
    int? episode,
    // previous episode to auto-mark finished (TV only)
    int? prevSeason,
    int? prevEpisode,
  }) async {
    final idx = state.indexWhere((e) => e.id == id && e.mediaType == mediaType);
    WatchedEntry updated;

    if (idx == -1) {
      // First time watching
      updated = WatchedEntry(
        id: id,
        mediaType: mediaType,
        title: title,
        posterPath: posterPath,
        lastSeason: season,
        lastEpisode: episode,
      );
      state = [updated, ...state];
    } else {
      updated = state[idx];
      Set<String> finished = Set<String>.from(updated.finishedEpisodes);

      // Auto-mark previous TV episode as finished when switching episodes
      if (mediaType == 'tv' &&
          prevSeason != null &&
          prevEpisode != null &&
          !(prevSeason == season && prevEpisode == episode)) {
        finished.add('${prevSeason}_$prevEpisode');
      }

      updated = updated.copyWith(
        lastSeason: season ?? updated.lastSeason,
        lastEpisode: episode ?? updated.lastEpisode,
        finishedEpisodes: finished,
      );

      final newList = List<WatchedEntry>.from(state);
      newList.removeAt(idx);
      state = [updated, ...newList]; // bump to top
    }

    await _save();
  }

  // Called manually (button) or automatically by the 75% timer
  Future<void> markFinished({
    required int id,
    required String mediaType,
    String? title,
    String? posterPath,
    int? season,
    int? episode,
  }) async {
    final idx = state.indexWhere((e) => e.id == id && e.mediaType == mediaType);

    if (idx == -1) {
      // Create new entry if it doesn't exist
      if (title == null) return; // Need title to create
      final entry = WatchedEntry(
        id: id,
        mediaType: mediaType,
        title: title,
        posterPath: posterPath,
        isFinished: true,
        finishedEpisodes:
            mediaType == 'tv' && season != null && episode != null
                ? {'${season}_$episode'}
                : const {},
      );
      state = [entry, ...state];
      await _save();
      return;
    }

    final entry = state[idx];
    Set<String> finished = Set<String>.from(entry.finishedEpisodes);

    if (mediaType == 'tv' && season != null && episode != null) {
      finished.add('${season}_$episode');
    }

    final updated = entry.copyWith(
      isFinished: true, // Manually marking as finished
      finishedEpisodes: finished,
    );

    final newList = List<WatchedEntry>.from(state);
    newList[idx] = updated;
    state = newList;
    await _save();
  }

  Future<void> toggleFinished({
    required int id,
    required String mediaType,
    String? title,
    String? posterPath,
  }) async {
    final entry = getEntry(id, mediaType);
    if (entry != null && entry.isFinished) {
      // Unmark
      final idx =
          state.indexWhere((e) => e.id == id && e.mediaType == mediaType);

      // If it's a movie OR a TV series with no individual episodes finished,
      // remove it from history entirely to keep it clean.
      if (mediaType == 'movie' || entry.finishedEpisodes.isEmpty) {
        final newList = List<WatchedEntry>.from(state);
        newList.removeAt(idx);
        state = newList;
      } else {
        // Just unmark as finished but keep in history (since they watched some eps)
        final updated = state[idx].copyWith(isFinished: false);
        final newList = List<WatchedEntry>.from(state);
        newList[idx] = updated;
        state = newList;
      }
      await _save();
    } else {
      // Mark
      await markFinished(
        id: id,
        mediaType: mediaType,
        title: title,
        posterPath: posterPath,
      );
    }
  }

  Future<void> removeEntry(int id, String mediaType) async {
    state = state
        .where((e) => !(e.id == id && e.mediaType == mediaType))
        .toList();
    await _save();
  }

  Future<void> clearAll() async {
    state = [];
    await _save();
  }

  WatchedEntry? getEntry(int id, String mediaType) {
    try {
      return state.firstWhere((e) => e.id == id && e.mediaType == mediaType);
    } catch (_) {
      return null;
    }
  }

  bool isMovieFinished(int id) {
    final entry = getEntry(id, 'movie');
    return entry?.isFinished ?? false;
  }

  bool isEpisodeFinished(int id, int season, int episode) {
    final entry = getEntry(id, 'tv');
    return entry?.isEpisodeFinished(season, episode) ?? false;
  }

  // Only entries with lastEpisode set (in-progress, not necessarily finished)
  List<WatchedEntry> get continueWatching =>
      state.where((e) => !e.isFinished).take(10).toList();
}

final watchHistoryProvider =
    NotifierProvider<WatchHistoryNotifier, List<WatchedEntry>>(
        WatchHistoryNotifier.new);

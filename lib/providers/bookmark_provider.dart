import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Bookmark {
  final int id;
  final String title;
  final String? posterPath;
  final String mediaType;

  Bookmark({
    required this.id,
    required this.title,
    this.posterPath,
    required this.mediaType,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'poster_path': posterPath,
        'media_type': mediaType,
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        id: json['id'],
        title: json['title'],
        posterPath: json['poster_path'],
        mediaType: json['media_type'],
      );
}

class BookmarkNotifier extends Notifier<List<Bookmark>> {
  static const String _storageKey = 'bookmarks';

  @override
  List<Bookmark> build() {
    _loadBookmarks();
    return [];
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? bookmarksJson = prefs.getStringList(_storageKey);
    if (bookmarksJson != null) {
      state = bookmarksJson
          .map((item) => Bookmark.fromJson(jsonDecode(item)))
          .toList();
    }
  }

  Future<void> toggleBookmark(Bookmark bookmark) async {
    final isBookmarked = state.any((item) => item.id == bookmark.id && item.mediaType == bookmark.mediaType);
    
    if (isBookmarked) {
      state = state.where((item) => !(item.id == bookmark.id && item.mediaType == bookmark.mediaType)).toList();
    } else {
      state = [...state, bookmark];
    }

    final prefs = await SharedPreferences.getInstance();
    final List<String> bookmarksJson = state.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_storageKey, bookmarksJson);
  }

  bool isBookmarked(int id, String mediaType) {
    return state.any((item) => item.id == id && item.mediaType == mediaType);
  }
}

final bookmarkProvider = NotifierProvider<BookmarkNotifier, List<Bookmark>>(() {
  return BookmarkNotifier();
});

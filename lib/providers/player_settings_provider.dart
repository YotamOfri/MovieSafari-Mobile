import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final playerSettingsProvider = NotifierProvider<PlayerSettingsNotifier, PlayerSettings>(() {
  return PlayerSettingsNotifier();
});

class PlayerSettings {
  final int lastSelectedServerIndex;

  PlayerSettings({this.lastSelectedServerIndex = 0});

  PlayerSettings copyWith({int? lastSelectedServerIndex}) {
    return PlayerSettings(
      lastSelectedServerIndex: lastSelectedServerIndex ?? this.lastSelectedServerIndex,
    );
  }
}

class PlayerSettingsNotifier extends Notifier<PlayerSettings> {
  static const _keyServerIndex = 'player_last_server_index';

  @override
  PlayerSettings build() {
    _loadSettings();
    return PlayerSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_keyServerIndex) ?? 0;
    state = state.copyWith(lastSelectedServerIndex: index);
  }

  Future<void> setLastSelectedServerIndex(int index) async {
    state = state.copyWith(lastSelectedServerIndex: index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyServerIndex, index);
  }
}

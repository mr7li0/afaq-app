import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/athkar_category.dart';

/// Athkar state controller managing:
/// - Category loading from hisn_almuslim.json
/// - Interactive tap counter with persistence
/// - Audio playback (morning/evening/sleep)
/// - Favorites/bookmarks
/// - Search/filter
/// - Reset functionality
class AthkarController extends ChangeNotifier {
  // ── Data ──────────────────────────────────────────
  List<AthkarCategory> _allCategories = [];
  List<AthkarCategory> _filteredCategories = [];
  AthkarCategory? _selectedCategory;

  // ── Search ────────────────────────────────────────
  String _searchQuery = '';

  // ── Counter State ─────────────────────────────────
  Map<String, Map<String, int>> _counterState = {};

  // ── Audio ─────────────────────────────────────────
  AudioPlayer? _audioPlayer;
  String? _currentAudioCategory;
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;

  // ── Favorites ─────────────────────────────────────
  final Set<String> _favoriteTexts = {};

  // ── Loading ───────────────────────────────────────
  bool _isLoading = true;
  bool _isInitialized = false;

  // ── Getters ───────────────────────────────────────
  List<AthkarCategory> get allCategories => _allCategories;
  List<AthkarCategory> get filteredCategories => _filteredCategories;
  AthkarCategory? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isPlaying => _isPlaying;
  String? get currentAudioCategory => _currentAudioCategory;
  double get playbackSpeed => _playbackSpeed;
  bool get isLoading => _isLoading;

  // ── Audio Streams ────────────────────────────────
  Stream<Duration> get positionStream =>
      _audioPlayer?.positionStream ?? const Stream.empty();
  Stream<Duration?> get durationStream =>
      _audioPlayer?.durationStream ?? const Stream.empty();
  Stream<PlayerState> get playerStateStream =>
      _audioPlayer?.playerStateStream ?? const Stream.empty();

  bool isFavorite(String text) => _favoriteTexts.contains(text);

  // ── Initialization ────────────────────────────────
  Future<void> init() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    await _loadCategories();
    await _loadCounterState();
    await _loadFavorites();

    _audioPlayer = AudioPlayer();

    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  // ── Category Loading ──────────────────────────────
  Future<void> _loadCategories() async {
    try {
      final jsonString =
          await rootBundle.loadString(AppConstants.hisnAlMuslimPath);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      _allCategories = jsonMap.entries
          .where((e) => e.value is Map<String, dynamic>)
          .map((e) => AthkarCategory.fromJson(
                e.key,
                e.value as Map<String, dynamic>,
              ))
          .toList();

      _filteredCategories = List.from(_allCategories);
    } catch (e) {
      _allCategories = [];
      _filteredCategories = [];
    }
  }

  // ── Counter Persistence ───────────────────────────
  Future<void> _loadCounterState() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('athkar_counters_v2');
    if (json != null) {
      try {
        final Map<String, dynamic> saved = jsonDecode(json);
        _counterState = saved.map((k, v) => MapEntry(
              k,
              (v as Map<String, dynamic>)
                  .map((k2, v2) => MapEntry(k2, v2 as int)),
            ));

        // Apply saved counters to categories
        for (final category in _allCategories) {
          final savedCounters = _counterState[category.id];
          if (savedCounters != null) {
            for (final item in category.items) {
              if (savedCounters.containsKey(item.id)) {
                item.remainingCount = savedCounters[item.id]!;
              }
            }
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _saveCounterState() async {
    final prefs = await SharedPreferences.getInstance();
    final state = <String, dynamic>{};

    for (final category in _allCategories) {
      final itemMap = <String, int>{};
      for (final item in category.items) {
        itemMap[item.id] = item.remainingCount;
      }
      state[category.id] = itemMap;
    }

    await prefs.setString('athkar_counters_v2', jsonEncode(state));
  }

  // ── Favorites Persistence ─────────────────────────
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('athkar_favorites_v2') ?? [];
    _favoriteTexts.addAll(list);
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('athkar_favorites_v2', _favoriteTexts.toList());
  }

  // ── Category Selection ────────────────────────────
  void selectCategory(AthkarCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void clearSelection() {
    _selectedCategory = null;
    notifyListeners();
  }

  // ── Search / Filter ───────────────────────────────
  void updateSearchQuery(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredCategories = List.from(_allCategories);
    } else {
      _filteredCategories = _allCategories.where((cat) {
        final nameMatch = cat.name.contains(query);
        final nameEnMatch = cat.nameEn.toLowerCase().contains(query.toLowerCase());
        final textMatch =
            cat.items.any((item) => item.text.contains(query));
        return nameMatch || nameEnMatch || textMatch;
      }).toList();
    }
    notifyListeners();
  }

  // ── Tap Counter ───────────────────────────────────
  /// Decrement the counter for a specific item.
  /// Returns true if the item just completed.
  bool tapDhikr(AthkarCategory category, int itemIndex) {
    if (itemIndex < 0 || itemIndex >= category.items.length) return false;

    final justCompleted = category.items[itemIndex].tap();

    // Haptic feedback per spec
    if (justCompleted) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    // Save state
    _saveCounterState();
    notifyListeners();

    return justCompleted;
  }

  /// Reset all counters in a category.
  void resetCategory(AthkarCategory category) {
    category.resetAll();
    _saveCounterState();
    notifyListeners();
  }

  /// Reset all counters across all categories.
  void resetAllCounters() {
    for (final category in _allCategories) {
      category.resetAll();
    }
    _saveCounterState();
    notifyListeners();
  }

  // ── Audio Playback ────────────────────────────────
  /// Get audio path for a category, preferring item-level asset over category-level.
  String? getAudioPathForCategory(String categoryName) {
    // Check category-level audio first
    for (final cat in _allCategories) {
      if (cat.name == categoryName && cat.audioAsset != null) {
        return cat.audioAsset;
      }
    }
    return null;
  }

  Future<void> playCategoryAudio(AthkarCategory category) async {
    final audioPath = category.audioAsset;
    if (audioPath == null || _audioPlayer == null) return;

    try {
      if (_currentAudioCategory == category.name && _isPlaying) {
        await pauseAudio();
        return;
      }

      await _audioPlayer!.setAsset(audioPath);
      await _audioPlayer!.setSpeed(_playbackSpeed);
      await _audioPlayer!.setLoopMode(LoopMode.one);
      await _audioPlayer!.play();

      _currentAudioCategory = category.name;
      _isPlaying = true;
      notifyListeners();

      _audioPlayer!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          notifyListeners();
        }
      });
    } catch (e) {
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> pauseAudio() async {
    await _audioPlayer?.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> stopAudio() async {
    await _audioPlayer?.stop();
    _isPlaying = false;
    _currentAudioCategory = null;
    notifyListeners();
  }

  void setPlaybackSpeed(double speed) {
    _playbackSpeed = speed;
    _audioPlayer?.setSpeed(speed);
    notifyListeners();
  }

  // ── Favorites ─────────────────────────────────────
  void toggleFavorite(String text) {
    if (_favoriteTexts.contains(text)) {
      _favoriteTexts.remove(text);
    } else {
      _favoriteTexts.add(text);
    }
    _saveFavorites();
    notifyListeners();
  }

  // ── Cleanup ───────────────────────────────────────
  @override
  void dispose() {
    _audioPlayer?.dispose();
    super.dispose();
  }
}

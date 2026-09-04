import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/color_constants.dart';
import '../../../../core/services/audio_service.dart';
import '../../../../shared/models/quran_verse.dart';
import '../../../../shared/models/bookmark.dart';
import '../../../../shared/models/wird_progress.dart';
import '../search/quran_search_engine.dart';

/// Quran & Wird engine controller managing:
/// - Verse data loading & surah/juz navigation
/// - Offline search with diacritics stripping
/// - Recitation audio playback from public CDNs
/// - Ambient audio layer (rain, mosque ambience)
/// - Bookmark management
/// - Wird progress tracking
/// - Auto-scroll hands-free reading
/// - Ayah action sheet state
class QuranController extends ChangeNotifier {
  // ── Data ──────────────────────────────────────────
  final QuranSearchEngine _searchEngine = QuranSearchEngine();
  List<QuranVerse> _currentVerses = [];
  int _currentSurah = 1;
  int _currentJuz = 1;
  int _currentPage = 1;

  // ── Search ────────────────────────────────────────
  String _searchQuery = '';
  List<SearchResult> _searchResults = [];
  bool _isSearchActive = false;
  bool _isSearching = false;

  // ── Audio ─────────────────────────────────────────
  AudioPlayer? _recitationPlayer;
  AudioPlayer? _rainPlayer;
  AudioPlayer? _mosquePlayer;
  QuranVerse? _currentlyPlayingVerse;
  bool _isPlaying = false;
  bool _ambientPlaying = false;
  double _rainVolume = 0.5;
  double _mosqueVolume = 0.5;

  // ── Bookmarks ─────────────────────────────────────
  final Set<String> _bookmarkedVerses = {};

  // ── Wird ──────────────────────────────────────────
  WirdProgress _wirdProgress = WirdProgress();

  // ── Auto-Scroll ───────────────────────────────────
  bool _autoScrollEnabled = false;
  Timer? _autoScrollTimer;
  ScrollController? _scrollController;
  double _autoScrollSpeed = 0.5; // pixels per tick

  // ── Ayah Action Sheet ─────────────────────────────
  QuranVerse? _selectedVerseForAction;

  // ── Loading ───────────────────────────────────────
  bool _isLoading = true;
  bool _isInitialized = false;

  // ── Getters ───────────────────────────────────────
  QuranSearchEngine get searchEngine => _searchEngine;
  List<QuranVerse> get currentVerses => _currentVerses;
  int get currentSurah => _currentSurah;
  int get currentJuz => _currentJuz;
  int get currentPage => _currentPage;

  String get searchQuery => _searchQuery;
  List<SearchResult> get searchResults => _searchResults;
  bool get isSearchActive => _isSearchActive;
  bool get isSearching => _isSearching;

  AudioPlayer? get recitationPlayer => _recitationPlayer;
  QuranVerse? get currentlyPlayingVerse => _currentlyPlayingVerse;
  bool get isPlaying => _isPlaying;
  bool get ambientPlaying => _ambientPlaying;
  double get rainVolume => _rainVolume;
  double get mosqueVolume => _mosqueVolume;

  Set<String> get bookmarkedVerses => _bookmarkedVerses;
  WirdProgress get wirdProgress => _wirdProgress;

  bool get autoScrollEnabled => _autoScrollEnabled;
  double get autoScrollSpeed => _autoScrollSpeed;

  QuranVerse? get selectedVerseForAction => _selectedVerseForAction;
  bool get isLoading => _isLoading;

  // ── CDN URL Builder ───────────────────────────────
  /// Build EveryAyah CDN URL for recitation audio.
  /// Pattern: https://everyayah.com/data/Alafasy_128kbps/{surah}_{ayah}.mp3
  static String getRecitationUrl(int surah, int ayah) {
    final surahStr = surah.toString().padLeft(3, '0');
    final ayahStr = ayah.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/Alafasy_128kbps/$surahStr$ayahStr.mp3';
  }

  // ── Initialization ────────────────────────────────
  Future<void> init() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    await _searchEngine.loadVerses();
    await _loadBookmarks();
    await _loadWirdProgress();
    _loadSurah(1);

    _recitationPlayer = AudioPlayer();
    _rainPlayer = AudioPlayer();
    _mosquePlayer = AudioPlayer();

    _isInitialized = true;
    _isLoading = false;
    notifyListeners();
  }

  // ── Surah / Juz Navigation ────────────────────────
  void loadSurah(int surahNumber) {
    if (surahNumber < 1 || surahNumber > 114) return;
    _currentSurah = surahNumber;
    _currentVerses = _searchEngine.getVersesForSurah(surahNumber);
    if (_currentVerses.isNotEmpty) {
      _currentPage = _currentVerses.first.page;
      _currentJuz = _currentVerses.first.juz;
    }
    notifyListeners();
  }

  void loadJuz(int juzNumber) {
    if (juzNumber < 1 || juzNumber > 30) return;
    _currentJuz = juzNumber;
    _currentVerses = _searchEngine.getVersesForJuz(juzNumber);
    if (_currentVerses.isNotEmpty) {
      _currentPage = _currentVerses.first.page;
      _currentSurah = _currentVerses.first.surah;
    }
    notifyListeners();
  }

  void _loadSurah(int surahNumber) {
    _currentSurah = surahNumber;
    _currentVerses = _searchEngine.getVersesForSurah(surahNumber);
    if (_currentVerses.isNotEmpty) {
      _currentPage = _currentVerses.first.page;
      _currentJuz = _currentVerses.first.juz;
    }
  }

  // ── Search ────────────────────────────────────────
  void activateSearch() {
    _isSearchActive = true;
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  void deactivateSearch() {
    _isSearchActive = false;
    _searchQuery = '';
    _searchResults = [];
    _isSearching = false;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    _isSearching = true;
    notifyListeners();

    // Debounce search
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchQuery == query) {
        _searchResults = _searchEngine.search(query);
        _isSearching = false;
        notifyListeners();
      }
    });
  }

  void navigateToSearchResult(SearchResult result) {
    _currentSurah = result.verse.surah;
    _currentVerses = _searchEngine.getVersesForSurah(_currentSurah);
    _currentPage = result.verse.page;
    _currentJuz = result.verse.juz;
    _isSearchActive = false;
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  // ── Recitation Audio ──────────────────────────────
  Future<void> playRecitation(QuranVerse verse) async {
    if (_recitationPlayer == null) return;

    try {
      final url = getRecitationUrl(verse.surah, verse.ayah);
      await _recitationPlayer!.setUrl(url);
      await _recitationPlayer!.play();
      _currentlyPlayingVerse = verse;
      _isPlaying = true;
      notifyListeners();

      // Listen for completion
      _recitationPlayer!.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _isPlaying = false;
          _currentlyPlayingVerse = null;
          notifyListeners();
        }
      });
    } catch (e) {
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> pauseRecitation() async {
    await _recitationPlayer?.pause();
    _isPlaying = false;
    notifyListeners();
  }

  Future<void> resumeRecitation() async {
    await _recitationPlayer?.play();
    _isPlaying = true;
    notifyListeners();
  }

  Future<void> stopRecitation() async {
    await _recitationPlayer?.stop();
    _isPlaying = false;
    _currentlyPlayingVerse = null;
    notifyListeners();
  }

  // ── Ambient Audio ─────────────────────────────────
  Future<void> toggleAmbient() async {
    if (_ambientPlaying) {
      await stopAmbient();
    } else {
      await playAmbient();
    }
  }

  Future<void> playAmbient() async {
    try {
      // Play rain sound
      await _rainPlayer?.setAsset('assets/audio/notifications/athkar-morning.mp3');
      await _rainPlayer?.setVolume(_rainVolume);
      await _rainPlayer?.setLoopMode(LoopMode.one);
      await _rainPlayer?.play();

      _ambientPlaying = true;
      notifyListeners();
    } catch (e) {
      _ambientPlaying = false;
    }
  }

  Future<void> stopAmbient() async {
    await _rainPlayer?.stop();
    await _mosquePlayer?.stop();
    _ambientPlaying = false;
    notifyListeners();
  }

  Future<void> setRainVolume(double volume) async {
    _rainVolume = volume.clamp(0.0, 1.0);
    await _rainPlayer?.setVolume(_rainVolume);
    notifyListeners();
  }

  Future<void> setMosqueVolume(double volume) async {
    _mosqueVolume = volume.clamp(0.0, 1.0);
    await _mosquePlayer?.setVolume(_mosqueVolume);
    notifyListeners();
  }

  // ── Bookmarks ─────────────────────────────────────
  bool isBookmarked(QuranVerse verse) {
    return _bookmarkedVerses.contains(verse.key);
  }

  Future<void> toggleBookmark(QuranVerse verse) async {
    if (_bookmarkedVerses.contains(verse.key)) {
      _bookmarkedVerses.remove(verse.key);
    } else {
      _bookmarkedVerses.add(verse.key);
    }
    await _saveBookmarks();
    notifyListeners();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('quran_bookmarks') ?? [];
    _bookmarkedVerses.addAll(list);
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('quran_bookmarks', _bookmarkedVerses.toList());
  }

  // ── Wird Progress ─────────────────────────────────
  void markPageRead(int page) {
    _wirdProgress.markPageRead(page);
    _saveWirdProgress();
    notifyListeners();
  }

  Future<void> _loadWirdProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('wird_progress');
    if (json != null) {
      try {
        _wirdProgress = WirdProgress.fromJson(
          Map<String, dynamic>.from(
            Map<String, dynamic>.from(
              jsonDecode(json) as Map,
            ),
          ),
        );
      } catch (_) {
        _wirdProgress = WirdProgress();
      }
    }
  }

  Future<void> _saveWirdProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wird_progress', jsonEncode(_wirdProgress.toJson()));
  }

  // ── Auto-Scroll ───────────────────────────────────
  void setScrollController(ScrollController controller) {
    _scrollController = controller;
  }

  void toggleAutoScroll() {
    _autoScrollEnabled = !_autoScrollEnabled;

    if (_autoScrollEnabled) {
      _startAutoScroll();
    } else {
      _stopAutoScroll();
    }
    notifyListeners();
  }

  void setAutoScrollSpeed(double speed) {
    _autoScrollSpeed = speed.clamp(0.1, 2.0);
    notifyListeners();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) {
        if (_scrollController != null && _scrollController!.hasClients) {
          _scrollController!.animateTo(
            _scrollController!.offset + _autoScrollSpeed,
            duration: const Duration(milliseconds: 50),
            curve: Curves.linear,
          );
        }
      },
    );
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  // ── Ayah Action Sheet ─────────────────────────────
  void selectVerseForAction(QuranVerse verse) {
    _selectedVerseForAction = verse;
    notifyListeners();
  }

  void clearSelectedVerse() {
    _selectedVerseForAction = null;
    notifyListeners();
  }

  // ── Tafsir ────────────────────────────────────────
  Map<int, Map<int, String>> _tafsirData = {};

  String getTafsir(int surah, int ayah) {
    return _tafsirData[surah]?[ayah] ?? '';
  }

  Future<void> loadTafsir() async {
    try {
      final jsonString =
          await rootBundle.loadString(AppConstants.tafsirDataPath);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      final surahs = jsonMap['data']?['surahs'] as List<dynamic>? ?? [];

      for (final surah in surahs) {
        final surahNumber = surah['number'] as int;
        final ayahs = surah['ayahs'] as List<dynamic>? ?? [];
        _tafsirData[surahNumber] = {};
        for (final ayah in ayahs) {
          final ayahNumber = ayah['numberInSurah'] as int? ?? ayah['number'] as int;
          _tafsirData[surahNumber]![ayahNumber] = ayah['text'] as String? ?? '';
        }
      }
    } catch (e) {
      // Silently fail
    }
    notifyListeners();
  }

  // ── Ayah Number Formatting ────────────────────────
  /// Convert integer to Arabic-Indic numerals for ayah markers.
  static String toArabicNumerals(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number.toString().split('').map((d) {
      final digit = int.tryParse(d);
      return digit != null ? arabicDigits[digit] : d;
    }).join();
  }

  // ── Cleanup ───────────────────────────────────────
  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _recitationPlayer?.dispose();
    _rainPlayer?.dispose();
    _mosquePlayer?.dispose();
    _scrollController = null;
    super.dispose();
  }
}

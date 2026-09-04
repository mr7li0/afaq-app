import 'dart:convert';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/diacritics_remover.dart';
import '../../../../shared/models/quran_verse.dart';

/// Offline Quran search engine with smart diacritics stripping.
///
/// Algorithm:
/// 1. Load all verses from local quran_data.json
/// 2. Strip diacritics from BOTH query and verse text
/// 3. Search sequentially from Al-Fatiha → An-Nas
/// 4. Return first 15 matches with original diacritics intact
/// 5. Provide highlighted text spans for UI rendering
class QuranSearchEngine {
  List<QuranVerse> _verses = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  int get totalVerses => _verses.length;

  // ── Data Loading ──────────────────────────────────
  Future<void> loadVerses() async {
    if (_loaded) return;

    try {
      final jsonString =
          await rootBundle.loadString(AppConstants.quranDataPath);
      final List<dynamic> jsonList = json.decode(jsonString);
      _verses = jsonList.map((e) => QuranVerse.fromJson(e)).toList();
      _loaded = true;
    } catch (e) {
      _verses = [];
      _loaded = false;
    }
  }

  // ── Search ────────────────────────────────────────
  /// Search the Quran sequentially (Al-Fatiha → An-Nas).
  /// Returns the first [maxResults] matches.
  /// Both query and verse text are stripped of diacritics for matching,
  /// but original text with diacritics is preserved in results.
  List<SearchResult> search(String query, {int maxResults = 15}) {
    if (query.trim().isEmpty || _verses.isEmpty) return [];

    final normalizedQuery = DiacriticsRemover.remove(query).toLowerCase().trim();
    if (normalizedQuery.isEmpty) return [];

    final results = <SearchResult>[];

    for (final verse in _verses) {
      final normalizedVerse = DiacriticsRemover.remove(verse.text).toLowerCase();

      if (normalizedVerse.contains(normalizedQuery)) {
        results.add(SearchResult(
          verse: verse,
          query: query,
        ));

        if (results.length >= maxResults) break;
      }
    }

    return results;
  }

  // ── Get Verses for Surah ──────────────────────────
  List<QuranVerse> getVersesForSurah(int surahNumber) {
    return _verses.where((v) => v.surah == surahNumber).toList();
  }

  // ── Get Verses for Juz ────────────────────────────
  List<QuranVerse> getVersesForJuz(int juzNumber) {
    return _verses.where((v) => v.juz == juzNumber).toList();
  }

  // ── Get Verse by Reference ────────────────────────
  QuranVerse? getVerse(int surah, int ayah) {
    try {
      return _verses.firstWhere((v) => v.surah == surah && v.ayah == ayah);
    } catch (_) {
      return null;
    }
  }

  // ── Get all verses ────────────────────────────────
  List<QuranVerse> get allVerses => List.unmodifiable(_verses);
}

/// A search result containing the matched verse and highlighted text data.
class SearchResult {
  final QuranVerse verse;
  final String query;

  const SearchResult({
    required this.verse,
    required this.query,
  });

  /// Get the original verse text (with diacritics).
  String get text => verse.text;

  /// Get verse reference string.
  String get reference => '${verse.surahName} : ${verse.ayah}';

  /// Get English surah name.
  String get surahEnglish => verse.surahEnglish;

  /// Build highlighted text spans for display.
  /// The matched portion is wrapped in a highlighted style.
  List<MatchSegment> get highlightedSegments {
    final normalizedText = DiacriticsRemover.remove(text).toLowerCase();
    final normalizedQuery = DiacriticsRemover.remove(query).toLowerCase().trim();

    final segments = <MatchSegment>[];
    int lastIndex = 0;

    int searchFrom = 0;
    while (true) {
      final index = normalizedText.indexOf(normalizedQuery, searchFrom);
      if (index == -1) break;

      // Add text before match
      if (index > lastIndex) {
        segments.add(MatchSegment(
          text: text.substring(lastIndex, index),
          isHighlighted: false,
        ));
      }

      // Calculate the original text range for this match
      // Since diacritics are removed, we need to map back to original indices
      final originalMatch = _findOriginalRange(
        text,
        normalizedText,
        index,
        normalizedQuery.length,
      );

      segments.add(MatchSegment(
        text: text.substring(originalMatch.start, originalMatch.end),
        isHighlighted: true,
      ));

      lastIndex = originalMatch.end;
      searchFrom = index + normalizedQuery.length;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      segments.add(MatchSegment(
        text: text.substring(lastIndex),
        isHighlighted: false,
      ));
    }

    return segments.isEmpty
        ? [MatchSegment(text: text, isHighlighted: false)]
        : segments;
  }

  /// Map a normalized-text index back to original text indices.
  _OriginalRange _findOriginalRange(
    String original,
    String normalized,
    int normalizedStart,
    int normalizedLength,
  ) {
    // Walk through original text, tracking normalized position
    int origIndex = 0;
    int normIndex = 0;

    // Find start position
    while (origIndex < original.length && normIndex < normalizedStart) {
      final char = original[origIndex];
      final normalizedChar = DiacriticsRemover.remove(char);
      origIndex++;
      normIndex += normalizedChar.length;
    }
    final start = origIndex;

    // Find end position
    final normalizedEnd = normalizedStart + normalizedLength;
    while (origIndex < original.length && normIndex < normalizedEnd) {
      final char = original[origIndex];
      final normalizedChar = DiacriticsRemover.remove(char);
      origIndex++;
      normIndex += normalizedChar.length;
    }
    final end = origIndex;

    return _OriginalRange(start, end);
  }
}

class _OriginalRange {
  final int start;
  final int end;
  const _OriginalRange(this.start, this.end);
}

/// A segment of text that may or may not be highlighted.
class MatchSegment {
  final String text;
  final bool isHighlighted;

  const MatchSegment({
    required this.text,
    required this.isHighlighted,
  });
}

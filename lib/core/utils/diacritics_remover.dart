/// Utility to strip Arabic diacritics (tashkeel/harakat) and hamzas
/// from text for search normalization.
///
/// Converts text like "إِنَّ الَّذِينَ" → "ان الذين"
class DiacriticsRemover {
  DiacriticsRemover._();

  // ── Unicode Diacritics Ranges ──────────────────────
  // Arabic Tashkeel: U+064B–U+065F, U+0670
  static final RegExp _tashkeel = RegExp(
    r'[\u064B-\u065F\u0670]',
  );

  // ── Hamza (ء) ─────────────────────────────────────
  // Plain hamza removed during normalization
  static final RegExp _hamza = RegExp(r'\u0621');

  // ── Alef Variants ──────────────────────────────────
  // آ أ إ → ا
  static final RegExp _alefVariants = RegExp(r'[\u0622\u0623\u0625]');

  // ── Teh Marbuta ────────────────────────────────────
  // ة → ه
  static final RegExp _tehMarbuta = RegExp(r'\u0629');

  // ── Alef Maqsura ───────────────────────────────────
  // ى → ي
  static final RegExp _alefMaqsura = RegExp(r'\u0649');

  // ── Tatweel / Kashida ──────────────────────────────
  static final RegExp _tatweel = RegExp(r'\u0640');

  /// Remove all diacritics and normalize Arabic text for search.
  /// This is a one-way transformation for matching purposes.
  static String remove(String text) {
    String result = text;
    result = result.replaceAll(_tashkeel, '');
    result = result.replaceAll(_tatweel, '');
    result = result.replaceAll(_hamza, '');
    result = result.replaceAllMapped(_alefVariants, (m) => 'ا');
    result = result.replaceAll(_tehMarbuta, 'ه');
    result = result.replaceAll(_alefMaqsura, 'ي');
    return result;
  }

  /// Remove diacritics only (preserve hamza and alef variants).
  static String removeDiacriticsOnly(String text) {
    return text.replaceAll(_tashkeel, '').replaceAll(_tatweel, '');
  }

  /// Check if a text contains a query (both stripped of diacritics).
  static bool contains(String text, String query) {
    final normalizedText = remove(text).toLowerCase();
    final normalizedQuery = remove(query).toLowerCase();
    return normalizedText.contains(normalizedQuery);
  }

  /// Find all matching positions of query within text (diacritics-agnostic).
  static List<int> findAllMatches(String text, String query) {
    final normalizedText = remove(text).toLowerCase();
    final normalizedQuery = remove(query).toLowerCase();
    final positions = <int>[];
    int startIndex = 0;
    while (true) {
      final index = normalizedText.indexOf(normalizedQuery, startIndex);
      if (index == -1) break;
      positions.add(index);
      startIndex = index + 1;
    }
    return positions;
  }
}

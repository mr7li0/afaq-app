/// Data model for a single Quran verse (ayah).
/// Maps directly to the quran_data.json structure.
class QuranVerse {
  final int surah;
  final int ayah;
  final String text;
  final String surahName;
  final String surahEnglish;
  final int juz;
  final int page;

  const QuranVerse({
    required this.surah,
    required this.ayah,
    required this.text,
    required this.surahName,
    required this.surahEnglish,
    required this.juz,
    required this.page,
  });

  factory QuranVerse.fromJson(Map<String, dynamic> json) {
    return QuranVerse(
      surah: json['surah'] as int,
      ayah: json['ayah'] as int,
      text: json['text'] as String,
      surahName: json['surah_name'] as String,
      surahEnglish: json['surah_english'] as String,
      juz: json['juz'] as int,
      page: json['page'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'surah': surah,
        'ayah': ayah,
        'text': text,
        'surah_name': surahName,
        'surah_english': surahEnglish,
        'juz': juz,
        'page': page,
      };

  /// Unique key for this verse.
  String get key => '$surah:$ayah';

  /// Display reference string.
  String get reference => '$surahName : $ayah';

  @override
  String toString() => 'QuranVerse($surah:$ayah)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuranVerse && surah == other.surah && ayah == other.ayah;

  @override
  int get hashCode => surah.hashCode ^ ayah.hashCode;
}

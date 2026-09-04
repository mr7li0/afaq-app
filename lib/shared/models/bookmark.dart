class Bookmark {
  final int surah;
  final int ayah;
  final DateTime timestamp;

  Bookmark({required this.surah, required this.ayah, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'surah': surah,
        'ayah': ayah,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Bookmark.fromJson(Map<String, dynamic> j) => Bookmark(
        surah: j['surah'] ?? 0,
        ayah: j['ayah'] ?? 0,
        timestamp: j['timestamp'] != null ? DateTime.parse(j['timestamp']) : null,
      );
}

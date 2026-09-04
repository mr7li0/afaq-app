/// Enhanced Athkar category model from Hisn Al-Muslim.
/// Maps to top-level keys in hisn_almuslim.json.
///
/// Spec fields:
/// - id: auto-generated unique identifier
/// - category_id: category slug for persistence
/// - category_name: display name
/// - text: dhikr text with diacritics
/// - count: target repeats (auto-estimated from text content)
/// - reward_text: fadilath / virtue text (mapped from footnotes)
/// - audio_asset: optional path to local audio file
class AthkarCategory {
  final String id;
  final String name;
  final String nameEn;
  final List<AthkarItem> items;
  final List<String> footnotes;
  final int iconCodePoint;
  final String? audioAsset;

  const AthkarCategory({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.items,
    this.footnotes = const [],
    this.iconCodePoint = 0xe939, // default icon
    this.audioAsset,
  });

  factory AthkarCategory.fromJson(String name, Map<String, dynamic> json) {
    final texts = (json['text'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final footnotes = (json['footnote'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final mapping = _categoryMapping(name);
    final categoryId = _slugify(name);

    // Determine audio asset for this category
    final audioPath = _audioAssetForCategory(name);

    return AthkarCategory(
      id: categoryId,
      name: name,
      nameEn: mapping?.$2 ?? name,
      items: texts
          .asMap()
          .entries
          .map((entry) => AthkarItem(
                id: '${categoryId}_${entry.key}',
                text: entry.value,
                defaultCount: _estimateCount(entry.value),
                // Use corresponding footnote as reward text when available
                rewardText: entry.key < footnotes.length
                    ? footnotes[entry.key]
                    : null,
                audioAsset: audioPath,
              ))
          .toList(),
      footnotes: footnotes,
      iconCodePoint: mapping?.$3 ?? 0xe939,
      audioAsset: audioPath,
    );
  }

  int get totalItems => items.length;

  int get completedCount => items.where((item) => item.isCompleted).length;

  double get completionProgress =>
      totalItems > 0 ? completedCount / totalItems : 0.0;

  bool get isFullyCompleted => totalItems > 0 && completedCount == totalItems;

  /// Reset all item counters in this category.
  void resetAll() {
    for (final item in items) {
      item.reset();
    }
  }

  // ── Dhikr Count Estimation ────────────────────────
  static int _estimateCount(String text) {
    if (text.contains('سبحان الله')) return 33;
    if (text.contains('الحمد لله')) return 33;
    if (text.contains('الله أكبر')) return 33;
    if (text.contains('لا إله إلا الله')) return 100;
    if (text.contains('أستغفر الله')) return 100;
    if (text.contains('لا حول ولا قوة إلا الله')) return 100;
    if (text.contains('سبحان الله وبحمده')) return 100;
    if (text.contains('لا إله إلا الله وحده')) return 100;
    return 1; // Default single recitation
  }

  // ── Audio Asset Mapping ───────────────────────────
  static String? _audioAssetForCategory(String name) {
    const audioMap = <String, String>{
      'أذكار الصباح والمساء': 'assets/audio/notifications/athkar-morning.mp3',
      'أذكار النوم': 'assets/audio/notifications/athkar-sleep.mp3',
      'أذكار الاستيقاظ من النوم': 'assets/audio/notifications/duha.mp3',
    };
    return audioMap[name];
  }

  // ── Slugify Category Name ─────────────────────────
  static String _slugify(String name) {
    return name
        .replaceAll(' ', '_')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), '')
        .toLowerCase();
  }

  // ── Category Mapping (Arabic → English + Icon) ────
  static (String, String, int)? _categoryMapping(String name) {
    const map = <String, (String, String, int)>{
      'المقدمة': ('Introduction', 'info', 0xe88f),
      'فضل الذكر': ('Virtues of Dhikr', 'star', 0xe25b),
      'أذكار الاستيقاظ من النوم': ('Wake-up Athkar', 'alarm', 0xe335),
      'دعاء لبس الثوب': ('Wearing Clothes', 'checkroom', 0xe593),
      'دعاء لبس الثوب الجديد': ('New Clothes', 'checkroom', 0xe593),
      'الدعاء لمن لبس ثوباً جديداً': ('New Clothes Supplication', 'checkroom', 0xe593),
      'ما يقول إذا وضع الثوب': ('Removing Clothes', 'unfold_less', 0xe5d6),
      'دعاء دخول الخلاء': ('Enter Bathroom', 'wc', 0xe588),
      'دعاء الخروج من الخلاء': ('Exit Bathroom', 'wc', 0xe588),
      'الذكر قبل الوضوء': ('Before Wudu', 'water_drop', 0xe798),
      'الذكر بعد الفراغ من الوضوء': ('After Wudu', 'water_drop', 0xe798),
      'الذكر عند الخروج من المنزل': ('Leaving Home', 'home', 0xe88c),
      'الذكر عند الدخول المنزل': ('Entering Home', 'home', 0xe88c),
      'دعاء الذهاب إلى المسجد': ('Going to Mosque', 'mosque', 0xf107),
      'دعاء دخول المسجد': ('Enter Mosque', 'mosque', 0xf107),
      'دعاء الخروج من المسجد': ('Exit Mosque', 'mosque', 0xf107),
      'أذكار الأذان': ('Athan Athkar', 'notifications_active', 0xe7f7),
      'دعاء الاستفتاح': ('Opening Prayer', 'play_circle', 0xe039),
      'دعاء الركوع': ('Ruku Supplication', ' accessibility_new', 0xf10b),
      'دعاء الرفع من الركوع': ('Rising from Ruku', 'accessibility_new', 0xf10b),
      'دعاء السجود': ('Sujud Supplication', 'gesture', 0xe53e),
      'دعاء الجلسة بين السجدتين': ('Between Sujud', 'gesture', 0xe53e),
      'دعاء سجود التلاوة': ('Recitation Sujud', 'gesture', 0xe53e),
      'التشهد': ('Tashahhud', 'menu_book', 0xe2c8),
      'الصلاة على النبي صلى الله عليه وسلم بعد التشهد': ('Salawat', 'favorite', 0xe87d),
      'دعاء التشهد الأخير وقبل السلام': ('Final Tashahhud', 'menu_book', 0xe2c8),
      'الأذكار بعد السلام من الصلاة': ('Post-Prayer Athkar', 'check_circle', 0xe86c),
      'دعاء صلاة الاستخارة': ('Istikhara Prayer', 'brightness_3', 0xe3db),
      'أذكار الصباح والمساء': ('Morning & Evening', 'wb_sunny', 0xe33b),
      'أذكار النوم': ('Sleep Athkar', 'bedtime', 0xe33a),
      'الدعاء إذا تقلب ليلاً': ('Night Restlessness', 'nights_stay', 0xe636),
      'دعاء القلق والفزع في النوم ومن بلي بالوحشة': ('Anxiety & Fear', 'psychology', 0xe919),
      'ما يفعل من رأى الرؤيا أو الحلم': ('Dreams Interpretation', 'auto_stories', 0xe873),
      'دعاء قنوت الوتر': ('Witr Qunut', 'nights_stay', 0xe636),
      'الذكر عقب السلام من الوتر': ('Post-Witr Dhikr', 'nights_stay', 0xe636),
      'دعاء الهم والحزن': ('Grief & Sorrow', 'sentiment_dissatisfied', 0xe814),
      'دعاء الكرب': ('Distress Supplication', 'emergency', 0xe001),
      'دعاء لقاء العدو وذي السلطان': ('Meeting Enemy/Ruler', 'shield', 0xe9a7),
      'دعاء من خاف ظلم السلطان': ('Tyranny Protection', 'security', 0xe32a),
      'الدعاء على العدو': ('Against Enemy', 'gavel', 0xe30e),
      'ما يقول من خاف قوماً': ('Fear of People', 'groups', 0xe7ef),
      'دعاء من أصابه شك في الإيمان': ('Doubt in Faith', 'help_outline', 0xe8fd),
      'دعاء قضاء الدين': ('Debt Relief', 'account_balance', 0xe84f),
      'دعاء الوسوسة في الصلاة والقراءة': ('Prayer Whisperings', 'hearing', 0xe901),
      'دعاء من استصعب عليه أمر': ('Difficulty Supplication', 'trending_up', 0xe8e5),
      'ما يقول ويفعل من أذنب ذنباً': ('Sin Repentance', 'redo', 0xe40a),
      'دعاء طرد الشيطان ووساوسه': ('Shaytan Repulsion', 'block', 0xe14b),
      'دعاء حينما يقع مالا يرضاه أو غلب على أمره': ('Unwanted Events', 'warning', 0xe002),
      'تهنئة المولود له وجوابه': ('Newborn Congratulations', 'child_care', 0xe907),
      'ما يعوذ به الأولاد': ('Child Protection', 'family_restroom', 0xe935),
    };
    return map[name];
  }
}

/// A single dhikr/athkar item within a category.
///
/// Spec fields:
/// - id: unique identifier for persistence
/// - text: dhikr text with diacritics
/// - count: target repeats (defaultCount)
/// - reward_text: fadilath / virtue text
/// - audio_asset: optional audio path
class AthkarItem {
  final String id;
  final String text;
  final int defaultCount;
  final String? rewardText;
  final String? audioAsset;
  int remainingCount;
  bool isFavorite;

  AthkarItem({
    required this.id,
    required this.text,
    required this.defaultCount,
    this.rewardText,
    this.audioAsset,
    int? remainingCount,
    this.isFavorite = false,
  }) : remainingCount = remainingCount ?? defaultCount;

  bool get isCompleted => remainingCount <= 0;

  /// Decrement count by 1 on tap. Returns true if just completed.
  bool tap() {
    if (remainingCount > 0) {
      remainingCount--;
      return remainingCount == 0;
    }
    return false;
  }

  /// Reset counter to default.
  void reset() {
    remainingCount = defaultCount;
  }

  /// Toggle favorite state.
  void toggleFavorite() {
    isFavorite = !isFavorite;
  }

  /// Progress as a fraction (0.0 to 1.0).
  double get progress =>
      defaultCount > 0 ? 1.0 - (remainingCount / defaultCount) : 1.0;

  /// Serialize counter state for persistence.
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'defaultCount': defaultCount,
        'remainingCount': remainingCount,
        'isFavorite': isFavorite,
        'rewardText': rewardText,
        'audioAsset': audioAsset,
      };

  factory AthkarItem.fromJson(Map<String, dynamic> json) {
    return AthkarItem(
      id: json['id'] as String? ?? '',
      text: json['text'] as String,
      defaultCount: json['defaultCount'] as int? ?? 1,
      remainingCount: json['remainingCount'] as int?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      rewardText: json['rewardText'] as String?,
      audioAsset: json['audioAsset'] as String?,
    );
  }
}

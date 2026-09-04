class WirdProgress {
  int dailyPages = 0;
  int totalPages = 0;
  int dailyGoal = 4;
  DateTime? lastDate;
  Set<int> readPages = {};

  WirdProgress();

  double get completionPercentage => dailyGoal > 0 ? (dailyPages / dailyGoal).clamp(0.0, 1.0) : 0.0;

  void markPageRead(int page) {
    dailyPages++;
    totalPages++;
    readPages.add(page);
    final now = DateTime.now();
    if (lastDate == null || lastDate!.day != now.day || lastDate!.month != now.month || lastDate!.year != now.year) {
      dailyPages = 1;
      readPages = {page};
    }
    lastDate = now;
  }

  Map<String, dynamic> toJson() => {
        'dailyPages': dailyPages,
        'totalPages': totalPages,
        'dailyGoal': dailyGoal,
        'lastDate': lastDate?.toIso8601String(),
      };

  factory WirdProgress.fromJson(Map<String, dynamic> j) {
    final w = WirdProgress();
    w.dailyPages = j['dailyPages'] ?? 0;
    w.totalPages = j['totalPages'] ?? 0;
    w.dailyGoal = j['dailyGoal'] ?? 4;
    w.lastDate = j['lastDate'] != null ? DateTime.parse(j['lastDate']) : null;
    return w;
  }
}

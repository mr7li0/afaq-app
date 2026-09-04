/// Centralized SVG Icon Management System.
///
/// This class maps every available SVG asset to a type-safe constant.
/// Only icons from the official whitelist may be used.
///
/// **Whitelist** (`assets/icons/`):
/// arrow-right, bell, bookmark, book-open-text, circle-check,
/// circle-chevron-down, circle-pause, circle-play, compass, download,
/// files, heart, home, image, layout-grid, logo, map, minus, plus,
/// refresh-cw, rotate-ccw, search, send, settings-2, share-2,
/// skip-back, skip-forward, square-arrow-out-up-right, star, sun,
/// user-round, x
///
/// Directional icons (arrow-right, send, circle-chevron-down) are
/// auto-mirrored via [MirroredIcon] widget in RTL layouts.
class AppIcons {
  AppIcons._();

  // ── Base Path ────────────────────────────────────────
  static const String _path = 'assets/icons/';

  // ── Navigation ───────────────────────────────────────
  static const String home = '${_path}home.svg';
  static const String search = '${_path}search.svg';
  static const String settings = '${_path}settings-2.svg';
  static const String user = '${_path}user-round.svg';
  static const String layoutGrid = '${_path}layout-grid.svg';

  // ── Content & Reading ────────────────────────────────
  static const String bookOpen = '${_path}book-open-text.svg';
  static const String bookmark = '${_path}bookmark.svg';
  static const String files = '${_path}files.svg';

  // ── Media ────────────────────────────────────────────
  static const String play = '${_path}circle-play.svg';
  static const String pause = '${_path}circle-pause.svg';
  static const String image = '${_path}image.svg';
  static const String skipBack = '${_path}skip-back.svg';
  static const String skipForward = '${_path}skip-forward.svg';

  // ── Actions ──────────────────────────────────────────
  static const String heart = '${_path}heart.svg';
  static const String star = '${_path}star.svg';
  static const String plus = '${_path}plus.svg';
  static const String minus = '${_path}minus.svg';
  static const String refresh = '${_path}refresh-cw.svg';
  static const String download = '${_path}download.svg';
  static const String send = '${_path}send.svg';
  static const String close = '${_path}x.svg';
  static const String share = '${_path}share-2.svg';
  static const String rotateCcw = '${_path}rotate-ccw.svg';

  // ── Directional (auto-mirror in RTL) ─────────────────
  static const String arrowRight = '${_path}arrow-right.svg';
  static const String chevronDown = '${_path}circle-chevron-down.svg';

  // ── Navigation & Location ────────────────────────────
  static const String compass = '${_path}compass.svg';
  static const String map = '${_path}map.svg';

  // ── Status ───────────────────────────────────────────
  static const String check = '${_path}circle-check.svg';
  static const String bell = '${_path}bell.svg';
  static const String sun = '${_path}sun.svg';
  static const String externalLink = '${_path}square-arrow-out-up-right.svg';

  // ── Branding ─────────────────────────────────────────
  static const String logo = '${_path}logo.svg';

  // ── Aliases (for backward compatibility) ─────────────
  /// Alias for [close] — use `close` for new code.
  static const String x = close;

  /// Alias for [bookOpen] — use `bookOpenText` for Phase 2 dashboard.
  static const String bookOpenText = bookOpen;

  /// Alias for [play] — use `play` for new code.
  static const String circlePlay = play;

  /// Alias for [pause] — use `pause` for new code.
  static const String circlePause = pause;

  /// Alias for [refresh] — use `refresh` for new code.
  static const String refreshCw = refresh;

  /// Alias for [settings] — use `settings` for new code.
  static const String settings2 = settings;

  /// Alias for [share] — use `share` for new code.
  static const String share2 = share;

  /// Alias for [externalLink] — use `externalLink` for new code.
  static const String squareArrowOutUpRight = externalLink;

  // ── Directional Icons List ───────────────────────────
  /// Icons that should auto-mirror horizontally in RTL layouts.
  static const List<String> directionalIcons = [
    arrowRight,
    send,
    chevronDown,
  ];

  // ── Fallback Mapping ─────────────────────────────────
  /// Maps requested icon names that aren't in the whitelist
  /// to the closest available alternative.
  static const Map<String, String> fallbackMap = {
    'bell-off': bell,          // Use bell with reduced opacity
    'chevron-up': chevronDown, // Rotate 180° for upward
    'chevron-left': arrowRight, // Mirror for left direction
    'map-pin': map,            // Map icon as location fallback
    'share-2': share,          // Alias
  };

  /// Get an icon path with intelligent fallback.
  /// Returns the whitelisted path or a safe fallback.
  static String getIcon(String requestedName) {
    // Check direct match first
    final directMatch = _directMap[requestedName];
    if (directMatch != null) return directMatch;

    // Check fallback map
    final fallback = fallbackMap[requestedName];
    if (fallback != null) return fallback;

    // Default to home icon as ultimate fallback
    return home;
  }

  // ── Internal Direct Map ──────────────────────────────
  static const Map<String, String> _directMap = {
    'home': home,
    'search': search,
    'settings': settings,
    'settings-2': settings,
    'user': user,
    'user-round': user,
    'layout-grid': layoutGrid,
    'book-open-text': bookOpen,
    'book-open': bookOpen,
    'bookmark': bookmark,
    'files': files,
    'circle-play': play,
    'play': play,
    'circle-pause': pause,
    'pause': pause,
    'image': image,
    'skip-back': skipBack,
    'skip-forward': skipForward,
    'heart': heart,
    'star': star,
    'plus': plus,
    'minus': minus,
    'refresh-cw': refresh,
    'refresh': refresh,
    'download': download,
    'send': send,
    'x': close,
    'close': close,
    'share-2': share,
    'share': share,
    'rotate-ccw': rotateCcw,
    'arrow-right': arrowRight,
    'circle-chevron-down': chevronDown,
    'chevron-down': chevronDown,
    'compass': compass,
    'map': map,
    'map-pin': map,
    'circle-check': check,
    'check': check,
    'bell': bell,
    'sun': sun,
    'square-arrow-out-up-right': externalLink,
    'external-link': externalLink,
    'logo': logo,
  };
}

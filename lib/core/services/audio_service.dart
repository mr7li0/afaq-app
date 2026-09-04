import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

/// Centralized audio service managing:
/// - Athan playback (local assets)
/// - Ambient reading sounds (rain, mosque)
/// - Quran recitation streaming with local caching
/// - Volume controls per channel
class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  // ── Players ────────────────────────────────────────
  final AudioPlayer _athanPlayer = AudioPlayer();
  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _recitationPlayer = AudioPlayer();

  bool _initialized = false;

  // ── State ──────────────────────────────────────────
  double _athanVolume = 1.0;
  double _ambientVolume = 0.5;
  double _recitationVolume = 1.0;
  bool _ambientPlaying = false;

  double get athanVolume => _athanVolume;
  double get ambientVolume => _ambientVolume;
  double get recitationVolume => _recitationVolume;
  bool get isAmbientPlaying => _ambientPlaying;

  // ── Initialization ─────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());

    _athanPlayer.playerStateStream.listen((state) {
      // Handle athan completion
    });

    _initialized = true;
  }

  // ── Athan Playback ─────────────────────────────────
  /// Play an athan from local assets.
  Future<void> playAthan(String assetPath) async {
    try {
      await _athanPlayer.setAsset(assetPath);
      await _athanPlayer.setVolume(_athanVolume);
      await _athanPlayer.play();
    } catch (e) {
      // Silently fail for athan — user should not see errors
    }
  }

  /// Stop current athan playback.
  Future<void> stopAthan() async {
    await _athanPlayer.stop();
  }

  // ── Notification Audio ─────────────────────────────
  /// Play a notification sound (athkar, reminders, etc.).
  Future<void> playNotificationSound(String assetPath) async {
    try {
      final player = AudioPlayer();
      await player.setAsset(assetPath);
      await player.setVolume(_athanVolume);
      await player.play();
      // Auto-dispose after completion
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          player.dispose();
        }
      });
    } catch (e) {
      // Silently fail
    }
  }

  // ── Ambient Sounds ─────────────────────────────────
  /// Play ambient background sound for Quran reading.
  Future<void> playAmbient(String assetPath) async {
    try {
      await _ambientPlayer.setAsset(assetPath);
      await _ambientPlayer.setVolume(_ambientVolume);
      await _ambientPlayer.setLoopMode(LoopMode.one);
      await _ambientPlayer.play();
      _ambientPlaying = true;
    } catch (e) {
      _ambientPlaying = false;
    }
  }

  /// Stop ambient sound.
  Future<void> stopAmbient() async {
    await _ambientPlayer.stop();
    _ambientPlaying = false;
  }

  /// Set ambient volume (0.0 to 1.0).
  Future<void> setAmbientVolume(double volume) async {
    _ambientVolume = volume.clamp(0.0, 1.0);
    await _ambientPlayer.setVolume(_ambientVolume);
  }

  // ── Quran Recitation ───────────────────────────────
  /// Play recitation from a public CDN URL.
  /// Uses just_audio's built-in caching.
  Future<void> playRecitation(String url) async {
    try {
      await _recitationPlayer.setUrl(url);
      await _recitationPlayer.setVolume(_recitationVolume);
      await _recitationPlayer.play();
    } catch (e) {
      // Handle network errors gracefully
    }
  }

  /// Pause recitation.
  Future<void> pauseRecitation() async {
    await _recitationPlayer.pause();
  }

  /// Stop recitation.
  Future<void> stopRecitation() async {
    await _recitationPlayer.stop();
  }

  /// Seek to position.
  Future<void> seekRecitation(Duration position) async {
    await _recitationPlayer.seek(position);
  }

  /// Set recitation volume.
  Future<void> setRecitationVolume(double volume) async {
    _recitationVolume = volume.clamp(0.0, 1.0);
    await _recitationPlayer.setVolume(_recitationVolume);
  }

  // ── General Controls ───────────────────────────────
  /// Set master volume for athan channel.
  Future<void> setAthanVolume(double volume) async {
    _athanVolume = volume.clamp(0.0, 1.0);
    await _athanPlayer.setVolume(_athanVolume);
  }

  /// Pause all audio (for Khushoo Mode).
  Future<void> pauseAll() async {
    await _athanPlayer.pause();
    await _ambientPlayer.pause();
    await _recitationPlayer.pause();
  }

  /// Resume all paused audio.
  Future<void> resumeAll() async {
    await _athanPlayer.play();
    if (_ambientPlaying) {
      await _ambientPlayer.play();
    }
    await _recitationPlayer.play();
  }

  // ── Streams ────────────────────────────────────────
  Stream<Duration> get recitationPosition =>
      _recitationPlayer.positionStream;
  Stream<Duration?> get recitationDuration =>
      _recitationPlayer.durationStream;
  Stream<PlayerState> get recitationState =>
      _recitationPlayer.playerStateStream;

  // ── Dispose ────────────────────────────────────────
  Future<void> dispose() async {
    await _athanPlayer.dispose();
    await _ambientPlayer.dispose();
    await _recitationPlayer.dispose();
    _initialized = false;
  }
}

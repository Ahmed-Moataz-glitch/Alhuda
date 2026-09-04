import 'dart:async';
import 'package:alhuda/model/adhan_model.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AdhanAudioService extends ChangeNotifier {
  static final AdhanAudioService _instance = AdhanAudioService._internal();

  factory AdhanAudioService() => _instance;

  final AudioPlayer _player = AudioPlayer();

  AdhanSound _selectedSound = AdhanData.defaultAdhan;
  AdhanSound? _currentPlayingSound;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  final Map<String, bool> _prayerAlerts = {
    'الفجر': true,
    'الشروق': false,
    'الظهر': true,
    'العصر': true,
    'المغرب': true,
    'العشاء': true,
  };

  StreamSubscription? _stateSubscription;
  StreamSubscription? _posSubscription;
  StreamSubscription? _durSubscription;
  StreamSubscription? _completeSubscription;

  AdhanAudioService._internal() {
    _initListeners();
  }

  void _initListeners() {
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      _playerState = state;
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        _currentPlayingSound = null;
        _position = Duration.zero;
      }
      notifyListeners();
    });

    _posSubscription = _player.onPositionChanged.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _durSubscription = _player.onDurationChanged.listen((dur) {
      _duration = dur;
      notifyListeners();
    });

    _completeSubscription = _player.onPlayerComplete.listen((_) {
      _currentPlayingSound = null;
      _playerState = PlayerState.completed;
      _position = Duration.zero;
      notifyListeners();
    });
  }

  AdhanSound get selectedSound => _selectedSound;
  AdhanSound? get currentPlayingSound => _currentPlayingSound;
  PlayerState get playerState => _playerState;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isPlaying => _playerState == PlayerState.playing;
  Map<String, bool> get prayerAlerts => Map.unmodifiable(_prayerAlerts);

  bool isPrayerAlertEnabled(String prayerName) =>
      _prayerAlerts[prayerName] ?? true;

  void togglePrayerAlert(String prayerName, bool enabled) {
    _prayerAlerts[prayerName] = enabled;
    notifyListeners();
  }

  void setSelectedAdhan(AdhanSound sound) {
    _selectedSound = sound;
    notifyListeners();
  }

  Future<void> play(AdhanSound sound) async {
    try {
      if (_currentPlayingSound?.id == sound.id &&
          _playerState == PlayerState.paused) {
        await _player.resume();
        return;
      }

      await _player.stop();
      _currentPlayingSound = sound;
      _position = Duration.zero;

      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientExclusive,
          ),
        ),
      );

      if (sound.sourceType == AdhanAudioSourceType.asset) {
        // Remove 'assets/' prefix if present for AssetSource in audioplayers
        final cleanPath = sound.source.startsWith('assets/')
            ? sound.source.substring(7)
            : sound.source;
        await _player.play(AssetSource(cleanPath));
      } else {
        await _player.play(UrlSource(sound.source));
      }
    } catch (e) {
      debugPrint('Error playing Adhan sound: $e');
      _currentPlayingSound = null;
      _playerState = PlayerState.stopped;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.resume();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentPlayingSound = null;
    _position = Duration.zero;
    notifyListeners();
  }

  Future<void> seek(Duration pos) async {
    await _player.seek(pos);
  }

  Future<void> toggle(AdhanSound sound) async {
    if (_currentPlayingSound?.id == sound.id && isPlaying) {
      await pause();
    } else {
      await play(sound);
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _posSubscription?.cancel();
    _durSubscription?.cancel();
    _completeSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }
}

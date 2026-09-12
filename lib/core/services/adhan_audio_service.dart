import 'dart:async';
import 'dart:ui';
import 'package:alhuda/model/adhan_model.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AdhanAudioService extends ChangeNotifier {
  static final AdhanAudioService _instance = AdhanAudioService._internal();

  factory AdhanAudioService() => _instance;
  static AdhanAudioService get instance => _instance;

  static const MethodChannel _channel =
      MethodChannel('com.example.alhuda/adhan');

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
    _channel.setMethodCallHandler(_handleMethodCall);

    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      _playerState = state;
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        _currentPlayingSound = null;
        _position = Duration.zero;
        _stopMonitoring();
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
      _stopMonitoring();
      notifyListeners();
    });
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'stopAdhan') {
      await stop();
    }
  }

  Future<void> _startMonitoring() async {
    try {
      await _channel.invokeMethod('startAdhanMonitoring');
    } catch (_) {}
  }

  Future<void> _stopMonitoring() async {
    try {
      await _channel.invokeMethod('stopAdhanMonitoring');
    } catch (_) {}
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
      await _startMonitoring();
    } catch (e) {
      debugPrint('Error playing Adhan sound: $e');
      _currentPlayingSound = null;
      _playerState = PlayerState.stopped;
      await _stopMonitoring();
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _player.pause();
    await _stopMonitoring();
  }

  Future<void> resume() async {
    await _player.resume();
    await _startMonitoring();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentPlayingSound = null;
    _position = Duration.zero;
    await _stopMonitoring();
    try {
      final sendPort = IsolateNameServer.lookupPortByName('adhan_stop_port');
      sendPort?.send('stop');
    } catch (_) {}
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
    _stopMonitoring();
    _stateSubscription?.cancel();
    _posSubscription?.cancel();
    _durSubscription?.cancel();
    _completeSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }
}

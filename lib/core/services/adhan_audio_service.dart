import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:alhuda/core/services/notification_services.dart';
import 'package:alhuda/features/prayer_times/data/models/adhan_model.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class AdhanAudioService extends ChangeNotifier {
  static final AdhanAudioService _instance = AdhanAudioService._internal();

  factory AdhanAudioService() => _instance;
  static AdhanAudioService get instance => _instance;

  static const MethodChannel _channel =
      MethodChannel('com.example.alhuda/adhan');

  final AudioPlayer _player = AudioPlayer();

  AdhanSound _selectedSound = AdhanData.defaultAdhan;
  AdhanSound? _currentPlayingSound;
  String _currentPrayerName = '';
  int _currentNotificationId = 9999;
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
  ReceivePort? _controlPort;

  AdhanAudioService._internal() {
    _initListeners();
  }

  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/alhuda_adhan_settings.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        if (data['selectedSoundId'] != null) {
          final soundId = data['selectedSoundId'] as String;
          _selectedSound = AdhanData.availableSounds.firstWhere(
            (s) => s.id == soundId,
            orElse: () => AdhanData.defaultAdhan,
          );
        }
        if (data['prayerAlerts'] != null) {
          final alerts = Map<String, dynamic>.from(data['prayerAlerts']);
          for (final entry in alerts.entries) {
            _prayerAlerts[entry.key] = entry.value as bool;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading adhan settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/alhuda_adhan_settings.json');
      final data = {
        'selectedSoundId': _selectedSound.id,
        'prayerAlerts': _prayerAlerts,
      };
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (e) {
      debugPrint('Error saving adhan settings: $e');
    }
  }

  void _initListeners() {
    _channel.setMethodCallHandler(_handleMethodCall);

    _setupControlPort();

    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      _playerState = state;
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        _currentPlayingSound = null;
        _position = Duration.zero;
        _stopMonitoring();
        NotificationServices.cancelAdhanNotification(id: _currentNotificationId);
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
      NotificationServices.cancelAdhanNotification(id: _currentNotificationId);
      notifyListeners();
    });
  }

  void _setupControlPort() {
    try {
      _controlPort?.close();
      _controlPort = ReceivePort();
      IsolateNameServer.removePortNameMapping(NotificationServices.adhanControlPort);
      IsolateNameServer.registerPortWithName(
        _controlPort!.sendPort,
        NotificationServices.adhanControlPort,
      );

      _controlPort!.listen((message) async {
        if (message == 'stop') {
          await stop();
        } else if (message == 'pause') {
          await pause();
        } else if (message == 'resume') {
          await resume();
        }
      });
    } catch (e) {
      debugPrint('Error setting up adhan control port: $e');
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'stopAdhan') {
      await stop();
    } else if (call.method == 'pauseAdhan') {
      await pause();
    } else if (call.method == 'resumeAdhan') {
      await resume();
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
    _saveSettings();
  }

  void setSelectedAdhan(AdhanSound sound) {
    _selectedSound = sound;
    notifyListeners();
    _saveSettings();
  }

  Future<void> play(
    AdhanSound sound, {
    String prayerName = '',
    int notificationId = 9999,
  }) async {
    try {
      _setupControlPort();
      _currentPrayerName = prayerName;
      _currentNotificationId = notificationId;

      if (_currentPlayingSound?.id == sound.id &&
          _playerState == PlayerState.paused) {
        await resume();
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

      // Show interactive notification with controls
      await NotificationServices.showAdhanControlNotification(
        id: _currentNotificationId,
        prayerName: _currentPrayerName,
        sound: sound,
        isPlaying: true,
      );
    } catch (e) {
      debugPrint('Error playing Adhan sound: $e');
      _currentPlayingSound = null;
      _playerState = PlayerState.stopped;
      await _stopMonitoring();
      await NotificationServices.cancelAdhanNotification(id: _currentNotificationId);
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _player.pause();
    await _stopMonitoring();
    if (_currentPlayingSound != null) {
      await NotificationServices.showAdhanControlNotification(
        id: _currentNotificationId,
        prayerName: _currentPrayerName,
        sound: _currentPlayingSound!,
        isPlaying: false,
      );
    }
  }

  Future<void> resume() async {
    await _player.resume();
    await _startMonitoring();
    if (_currentPlayingSound != null) {
      await NotificationServices.showAdhanControlNotification(
        id: _currentNotificationId,
        prayerName: _currentPrayerName,
        sound: _currentPlayingSound!,
        isPlaying: true,
      );
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentPlayingSound = null;
    _position = Duration.zero;
    await _stopMonitoring();
    await NotificationServices.cancelAdhanNotification(id: _currentNotificationId);
    try {
      final legacySendPort = IsolateNameServer.lookupPortByName('adhan_stop_port');
      legacySendPort?.send('stop');
    } catch (_) {}
    notifyListeners();
  }

  Future<void> seek(Duration pos) async {
    await _player.seek(pos);
  }

  Future<void> toggle(AdhanSound sound, {String prayerName = ''}) async {
    if (_currentPlayingSound?.id == sound.id && isPlaying) {
      await pause();
    } else {
      await play(sound, prayerName: prayerName);
    }
  }

  @override
  void dispose() {
    _controlPort?.close();
    _stopMonitoring();
    _stateSubscription?.cancel();
    _posSubscription?.cancel();
    _durSubscription?.cancel();
    _completeSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }
}

import 'dart:io';
import 'package:alhuda/core/services/adhan_audio_service.dart';
import 'package:alhuda/core/services/notification_services.dart';
import 'package:alhuda/features/prayer_times/data/models/adhan_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.example.alhuda/adhan'),
      (MethodCall methodCall) async => true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (MethodCall methodCall) async => true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );

    await NotificationServices.initializeNotifications();
  });

  group('Adhan Model & Service Tests', () {
    test('Default Adhan is Nasser Al-Qatami', () {
      expect(AdhanData.defaultAdhan.id, equals('qatami'));
      expect(AdhanData.defaultAdhan.title, contains('ناصر القطامي'));
      expect(AdhanData.defaultAdhan.sourceType, equals(AdhanAudioSourceType.asset));
      expect(AdhanData.defaultAdhan.source, equals('assets/audio/nasser_al_qatami.mp3'));
    });

    test('Available sounds list contains Nasser Al-Qatami and holy mosques', () {
      final sounds = AdhanData.availableSounds;
      expect(sounds.any((s) => s.id == 'qatami'), isTrue);
      expect(sounds.any((s) => s.id == 'makkah'), isTrue);
      expect(sounds.any((s) => s.id == 'madinah'), isTrue);
      expect(sounds.length, greaterThanOrEqualTo(6));
    });

    test('AdhanAudioService manages prayer alerts correctly and sunrise is strictly disabled', () {
      final service = AdhanAudioService();
      expect(service.isPrayerAlertEnabled('الفجر'), isTrue);
      expect(service.isPrayerAlertEnabled('الظهر'), isTrue);
      expect(service.isPrayerAlertEnabled('العصر'), isTrue);
      expect(service.isPrayerAlertEnabled('المغرب'), isTrue);
      expect(service.isPrayerAlertEnabled('العشاء'), isTrue);
      expect(service.isPrayerAlertEnabled('الشروق'), isFalse);

      // Sunrise toggle attempt should be ignored
      service.togglePrayerAlert('الشروق', true);
      expect(service.isPrayerAlertEnabled('الشروق'), isFalse);

      service.togglePrayerAlert('الفجر', false);
      expect(service.isPrayerAlertEnabled('الفجر'), isFalse);

      service.togglePrayerAlert('الفجر', true);
      expect(service.isPrayerAlertEnabled('الفجر'), isTrue);
    });

    test('Battery optimization methods work through MethodChannel', () async {
      final service = AdhanAudioService();
      expect(await service.isIgnoringBatteryOptimizations(), isTrue);
      expect(await service.requestIgnoreBatteryOptimizations(), isTrue);
      expect(await service.openAppSettings(), isTrue);
    });

    test('AdhanAudioService manages selected adhan sound', () {
      final service = AdhanAudioService();
      final makkah = AdhanData.availableSounds.firstWhere((s) => s.id == 'makkah');

      service.setSelectedAdhan(makkah);
      expect(service.selectedSound.id, equals('makkah'));

      // Restore to default
      service.setSelectedAdhan(AdhanData.defaultAdhan);
      expect(service.selectedSound.id, equals('qatami'));
    });

    test('AdhanAudioService manages volume correctly with clamping', () {
      final service = AdhanAudioService();
      expect(service.adhanVolume, greaterThanOrEqualTo(0.1));
      expect(service.adhanVolume, lessThanOrEqualTo(1.0));

      bool notified = false;
      void listener() => notified = true;
      service.addListener(listener);

      service.setAdhanVolume(0.8);
      expect(service.adhanVolume, closeTo(0.8, 0.001));
      expect(notified, isTrue);

      // Clamping test
      service.setAdhanVolume(1.5);
      expect(service.adhanVolume, equals(1.0));

      service.setAdhanVolume(0.01);
      expect(service.adhanVolume, equals(0.1));

      // Reset to 1.0
      service.setAdhanVolume(1.0);
      expect(service.adhanVolume, equals(1.0));

      service.removeListener(listener);
    });

    test('Available Adhan sounds list contains all Egyptian sheikhs and verified local asset files on disk', () {
      final sounds = AdhanData.availableSounds;
      expect(sounds.length, equals(16));
      expect(sounds.any((s) => s.id == 'rifaat'), isTrue);
      expect(sounds.any((s) => s.id == 'mostafa_ismail'), isTrue);
      expect(sounds.any((s) => s.id == 'abdulbasit'), isTrue);
      expect(sounds.any((s) => s.id == 'minshawi'), isTrue);
      expect(sounds.any((s) => s.id == 'shuaisha'), isTrue);
      expect(sounds.any((s) => s.id == 'hussary'), isTrue);
      expect(sounds.any((s) => s.id == 'mahmoud_ramadan'), isTrue);
      expect(sounds.any((s) => s.id == 'banna'), isTrue);

      for (final sound in sounds) {
        expect(sound.sourceType, equals(AdhanAudioSourceType.asset));
        final file = File(sound.source);
        expect(file.existsSync(), isTrue,
            reason: '${sound.source} must exist on disk');
        expect(file.lengthSync(), greaterThan(0),
            reason: '${sound.source} must not be empty');
      }
    });

    test('AdhanAudioService.stop() resets state correctly', () async {
      final service = AdhanAudioService();
      await service.stop();
      expect(service.currentPlayingSound, isNull);
      expect(service.isPlaying, isFalse);
      expect(service.position.inSeconds, equals(0));
    });

    test('MethodChannel stopAdhan call from Kotlin volume key invokes stop handler', () async {
      final service = AdhanAudioService();
      bool listenerNotified = false;
      void listener() {
        listenerNotified = true;
      }
      service.addListener(listener);

      // Simulate native volume button event calling 'stopAdhan' on MethodChannel
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final byteData = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('stopAdhan'),
      );
      await messenger.handlePlatformMessage(
        'com.example.alhuda/adhan',
        byteData,
        (ByteData? reply) {},
      );

      service.removeListener(listener);
      expect(service.isPlaying, isFalse);
      expect(listenerNotified, isTrue);
    });

    test('NotificationServices notification actions and handlers run safely', () {
      expect(NotificationServices.actionStopAdhan, equals('stop_adhan'));
      expect(NotificationServices.actionPauseAdhan, equals('pause_adhan'));
      expect(NotificationServices.actionResumeAdhan, equals('resume_adhan'));
      expect(NotificationServices.adhanControlPort, equals('adhan_control_port'));

      expect(() => NotificationServices.handleStopAdhanAction(), returnsNormally);
      expect(() => NotificationServices.handlePauseAdhanAction(), returnsNormally);
      expect(() => NotificationServices.handleResumeAdhanAction(), returnsNormally);
    });

    test('showAdhanControlNotification runs without error', () async {
      await expectLater(
        NotificationServices.showAdhanControlNotification(
          id: 1001,
          prayerName: 'الفجر',
          sound: AdhanData.defaultAdhan,
          isPlaying: true,
        ),
        completes,
      );

      await expectLater(
        NotificationServices.showAdhanControlNotification(
          id: 1001,
          prayerName: 'الفجر',
          sound: AdhanData.defaultAdhan,
          isPlaying: false,
        ),
        completes,
      );
    });

    test('showAdhanNotification and sendAdhanNotification run without error', () async {
      await expectLater(
        NotificationServices.showAdhanNotification(
          id: 1002,
          prayerName: 'الظهر',
          sound: AdhanData.defaultAdhan,
        ),
        completes,
      );

      await expectLater(
        NotificationServices.sendAdhanNotification(
          id: 1003,
          prayerName: 'العصر',
          sound: AdhanData.defaultAdhan,
        ),
        completes,
      );
    });
  });
}

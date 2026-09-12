import 'dart:io';
import 'package:alhuda/core/services/adhan_audio_service.dart';
import 'package:alhuda/core/services/notification_services.dart';
import 'package:alhuda/features/prayer_times/data/models/adhan_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
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

    test('AdhanAudioService manages prayer alerts correctly', () {
      final service = AdhanAudioService();
      expect(service.isPrayerAlertEnabled('الفجر'), isTrue);

      service.togglePrayerAlert('الفجر', false);
      expect(service.isPrayerAlertEnabled('الفجر'), isFalse);

      service.togglePrayerAlert('الفجر', true);
      expect(service.isPrayerAlertEnabled('الفجر'), isTrue);
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

    test('All 8 available Adhan sounds have verified local asset files on disk', () {
      final sounds = AdhanData.availableSounds;
      expect(sounds.length, equals(8));
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

    test('NotificationServices.actionStopAdhan is defined as stop_adhan and handleStopAdhanAction runs safely', () {
      expect(NotificationServices.actionStopAdhan, equals('stop_adhan'));
      expect(() => NotificationServices.handleStopAdhanAction(), returnsNormally);
    });
  });
}

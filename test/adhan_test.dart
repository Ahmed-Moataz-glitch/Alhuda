import 'dart:io';
import 'package:alhuda/model/adhan_model.dart';
import 'package:alhuda/view/widgets/adhan_audio_service.dart';
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
  });
}

import 'package:alhuda/services/quran_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quran Reciters Tests', () {
    test('QuranService reciters includes Tablawi, Mustafa Ismail, and Mohamed Rifaat', () {
      final reciters = QuranService.instance.reciters;
      expect(reciters.length, equals(25));

      final tablawi = reciters.firstWhere((r) => r.nameAr.contains('الطبلاوي'));
      expect(tablawi.nameAr, contains('محمد محمود الطبلاوي'));
      expect(tablawi.nameEn, equals('Mohammad Al-Tablaway'));
      expect(tablawi.path, equals('Mohammad_al_Tablaway_128kbps'));
      expect(tablawi.index, equals(22));

      final mustafaIsmail = reciters.firstWhere((r) => r.nameAr.contains('مصطفى إسماعيل'));
      expect(mustafaIsmail.nameAr, contains('مصطفى إسماعيل'));
      expect(mustafaIsmail.nameEn, equals('Mustafa Ismail'));
      expect(mustafaIsmail.path, equals('Mustafa_Ismail_48kbps'));
      expect(mustafaIsmail.index, equals(23));

      final rifaat = reciters.firstWhere((r) => r.nameAr.contains('محمد رفعت'));
      expect(rifaat.nameAr, contains('محمد رفعت'));
      expect(rifaat.nameEn, equals('Mohamed Rifaat'));
      expect(rifaat.index, equals(24));
    });

    test('AlhudaQuranAudioService initializes and manages reciters correctly', () {
      final audioService = AlhudaQuranAudioService.instance;
      expect(AlhudaQuranAudioService.reciters.length, equals(25));
      expect(audioService.state.value.isPlaying, isFalse);
    });
  });
}

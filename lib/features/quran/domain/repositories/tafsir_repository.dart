import 'package:alhuda/features/quran/domain/entities/tafsir_entities.dart';

abstract class TafsirRepository {
  List<TafsirSource> getAvailableTafsirs();
  Future<String> getTafsir({
    required TafsirSource source,
    required int surah,
    required int ayah,
  });
}

import 'package:alhuda/services/tafsir_service.dart';

class TafsirRepositoryImpl implements TafsirRepository {
  final TafsirService _service;

  TafsirRepositoryImpl({TafsirService? service})
      : _service = service ?? TafsirService.instance;

  @override
  List<TafsirSource> getAvailableTafsirs() => TafsirService.availableTafsirs;

  @override
  Future<String> getTafsir({
    required TafsirSource source,
    required int surah,
    required int ayah,
  }) {
    return _service.getTafsir(
      source: source,
      surah: surah,
      ayah: ayah,
    );
  }
}

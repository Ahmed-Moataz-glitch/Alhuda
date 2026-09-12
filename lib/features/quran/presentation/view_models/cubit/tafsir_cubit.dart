import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/tafsir_repository_impl.dart';
import '../../../domain/entities/tafsir_entities.dart';
import '../../../domain/repositories/tafsir_repository.dart';
import 'tafsir_state.dart';
export 'tafsir_state.dart';

class TafsirCubit extends Cubit<TafsirState> {
  final TafsirRepository _repository;

  TafsirCubit({TafsirRepository? repository})
      : _repository = repository ?? TafsirRepositoryImpl(),
        super(const TafsirState());

  bool get isLoading => state.isLoading;
  String? get errorMessage => state.errorMessage;
  String? get currentTafsirText => state.currentTafsirText;
  String get selectedTafsirId => state.selectedTafsirId;

  List<TafsirSource> get availableTafsirs =>
      _repository.getAvailableTafsirs();

  void selectTafsir(String tafsirId) {
    if (state.selectedTafsirId == tafsirId) return;
    emit(state.copyWith(selectedTafsirId: tafsirId));
  }

  Future<void> loadTafsir({
    required int surahNumber,
    required int ayahNumber,
    String? tafsirId,
  }) async {
    final id = tafsirId ?? state.selectedTafsirId;
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final source = availableTafsirs.firstWhere(
        (s) => s.id == id,
        orElse: () => availableTafsirs.first,
      );

      final text = await _repository.getTafsir(
        source: source,
        surah: surahNumber,
        ayah: ayahNumber,
      );
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, currentTafsirText: text));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'تعذر تحميل التفسير، يرجى المحاولة لاحقاً',
      ));
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/quran_repository_impl.dart';
import '../../domain/entities/quran_entities.dart';
import '../../domain/repositories/quran_repository.dart';
import 'quran_state.dart';
export 'quran_state.dart';

class QuranCubit extends Cubit<QuranState> {
  final QuranRepository _repository;

  QuranCubit({QuranRepository? repository})
      : _repository = repository ?? QuranRepositoryImpl(),
        super(const QuranState());

  bool get isLoading => state.isLoading;
  List<SurahData> get surahs => state.surahs;
  List<JuzData> get juzs => state.juzs;
  List<QuranBookmark> get bookmarks => state.bookmarks;
  LastReadPosition? get lastRead => state.lastRead;
  String get searchQuery => state.searchQuery;
  List<QuranSearchResult> get searchResults => state.searchResults;

  Future<void> loadInitialData() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final surahs = _repository.getAllSurahs();
      final juzs = _repository.getAllJuzs();
      final bookmarks = _repository.getBookmarks();
      final lastRead = _repository.lastRead;

      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        surahs: surahs,
        juzs: juzs,
        bookmarks: bookmarks,
        lastRead: lastRead,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void search(String query) {
    if (query.trim().isEmpty) {
      emit(state.copyWith(searchQuery: query, searchResults: const []));
    } else {
      final results = _repository.search(query);
      emit(state.copyWith(searchQuery: query, searchResults: results));
    }
  }

  void clearSearch() {
    emit(state.copyWith(searchQuery: '', searchResults: const []));
  }

  bool isBookmarked(int surahNumber, int ayahNumber) {
    return _repository.isBookmarked(surahNumber, ayahNumber);
  }

  Future<void> toggleBookmark(QuranBookmark bookmark) async {
    await _repository.toggleBookmark(
      surah: bookmark.surahNumber,
      surahName: bookmark.surahName,
      ayah: bookmark.ayahNumber,
      snippet: bookmark.snippet,
      pageNumber: bookmark.pageNumber,
    );
    final updated = _repository.getBookmarks();
    if (isClosed) return;
    emit(state.copyWith(bookmarks: updated));
  }

  Future<void> saveLastRead(LastReadPosition position) async {
    await _repository.setLastRead(
      surahNumber: position.surahNumber,
      surahName: position.surahName,
      ayahNumber: position.ayahNumber,
      pageNumber: position.pageNumber,
    );
    if (isClosed) return;
    emit(state.copyWith(lastRead: position));
  }
}

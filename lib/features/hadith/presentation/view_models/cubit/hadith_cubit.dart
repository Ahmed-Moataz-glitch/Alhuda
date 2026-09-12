import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/hadith_repository_impl.dart';
import '../../../domain/entities/hadith_entities.dart';
import '../../../domain/repositories/hadith_repository.dart';
import 'hadith_state.dart';
export 'hadith_state.dart';

class HadithCubit extends Cubit<HadithState> {
  final HadithRepository _repository;

  HadithCubit({HadithRepository? repository})
      : _repository = repository ?? HadithRepositoryImpl(),
        super(const HadithState());

  bool get isLoading => state.isLoading;
  List<HadithBook> get books => state.books;
  double get fontSize => state.fontSize;
  List<HadithBookmark> get bookmarks => state.bookmarks;

  void increaseFontSize() {
    if (state.fontSize < 32.0) {
      emit(state.copyWith(fontSize: state.fontSize + 2.0));
    }
  }

  void decreaseFontSize() {
    if (state.fontSize > 14.0) {
      emit(state.copyWith(fontSize: state.fontSize - 2.0));
    }
  }

  void resetFontSize() {
    emit(state.copyWith(fontSize: 20.0));
  }

  Future<void> loadBooks() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final books = await _repository.getAllBooks();
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, books: books));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<List<HadithChapter>> getChapters(String bookId) {
    return _repository.getChapters(bookId);
  }

  Future<List<HadithItem>> getChapterHadiths(String bookId, int chapterId) {
    return _repository.getChapterHadiths(bookId, chapterId);
  }

  Future<void> loadBookmarks() async {
    final bmarks = await _repository.getBookmarks();
    if (isClosed) return;
    emit(state.copyWith(bookmarks: bmarks));
  }

  bool isBookmarked(String bookId, int chapterId, int hadithNumber) {
    return _repository.isBookmarked(bookId, chapterId, hadithNumber);
  }

  Future<bool> toggleBookmark({
    required String bookId,
    required String bookTitle,
    required int chapterId,
    required String chapterTitle,
    required int hadithNumber,
    required String snippet,
  }) async {
    final res = await _repository.toggleBookmark(
      bookId: bookId,
      bookTitle: bookTitle,
      chapterId: chapterId,
      chapterTitle: chapterTitle,
      hadithNumber: hadithNumber,
      snippet: snippet,
    );
    final updated = await _repository.getBookmarks();
    if (!isClosed) {
      emit(state.copyWith(bookmarks: updated));
    }
    return res;
  }
}

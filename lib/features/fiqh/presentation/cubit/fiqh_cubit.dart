import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/fiqh_repository_impl.dart';
import '../../domain/entities/fiqh_entities.dart';
import '../../domain/repositories/fiqh_repository.dart';
import 'fiqh_state.dart';
export 'fiqh_state.dart';

class FiqhCubit extends Cubit<FiqhState> {
  final FiqhRepository _repository;

  FiqhCubit({FiqhRepository? repository})
      : _repository = repository ?? FiqhRepositoryImpl(),
        super(const FiqhState());

  bool get isLoading => state.isLoading;
  FiqhCategory? get selectedCategory => state.selectedCategory;
  String get searchQuery => state.searchQuery;
  List<FiqhSearchResult> get searchResults => state.searchResults;
  List<FiqhBookmark> get bookmarks => state.bookmarks;

  List<FiqhBook> get allBooks => _repository.getAllBooks();

  List<FiqhBook> get displayedBooks {
    if (state.selectedCategory == null) return allBooks;
    return _repository.getBooksByCategory(state.selectedCategory!);
  }

  List<({FiqhBook book, FiqhChapter chapter, FiqhIssue issue})>
      get featuredIssues => _repository.getFeaturedIssues();

  void selectCategory(FiqhCategory? category) {
    if (state.selectedCategory == category) return;
    emit(state.copyWith(
      selectedCategory: category,
      clearSelectedCategory: category == null,
    ));
  }

  void setSearchQuery(String query) {
    if (query.trim().isEmpty) {
      emit(state.copyWith(searchQuery: query, searchResults: const []));
    } else {
      final results = _repository.searchIssues(query);
      emit(state.copyWith(searchQuery: query, searchResults: results));
    }
  }

  void clearSearch() {
    emit(state.copyWith(searchQuery: '', searchResults: const []));
  }

  Future<void> loadBookmarks() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true));
    await _repository.ensureBookmarksLoaded();
    final bmarks = _repository.getBookmarks();
    if (isClosed) return;
    emit(state.copyWith(isLoading: false, bookmarks: bmarks));
  }

  bool isBookmarked(String issueId) => _repository.isBookmarked(issueId);

  Future<bool> toggleBookmark({
    required FiqhBook book,
    required FiqhChapter chapter,
    required FiqhIssue issue,
  }) async {
    final result = await _repository.toggleBookmark(
      book: book,
      chapter: chapter,
      issue: issue,
    );
    final updated = _repository.getBookmarks();
    if (!isClosed) {
      emit(state.copyWith(bookmarks: updated));
    }
    return result;
  }
}

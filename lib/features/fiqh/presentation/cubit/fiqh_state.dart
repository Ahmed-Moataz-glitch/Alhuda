import 'package:equatable/equatable.dart';
import '../../domain/entities/fiqh_entities.dart';

class FiqhState extends Equatable {
  final bool isLoading;
  final FiqhCategory? selectedCategory;
  final String searchQuery;
  final List<FiqhSearchResult> searchResults;
  final List<FiqhBookmark> bookmarks;
  final String? errorMessage;

  const FiqhState({
    this.isLoading = false,
    this.selectedCategory,
    this.searchQuery = '',
    this.searchResults = const [],
    this.bookmarks = const [],
    this.errorMessage,
  });

  FiqhState copyWith({
    bool? isLoading,
    FiqhCategory? selectedCategory,
    bool clearSelectedCategory = false,
    String? searchQuery,
    List<FiqhSearchResult>? searchResults,
    List<FiqhBookmark>? bookmarks,
    String? errorMessage,
  }) {
    return FiqhState(
      isLoading: isLoading ?? this.isLoading,
      selectedCategory:
          clearSelectedCategory ? null : (selectedCategory ?? this.selectedCategory),
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      bookmarks: bookmarks ?? this.bookmarks,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        selectedCategory,
        searchQuery,
        searchResults,
        bookmarks,
        errorMessage,
      ];
}

import 'package:equatable/equatable.dart';
import '../../../domain/entities/quran_entities.dart';

class QuranState extends Equatable {
  final bool isLoading;
  final List<SurahData> surahs;
  final List<JuzData> juzs;
  final List<QuranBookmark> bookmarks;
  final LastReadPosition? lastRead;
  final String searchQuery;
  final List<QuranSearchResult> searchResults;
  final String? errorMessage;

  const QuranState({
    this.isLoading = false,
    this.surahs = const [],
    this.juzs = const [],
    this.bookmarks = const [],
    this.lastRead,
    this.searchQuery = '',
    this.searchResults = const [],
    this.errorMessage,
  });

  QuranState copyWith({
    bool? isLoading,
    List<SurahData>? surahs,
    List<JuzData>? juzs,
    List<QuranBookmark>? bookmarks,
    LastReadPosition? lastRead,
    String? searchQuery,
    List<QuranSearchResult>? searchResults,
    String? errorMessage,
  }) {
    return QuranState(
      isLoading: isLoading ?? this.isLoading,
      surahs: surahs ?? this.surahs,
      juzs: juzs ?? this.juzs,
      bookmarks: bookmarks ?? this.bookmarks,
      lastRead: lastRead ?? this.lastRead,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        surahs,
        juzs,
        bookmarks,
        lastRead,
        searchQuery,
        searchResults,
        errorMessage,
      ];
}

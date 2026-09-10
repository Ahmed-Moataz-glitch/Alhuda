import 'package:equatable/equatable.dart';
import '../../domain/entities/hadith_entities.dart';

class HadithState extends Equatable {
  final bool isLoading;
  final List<HadithBook> books;
  final double fontSize;
  final List<HadithBookmark> bookmarks;
  final String? errorMessage;

  const HadithState({
    this.isLoading = true,
    this.books = const [],
    this.fontSize = 20.0,
    this.bookmarks = const [],
    this.errorMessage,
  });

  HadithState copyWith({
    bool? isLoading,
    List<HadithBook>? books,
    double? fontSize,
    List<HadithBookmark>? bookmarks,
    String? errorMessage,
  }) {
    return HadithState(
      isLoading: isLoading ?? this.isLoading,
      books: books ?? this.books,
      fontSize: fontSize ?? this.fontSize,
      bookmarks: bookmarks ?? this.bookmarks,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        books,
        fontSize,
        bookmarks,
        errorMessage,
      ];
}

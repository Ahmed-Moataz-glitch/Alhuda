import 'package:equatable/equatable.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';
import '../../../domain/entities/azkar_quick_item.dart';

class AzkarState extends Equatable {
  final bool isLoading;
  final List<AzkarCategory> categories;
  final List<AzkarChapter> allChapters;
  final int selectedCategoryId; // -1 means All
  final String searchQuery;
  final List<AzkarQuickItem> quickAzkarList;
  final String? errorMessage;

  const AzkarState({
    this.isLoading = true,
    this.categories = const [],
    this.allChapters = const [],
    this.selectedCategoryId = -1,
    this.searchQuery = '',
    this.quickAzkarList = const [],
    this.errorMessage,
  });

  AzkarState copyWith({
    bool? isLoading,
    List<AzkarCategory>? categories,
    List<AzkarChapter>? allChapters,
    int? selectedCategoryId,
    String? searchQuery,
    List<AzkarQuickItem>? quickAzkarList,
    String? errorMessage,
  }) {
    return AzkarState(
      isLoading: isLoading ?? this.isLoading,
      categories: categories ?? this.categories,
      allChapters: allChapters ?? this.allChapters,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      quickAzkarList: quickAzkarList ?? this.quickAzkarList,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        categories,
        allChapters,
        selectedCategoryId,
        searchQuery,
        quickAzkarList,
        errorMessage,
      ];
}

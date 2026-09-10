import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';
import '../../data/repositories/azkar_repository_impl.dart';
import '../../domain/entities/azkar_quick_item.dart';
import '../../domain/repositories/azkar_repository.dart';
import 'azkar_state.dart';
export 'azkar_state.dart';

class AzkarCubit extends Cubit<AzkarState> {
  final AzkarRepository _repository;

  AzkarCubit({AzkarRepository? repository})
      : _repository = repository ?? AzkarRepositoryImpl(),
        super(const AzkarState());

  bool get isLoading => state.isLoading;
  List<AzkarCategory> get categories => state.categories;
  List<AzkarChapter> get allChapters => state.allChapters;
  int get selectedCategoryId => state.selectedCategoryId;
  String get searchQuery => state.searchQuery;
  List<AzkarQuickItem> get quickAzkarList =>
      state.quickAzkarList.isNotEmpty
          ? state.quickAzkarList
          : _repository.getQuickAzkarList();

  List<AzkarChapter> get filteredChapters {
    List<AzkarChapter> list = state.allChapters;

    if (state.selectedCategoryId != -1) {
      list = list.where((ch) => ch.categoryId == state.selectedCategoryId).toList();
    }

    if (state.searchQuery.trim().isNotEmpty) {
      list = _repository.filterChapters(list, state.searchQuery);
    }

    return list;
  }

  Future<void> loadInitialData() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final categories = await _repository.getCategories();
      final chapters = await _repository.getAllChapters();
      final quickList = _repository.getQuickAzkarList();
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        categories: categories,
        allChapters: chapters,
        quickAzkarList: quickList,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void selectCategory(int categoryId) {
    if (state.selectedCategoryId == categoryId) return;
    emit(state.copyWith(selectedCategoryId: categoryId));
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void clearSearch() {
    emit(state.copyWith(searchQuery: ''));
  }

  Future<List<AzkarItem>> getAzkarItems(int chapterId) {
    return _repository.getAzkarItems(chapterId);
  }
}

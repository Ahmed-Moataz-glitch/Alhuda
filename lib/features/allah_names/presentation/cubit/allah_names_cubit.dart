import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/allah_names_repository_impl.dart';
import '../../domain/entities/allah_name_entity.dart';
import '../../domain/repositories/allah_names_repository.dart';
import 'allah_names_state.dart';
export 'allah_names_state.dart';

class AllahNamesCubit extends Cubit<AllahNamesState> {
  final AllahNamesRepository _repository;

  AllahNamesCubit({AllahNamesRepository? repository})
      : _repository = repository ?? AllahNamesRepositoryImpl(),
        super(const AllahNamesState());

  bool get isLoading => state.isLoading;
  List<AllahNameEntity> get allNames => state.allNames;
  String get searchQuery => state.searchQuery;
  bool get favoritesOnly => state.favoritesOnly;
  AllahNameEntity? get nameOfTheDay => state.nameOfTheDay;
  int get favoritesCount => state.favoritesCount;

  List<AllahNameEntity> get filteredNames {
    return _repository.filterNames(
      state.allNames,
      query: state.searchQuery,
      favoritesOnly: state.favoritesOnly,
    );
  }

  Future<void> loadNames() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final names = await _repository.getAllNames();
      final nameOfTheDay = _repository.getNameOfTheDay(names);
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        allNames: names,
        nameOfTheDay: nameOfTheDay,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void clearSearch() {
    emit(state.copyWith(searchQuery: ''));
  }

  void toggleFavoritesFilter() {
    emit(state.copyWith(favoritesOnly: !state.favoritesOnly));
  }

  void setFavoritesFilter(bool value) {
    emit(state.copyWith(favoritesOnly: value));
  }

  Future<void> toggleFavorite(int nameId) async {
    final willBeFav = await _repository.toggleFavorite(nameId);
    final updatedList = state.allNames.map((item) {
      if (item.id == nameId) {
        return item.copyWith(isFavorite: willBeFav);
      }
      return item;
    }).toList();

    AllahNameEntity? updatedNotd = state.nameOfTheDay;
    if (updatedNotd?.id == nameId) {
      updatedNotd = updatedNotd?.copyWith(isFavorite: willBeFav);
    }

    if (isClosed) return;
    emit(state.copyWith(
      allNames: updatedList,
      nameOfTheDay: updatedNotd,
    ));
  }
}

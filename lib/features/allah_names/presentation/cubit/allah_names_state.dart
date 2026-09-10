import 'package:equatable/equatable.dart';
import '../../domain/entities/allah_name_entity.dart';

class AllahNamesState extends Equatable {
  final bool isLoading;
  final List<AllahNameEntity> allNames;
  final String searchQuery;
  final bool favoritesOnly;
  final AllahNameEntity? nameOfTheDay;
  final String? errorMessage;

  const AllahNamesState({
    this.isLoading = true,
    this.allNames = const [],
    this.searchQuery = '',
    this.favoritesOnly = false,
    this.nameOfTheDay,
    this.errorMessage,
  });

  int get favoritesCount => allNames.where((n) => n.isFavorite).length;

  AllahNamesState copyWith({
    bool? isLoading,
    List<AllahNameEntity>? allNames,
    String? searchQuery,
    bool? favoritesOnly,
    AllahNameEntity? nameOfTheDay,
    String? errorMessage,
  }) {
    return AllahNamesState(
      isLoading: isLoading ?? this.isLoading,
      allNames: allNames ?? this.allNames,
      searchQuery: searchQuery ?? this.searchQuery,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      nameOfTheDay: nameOfTheDay ?? this.nameOfTheDay,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        allNames,
        searchQuery,
        favoritesOnly,
        nameOfTheDay,
        errorMessage,
      ];
}

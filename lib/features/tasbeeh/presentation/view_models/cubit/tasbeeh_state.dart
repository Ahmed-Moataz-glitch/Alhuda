import 'package:equatable/equatable.dart';
import '../../../domain/entities/tasbeeh_item.dart';

class TasbeehState extends Equatable {
  final List<TasbeehItem> items;
  final int currentIndex;
  final int counter;
  final int totalCount;

  const TasbeehState({
    this.items = const [],
    this.currentIndex = 0,
    this.counter = 0,
    this.totalCount = 0,
  });

  TasbeehItem get currentItem =>
      (items.isNotEmpty && currentIndex >= 0 && currentIndex < items.length)
          ? items[currentIndex]
          : const TasbeehItem(id: 0, text: '');

  TasbeehState copyWith({
    List<TasbeehItem>? items,
    int? currentIndex,
    int? counter,
    int? totalCount,
  }) {
    return TasbeehState(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      counter: counter ?? this.counter,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  List<Object?> get props => [
        items,
        currentIndex,
        counter,
        totalCount,
      ];
}

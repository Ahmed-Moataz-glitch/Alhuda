import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/tasbeeh_repository_impl.dart';
import '../../../domain/entities/tasbeeh_item.dart';
import '../../../domain/repositories/tasbeeh_repository.dart';
import 'tasbeeh_state.dart';
export 'tasbeeh_state.dart';

class TasbeehCubit extends Cubit<TasbeehState> {
  final TasbeehRepository _repository;

  TasbeehCubit({TasbeehRepository? repository})
      : _repository = repository ?? TasbeehRepositoryImpl(),
        super(const TasbeehState()) {
    init();
  }

  void init() {
    final defaultItems = _repository.getDefaultItems();
    emit(state.copyWith(items: defaultItems));
  }

  List<TasbeehItem> get items => state.items;
  int get currentIndex => state.currentIndex;
  int get counter => state.counter;
  int get totalCount => state.totalCount;
  TasbeehItem get currentItem => state.currentItem;

  void increment() {
    final newCounter = state.counter + 1;
    final newTotal = state.totalCount + 1;

    if (state.items.isNotEmpty && newCounter >= state.currentItem.targetCount) {
      final nextIdx = (state.currentIndex + 1) % state.items.length;
      emit(state.copyWith(
        counter: 0,
        totalCount: newTotal,
        currentIndex: nextIdx,
      ));
    } else {
      emit(state.copyWith(
        counter: newCounter,
        totalCount: newTotal,
      ));
    }
  }

  void resetCounter() {
    emit(state.copyWith(counter: 0));
  }

  void nextItem() {
    if (state.items.isEmpty) return;
    final nextIdx = (state.currentIndex + 1) % state.items.length;
    emit(state.copyWith(
      currentIndex: nextIdx,
      counter: 0,
    ));
  }

  void previousItem() {
    if (state.items.isEmpty) return;
    final prevIdx = (state.currentIndex - 1 + state.items.length) % state.items.length;
    emit(state.copyWith(
      currentIndex: prevIdx,
      counter: 0,
    ));
  }

  void selectItem(int index) {
    if (index >= 0 && index < state.items.length) {
      emit(state.copyWith(
        currentIndex: index,
        counter: 0,
      ));
    }
  }
}

import 'package:alhuda/features/tasbeeh/data/repositories/tasbeeh_repository_impl.dart';
import 'package:alhuda/features/tasbeeh/presentation/view_models/tasbeeh_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tasbeeh Clean Architecture Tests', () {
    test('TasbeehRepositoryImpl returns authentic items', () {
      final repo = TasbeehRepositoryImpl();
      final items = repo.getDefaultItems();
      expect(items.length, greaterThanOrEqualTo(9));
      expect(items.first.text, contains('سبحان الله'));
    });

    test('TasbeehViewModel increments count and advances item', () {
      final vm = TasbeehViewModel();
      expect(vm.counter, equals(0));
      expect(vm.totalCount, equals(0));

      vm.increment();
      expect(vm.counter, equals(1));
      expect(vm.totalCount, equals(1));

      vm.resetCounter();
      expect(vm.counter, equals(0));
      expect(vm.totalCount, equals(1));

      vm.nextItem();
      expect(vm.currentIndex, equals(1));

      vm.previousItem();
      expect(vm.currentIndex, equals(0));
    });
  });
}

import 'package:alhuda/features/tasbeeh/domain/entities/tasbeeh_item.dart';

abstract class TasbeehRepository {
  List<TasbeehItem> getDefaultItems();
}

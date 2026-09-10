import 'package:alhuda/features/tasbeeh/domain/entities/tasbeeh_item.dart';
import 'package:alhuda/features/tasbeeh/domain/repositories/tasbeeh_repository.dart';

class TasbeehRepositoryImpl implements TasbeehRepository {
  static const List<TasbeehItem> _defaults = [
    TasbeehItem(id: 1, text: 'سبحان الله وبحمده سبحان الله العظيم'),
    TasbeehItem(id: 2, text: 'لا حول ولا قوة إلا بالله'),
    TasbeehItem(id: 3, text: 'سبحان الله والحمد لله ولا إله إلا الله والله أكبر'),
    TasbeehItem(id: 4, text: 'أستغفر الله وأتوب إليه'),
    TasbeehItem(id: 5, text: 'اللهم صل وسلم على نبينا محمد'),
    TasbeehItem(id: 6, text: 'سبحان الله'),
    TasbeehItem(id: 7, text: 'الحمد لله'),
    TasbeehItem(id: 8, text: 'لا إله إلا الله'),
    TasbeehItem(id: 9, text: 'الله أكبر'),
  ];

  @override
  List<TasbeehItem> getDefaultItems() => List.unmodifiable(_defaults);
}

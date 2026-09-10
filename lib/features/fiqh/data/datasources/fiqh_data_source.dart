import 'package:alhuda/features/fiqh/domain/entities/fiqh_entities.dart';
import 'package:alhuda/services/fiqh_data.dart';

abstract class FiqhDataSource {
  List<FiqhBook> getBooks();
}

class FiqhLocalDataSource implements FiqhDataSource {
  @override
  List<FiqhBook> getBooks() {
    return FiqhData.getBooks();
  }
}

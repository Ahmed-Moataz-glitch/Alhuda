import '../cubit/hadith_cubit.dart';

export '../cubit/hadith_cubit.dart';
export '../cubit/hadith_state.dart';

/// ViewModel for Hadith feature backed by [HadithCubit].
class HadithViewModel extends HadithCubit {
  HadithViewModel({super.repository});
}

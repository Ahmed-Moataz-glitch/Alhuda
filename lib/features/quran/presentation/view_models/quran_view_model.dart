import '../cubit/quran_cubit.dart';

export '../cubit/quran_cubit.dart';
export '../cubit/quran_state.dart';

/// ViewModel for Quran feature backed by [QuranCubit].
class QuranViewModel extends QuranCubit {
  QuranViewModel({super.repository});
}

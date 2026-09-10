import '../cubit/fiqh_cubit.dart';

export '../cubit/fiqh_cubit.dart';
export '../cubit/fiqh_state.dart';

/// ViewModel for Fiqh feature backed by [FiqhCubit].
class FiqhViewModel extends FiqhCubit {
  FiqhViewModel({super.repository});
}

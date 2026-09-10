import '../cubit/azkar_cubit.dart';

export '../cubit/azkar_cubit.dart';
export '../cubit/azkar_state.dart';

/// ViewModel for Azkar feature backed by [AzkarCubit].
class AzkarViewModel extends AzkarCubit {
  AzkarViewModel({super.repository});
}

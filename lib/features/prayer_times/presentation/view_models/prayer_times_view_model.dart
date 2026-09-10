import '../cubit/prayer_times_cubit.dart';

export '../cubit/prayer_times_cubit.dart';
export '../cubit/prayer_times_state.dart';

/// ViewModel for Prayer Times feature backed by [PrayerTimesCubit].
class PrayerTimesViewModel extends PrayerTimesCubit {
  PrayerTimesViewModel({super.repository});
}

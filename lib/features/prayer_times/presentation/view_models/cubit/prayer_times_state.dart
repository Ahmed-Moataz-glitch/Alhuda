import 'package:equatable/equatable.dart';
import 'package:muslim_data_flutter/muslim_data_flutter.dart';
import '../../../../../core/utils/egypt_dst_helper.dart';

class PrayerTimesState extends Equatable {
  final bool isLoading;
  final PrayerTime? rawPrayerTime;
  final PrayerTime? adjustedPrayerTime;
  final DateTime currentDate;
  final Location currentLocation;
  final CalculationMethod calculationMethod;
  final EgyptDstMode dstMode;
  final String? errorMessage;

  const PrayerTimesState({
    this.isLoading = false,
    this.rawPrayerTime,
    this.adjustedPrayerTime,
    required this.currentDate,
    required this.currentLocation,
    this.calculationMethod = CalculationMethod.egypt,
    this.dstMode = EgyptDstMode.auto,
    this.errorMessage,
  });

  PrayerTime? get prayerTime => adjustedPrayerTime;

  PrayerTimesState copyWith({
    bool? isLoading,
    PrayerTime? rawPrayerTime,
    PrayerTime? adjustedPrayerTime,
    DateTime? currentDate,
    Location? currentLocation,
    CalculationMethod? calculationMethod,
    EgyptDstMode? dstMode,
    String? errorMessage,
  }) {
    return PrayerTimesState(
      isLoading: isLoading ?? this.isLoading,
      rawPrayerTime: rawPrayerTime ?? this.rawPrayerTime,
      adjustedPrayerTime: adjustedPrayerTime ?? this.adjustedPrayerTime,
      currentDate: currentDate ?? this.currentDate,
      currentLocation: currentLocation ?? this.currentLocation,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      dstMode: dstMode ?? this.dstMode,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        rawPrayerTime,
        adjustedPrayerTime,
        currentDate,
        currentLocation,
        calculationMethod,
        dstMode,
        errorMessage,
      ];
}

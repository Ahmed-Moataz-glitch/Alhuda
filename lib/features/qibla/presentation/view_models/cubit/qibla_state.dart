import 'package:equatable/equatable.dart';
import '../../../domain/entities/qibla_data.dart';

class QiblaState extends Equatable {
  final double latitude;
  final double longitude;
  final String cityName;
  final QiblaData? qiblaData;
  final double currentHeading;
  final bool isFacing;
  final bool isSensorlessMode;
  final bool isLoading;
  final String? errorMessage;

  const QiblaState({
    this.latitude = 30.0444, // Default Cairo
    this.longitude = 31.2357,
    this.cityName = 'القاهرة',
    this.qiblaData,
    this.currentHeading = 0.0,
    this.isFacing = false,
    this.isSensorlessMode = false,
    this.isLoading = false,
    this.errorMessage,
  });

  QiblaState copyWith({
    double? latitude,
    double? longitude,
    String? cityName,
    QiblaData? qiblaData,
    double? currentHeading,
    bool? isFacing,
    bool? isSensorlessMode,
    bool? isLoading,
    String? errorMessage,
  }) {
    return QiblaState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      cityName: cityName ?? this.cityName,
      qiblaData: qiblaData ?? this.qiblaData,
      currentHeading: currentHeading ?? this.currentHeading,
      isFacing: isFacing ?? this.isFacing,
      isSensorlessMode: isSensorlessMode ?? this.isSensorlessMode,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        cityName,
        qiblaData,
        currentHeading,
        isFacing,
        isSensorlessMode,
        isLoading,
        errorMessage,
      ];
}

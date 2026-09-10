import 'package:equatable/equatable.dart';

class TafsirState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final String? currentTafsirText;
  final String selectedTafsirId;

  const TafsirState({
    this.isLoading = false,
    this.errorMessage,
    this.currentTafsirText,
    this.selectedTafsirId = 'muyassar',
  });

  TafsirState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? currentTafsirText,
    String? selectedTafsirId,
  }) {
    return TafsirState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      currentTafsirText: currentTafsirText ?? this.currentTafsirText,
      selectedTafsirId: selectedTafsirId ?? this.selectedTafsirId,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        currentTafsirText,
        selectedTafsirId,
      ];
}

abstract class WritePoemState {}

class WritePoemInitial extends WritePoemState {}

class WritePoemGenerating extends WritePoemState {}

class WritePoemGenerated extends WritePoemState {
  final String lines;
  WritePoemGenerated({required this.lines});
}

class WritePoemSaved extends WritePoemState {}

class WritePoemError extends WritePoemState {
  final String message;
  WritePoemError({required this.message});
}

class ShowSuccessAnimationState extends WritePoemState {}
class WritePoemValidationState extends WritePoemState {
  final String? titleError;
  final String? poemError;

  WritePoemValidationState({this.titleError, this.poemError});
}

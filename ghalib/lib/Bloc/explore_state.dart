abstract class ExploreState {}

class ExploreInitial extends ExploreState {}

class ExploreLoading extends ExploreState {}

class ExploreLoaded extends ExploreState {
  final Map<String, dynamic> poem;

  ExploreLoaded({required this.poem});
}

class ExploreError extends ExploreState {
  final String message;

  ExploreError({required this.message});
}

class SearchHistoryLoaded extends ExploreState {
  final List<String> history;
  SearchHistoryLoaded({required this.history});
}

class ExploreValidationState extends ExploreState {
  final String? titleError;
  final String? authorError;
  final String? lineError;
  final List<String> history;

  ExploreValidationState({
    this.titleError,
    this.authorError,
    this.lineError,
    required this.history,
  });
}


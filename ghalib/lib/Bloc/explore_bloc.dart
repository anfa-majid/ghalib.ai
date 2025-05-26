import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/poem_service.dart';
import '../Bloc/explore_event.dart';
import '../Bloc/explore_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExploreBloc extends Bloc<ExploreEvent, ExploreState> {
  List<String> _history = [];

  ExploreBloc() : super(ExploreInitial()) {
    on<SearchByTitleAndAuthor>(_onSearchByTitleAndAuthor);
    on<SearchByLine>(_onSearchByLine);
    on<ResetExplore>(_onResetExplore);
    on<LoadSearchHistory>(_onLoadSearchHistory);
    on<AddSearchHistory>(_onAddSearchHistory);
    on<RemoveSearchHistoryEntry>(_onRemoveEntry);
    on<ClearSearchHistory>(_onClearSearchHistory);
  }

  Future<void> _onSearchByTitleAndAuthor(
    SearchByTitleAndAuthor event,
    Emitter<ExploreState> emit,
  ) async {
    final trimmedTitle = event.title.trim();
    final trimmedAuthor = event.author.trim();

    if (trimmedTitle.isEmpty || trimmedAuthor.isEmpty) {
      emit(ExploreValidationState(
        titleError: trimmedTitle.isEmpty ? "Please enter a title" : null,
        authorError: trimmedAuthor.isEmpty ? "Please enter an author" : null,
        history: _history,
      ));
      return;
    }

    emit(ExploreLoading());

    try {
      final result = await PoetryService.searchPoemByTitleAndAuthor(
          trimmedTitle, trimmedAuthor);
      if (result != null) {
        emit(ExploreLoaded(poem: result));
      } else {
        emit(ExploreError(
            message: "No poem found with that title and author."));
      }
    } catch (e) {
      emit(ExploreError(message: "An error occurred: ${e.toString()}"));
    }
  }

  Future<void> _onSearchByLine(
    SearchByLine event,
    Emitter<ExploreState> emit,
  ) async {
    final trimmedLine = event.line.trim();

    if (trimmedLine.isEmpty) {
      emit(ExploreValidationState(
        lineError: "Please enter a line",
        history: _history,
      ));
      return;
    }

    emit(ExploreLoading());

    try {
      final result = await PoetryService.searchPoemByLine(trimmedLine);
      if (result != null) {
        emit(ExploreLoaded(poem: result));
      } else {
        emit(ExploreError(message: "No poem found containing that line."));
      }
    } catch (e) {
      emit(ExploreError(message: "An error occurred: ${e.toString()}"));
    }
  }

  void _onResetExplore(
    ResetExplore event,
    Emitter<ExploreState> emit,
  ) {
    emit(ExploreInitial());
  }

  Future<void> _onLoadSearchHistory(
    LoadSearchHistory event,
    Emitter<ExploreState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    _history = prefs.getStringList('searchHistory') ?? [];
    emit(SearchHistoryLoaded(history: _history));
  }

  Future<void> _onAddSearchHistory(
    AddSearchHistory event,
    Emitter<ExploreState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    _history = [event.entry, ..._history].toSet().take(10).toList();
    await prefs.setStringList('searchHistory', _history);
    emit(SearchHistoryLoaded(history: _history));
  }

  Future<void> _onRemoveEntry(
    RemoveSearchHistoryEntry event,
    Emitter<ExploreState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    _history.remove(event.entry);
    await prefs.setStringList('searchHistory', _history);
    emit(SearchHistoryLoaded(history: _history));
  }

  Future<void> _onClearSearchHistory(
    ClearSearchHistory event,
    Emitter<ExploreState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('searchHistory');
    _history.clear();
    emit(SearchHistoryLoaded(history: _history));
  }
}

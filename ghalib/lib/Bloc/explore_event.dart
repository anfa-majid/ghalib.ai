abstract class ExploreEvent {}

class SearchByTitleAndAuthor extends ExploreEvent {
  final String title;
  final String author;

  SearchByTitleAndAuthor({required this.title, required this.author});
}

class SearchByLine extends ExploreEvent {
  final String line;

  SearchByLine({required this.line});
}

class ResetExplore extends ExploreEvent {}

class LoadSearchHistory extends ExploreEvent {}

class AddSearchHistory extends ExploreEvent {
  final String entry;
  AddSearchHistory(this.entry);
}

class RemoveSearchHistoryEntry extends ExploreEvent {
  final String entry;
  RemoveSearchHistoryEntry(this.entry);
}

class ClearSearchHistory extends ExploreEvent {}

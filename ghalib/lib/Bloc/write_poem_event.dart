abstract class WritePoemEvent {}

class GenerateStarterLinesEvent extends WritePoemEvent {
  final String mood;
  GenerateStarterLinesEvent({required this.mood});
}

class SavePoemEvent extends WritePoemEvent {
  final String title;
  final String author;
  final String mood;
  final String content;

  SavePoemEvent({
    required this.title,
    required this.author,
    required this.mood,
    required this.content,
  });
}

class ChangeMoodEvent extends WritePoemEvent {
  final String mood;
  ChangeMoodEvent({required this.mood});
}

class ToggleAiStarterEvent extends WritePoemEvent {
  final bool enabled;
  ToggleAiStarterEvent({required this.enabled});
}

class TriggerSuccessAnimationEvent extends WritePoemEvent {}
class WritePoemReset extends WritePoemEvent {}

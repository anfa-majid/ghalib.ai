import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'write_poem_state.dart';
import '../services/poem_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'write_poem_event.dart';
import '../model/poem_model.dart';

class WritePoemBloc extends Bloc<WritePoemEvent, WritePoemState> {
  final titleController = TextEditingController();
  final poemController = TextEditingController();
  String selectedMood = 'Love';
  bool aiStarterSelected = false;

  final moods = [
    'Love', 'Sadness', 'Hope', 'Nostalgia', 'Freedom',
    'Happiness', 'Longing', 'Dreams', 'Spiritual'
  ];

  WritePoemBloc() : super(WritePoemInitial()) {
    on<GenerateStarterLinesEvent>(_onGenerateStarterLines);

    on<SavePoemEvent>((event, emit) async {
      final title = event.title.trim();
      final content = event.content.trim();

      if (title.isEmpty || content.isEmpty) {
        emit(WritePoemValidationState(
          titleError: title.isEmpty ? "Please enter a title" : null,
          poemError: content.isEmpty ? "Please write your poem" : null,
        ));
        return;
      }

      try {
        // Create a temporary poem object for consistency
        final newPoem = Poem(
          id: '', // Will be assigned by Firestore
          title: title,
          author: event.author,
          content: content,
          createdAt: DateTime.now(),
          highlightLine: content.split('\n').where((line) => line.trim().isNotEmpty).first,
          isPoetryOfTheDay: false,
          moodTag: event.mood,
          stanza: content.split('\n').take(4).where((line) => line.trim().isNotEmpty).join('\n'),
        );

        // Save using the poem model structure
        await FirebaseFirestore.instance.collection('poem').add({
          'title': newPoem.title,
          'author': newPoem.author,
          'moodTag': newPoem.moodTag,
          'content': newPoem.content,
          'stanza': newPoem.stanza,
          'highlightLine': newPoem.highlightLine,
          'isPoetryOfTheDay': newPoem.isPoetryOfTheDay,
          'createdAt': FieldValue.serverTimestamp(),
        });

        emit(WritePoemSaved());
        emit(ShowSuccessAnimationState());
      } catch (e) {
        emit(WritePoemError(message: "Failed to save poem: $e"));
      }
    });

    on<WritePoemReset>((event, emit) {
      clearInputs();
      emit(WritePoemInitial());
    });

    on<ChangeMoodEvent>((event, emit) {
      selectedMood = event.mood;
    });

    on<ToggleAiStarterEvent>((event, emit) {
      aiStarterSelected = event.enabled;
    });

    on<TriggerSuccessAnimationEvent>((event, emit) async {
      emit(ShowSuccessAnimationState());
      await Future.delayed(const Duration(seconds: 2));
      clearInputs();
      emit(WritePoemInitial());
    });
  }

  Future<void> _onGenerateStarterLines(
    GenerateStarterLinesEvent event,
    Emitter<WritePoemState> emit,
  ) async {
    emit(WritePoemGenerating());
    try {
      final lines = await PoetryService.generateStarterLines(event.mood);
      emit(WritePoemGenerated(lines: lines));
    } catch (e) {
      emit(WritePoemError(message: e.toString()));
    }
  }

  void clearInputs() {
    titleController.clear();
    poemController.clear();
    aiStarterSelected = false;
    selectedMood = 'Love';
  }
}

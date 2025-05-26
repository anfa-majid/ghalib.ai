import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'my_poems_event.dart';
import 'my_poems_state.dart';

class MyPoemsBloc extends Bloc<MyPoemsEvent, MyPoemsState> {
  MyPoemsBloc() : super(MyPoemsInitial()) {
    on<LoadMyPoems>((event, emit) async {
      emit(MyPoemsLoading());
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('poem')
            .where('author', isEqualTo: event.userEmail.trim().toLowerCase())
            .orderBy('createdAt', descending: true)
            .get();

        final poems = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'title': data['title'] ?? 'Untitled',
            'author': data['author'] ?? 'Unknown',
            'mood': data['moodTag'] ?? 'unknown',
            'stanza': data['stanza'] ?? '',
            'fullPoem': data['content'] ?? '',
          };
        }).toList();

        emit(MyPoemsLoaded(poems));
      } catch (e) {
        emit(MyPoemsError("Failed to load poems"));
      }
    });

    on<DeletePoem>((event, emit) async {
      try {
        await FirebaseFirestore.instance.collection('poem').doc(event.poemId).delete();
        print("Poem deleted: ${event.poemId}");
        add(LoadMyPoems(event.userEmail));
      } catch (e) {
        emit(MyPoemsError("Failed to delete poem."));
      }
    });

    on<LoadMyPoemsFromCache>((event, emit) {
      emit(MyPoemsLoaded(event.poems));
    });
  }
}

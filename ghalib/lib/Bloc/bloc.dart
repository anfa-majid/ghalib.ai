import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/auth_repository.dart';
import 'event.dart';
import 'state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<AppStarted>((event, emit) async {
  await Future.delayed(Duration(milliseconds: 100)); 
  final user = authRepository.getCurrentUser();

  if (user != null) {
    print("Firebase restored user session");
    emit(Authenticated());
  } else {
    print("No user session found");
    emit(Unauthenticated());
  }
});


    // Handle Google login
    on<LoginRequested>((event, emit) async {
      try {
        emit(Loading());

        final isRegistered = await authRepository.signInWithGoogle();
        if (isRegistered) {
          print('Google Sign-In & Firestore check passed.');
          await Future.delayed(const Duration(milliseconds: 300));
          emit(Authenticated());
        } else {
          print('User is not registered.');
          emit(UserNotRegistered());
        }
      } catch (error) {
        print('Sign-In Failed: $error');
        emit(LoginFailed(error.toString()));
      }
    });

    // Logout
    on<LogoutRequested>((event, emit) async {
      await authRepository.signOut();
      emit(Unauthenticated());
    });

    // Email/password login
    on<LoginWithEmailPasswordRequested>((event, emit) async {
      try {
        emit(Loading());

        await authRepository.signInWithEmailAndPassword(event.email, event.password);
        print('Email/Password Login Successful!');
        await Future.delayed(const Duration(milliseconds: 300));
        emit(Authenticated());
      } catch (error) {
        if (error.toString().contains('UserNotRegistered')) {
          print('User is not registered.');
          emit(UserNotRegistered());
        } else {
          print('Email/Password Login Failed: $error');
          emit(LoginFailed(error.toString()));
        }
      }
    });

    // Email/password registration
    on<RegisterWithEmailPasswordRequested>((event, emit) async {
      try {
        await authRepository.registerWithEmailAndPassword(
          event.email,
          event.password,
          event.userName,
        );
        print('Registration Successful!');
        emit(Authenticated());
      } catch (error) {
        print('Registration Failed: $error');
        emit(LoginFailed(error.toString()));
      }
    });

    // Google registration
    on<RegisterWithGoogleRequested>((event, emit) async {
      try {
        await authRepository.registerWithGoogle();
        print('Google Register Successful!');
        emit(Authenticated());
      } catch (error) {
        if (error.toString().contains('AlreadyRegistered')) {
          print('User already exists. Please Login.');
          emit(LoginFailed('Account already exists. Please login.'));
        } else {
          print('Google Register Failed: $error');
          emit(LoginFailed(error.toString()));
        }
      }
    });

    on<LocalErrorOccurred>((event, emit) {
      emit(ShowError(event.message));
    });

   on<AddPoemToFavorites>((event, emit) async {
  try {
    emit(FavoritesLoading());

    final userRef = FirebaseFirestore.instance.collection('user').doc(event.userEmail);
    await userRef.update({
      'favorites': FieldValue.arrayUnion([event.poemId])
    });

    emit(FavoriteAdded());

    // Schedule LoadFavorites outside current handler
    await Future.delayed(Duration(milliseconds: 100));
    add(LoadFavorites(event.userEmail));
  } catch (e) {
    emit(FavoriteAddFailed("Failed to add to favorites"));
  }
});


    on<LoadFavorites>((event, emit) async {
  print("LoadFavorites event triggered for ${event.userEmail}");
  emit(FavoritesLoading());
  try {
    final userRef = FirebaseFirestore.instance.collection('user').doc(event.userEmail);
    final userDoc = await userRef.get();

    final favoriteIds = List<String>.from(userDoc['favorites'] ?? []);
    print("Fetched ${favoriteIds.length} favorite IDs");

    if (favoriteIds.isEmpty) {
      emit(const FavoritesLoaded([]));
      return;
    }

    final poemsSnap = await FirebaseFirestore.instance
        .collection('poem')
        .where(FieldPath.documentId, whereIn: favoriteIds)
        .get();

    final poems = poemsSnap.docs.map((doc) {
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

    print("Loaded ${poems.length} poems");
    emit(FavoritesLoaded(poems));
  } catch (e) {
    print("Error loading favorites: $e");
    emit(FavoritesError("Failed to load favorites."));
  }
});


on<RemovePoemFromFavorites>((event, emit) async {
  try {
    final userRef = FirebaseFirestore.instance.collection('user').doc(event.userEmail);
    await userRef.update({
      'favorites': FieldValue.arrayRemove([event.poemId])
    });

    // Schedule LoadFavorites after a slight delay
    await Future.delayed(Duration(milliseconds: 100));
    add(LoadFavorites(event.userEmail));
  } catch (e) {
    emit(FavoritesError("Failed to remove favorite."));
  }
});


on<LoadFavoritesFromCache>((event, emit) {
  emit(FavoritesLoaded(event.cachedFavorites));
});


  }

  
}

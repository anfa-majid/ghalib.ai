import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alchemist/alchemist.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart' show rootBundle, MethodCall, MethodChannel, FontLoader;

import 'package:ghalib/screens/my_poem_screen.dart';
import 'package:ghalib/Bloc/my_poems_bloc.dart';
import 'package:ghalib/Bloc/my_poems_state.dart';
import 'package:ghalib/Bloc/bloc.dart';
import 'package:ghalib/Bloc/state.dart';
import 'package:ghalib/services/auth_repository.dart';

void mockFirebaseChannels() {
  const MethodChannel firebaseCore = MethodChannel('plugins.flutter.io/firebase_core');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    firebaseCore,
    (MethodCall methodCall) async {
      return {
        'app': {
          'name': '[DEFAULT]',
          'options': {
            'apiKey': 'test-api-key',
            'appId': 'test-app-id',
            'messagingSenderId': 'test-sender-id',
            'projectId': 'test-project-id',
          },
        },
        'pluginConstants': {},
      };
    },
  );

  const MethodChannel firebaseAuth = MethodChannel('plugins.flutter.io/firebase_auth');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    firebaseAuth,
    (MethodCall methodCall) async {
      if (methodCall.method == 'getCurrentUser') {
        return {'uid': 'mock_uid', 'email': 'test@example.com'};
      }
      return null;
    },
  );
}

class DummyAuthRepository implements AuthRepository {
  @override
  Future<bool> signInWithGoogle() async => true;
  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {}
  @override
  Future<void> registerWithEmailAndPassword(String email, String password, String userName) async {}
  @override
  Future<void> registerWithGoogle() async {}
  @override
  Future<void> signOut() async {}
  @override
  getCurrentUser() => null;
}

class DummyAuthBloc extends AuthBloc {
  DummyAuthBloc({required AuthRepository authRepository})
      : super(authRepository: authRepository) {
    emit(FavoritesLoaded([
      {
        'id': 'fav1',
        'title': 'Favorite Poem',
        'author': 'test@example.com',
        'mood': 'joy',
        'stanza': 'Soft winds carry hope...',
        'fullPoem': 'Full favorite poem...',
      },
    ]));
  }

  @override
  void add(event) {} // Ignore all events during tests
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
    mockFirebaseChannels();

    final playfairLoader = FontLoader('PlayfairDisplay')
      ..addFont(rootBundle.load('assets/fonts/PlayfairDisplay-Regular.ttf'));
    final satisfyLoader = FontLoader('Satisfy')
      ..addFont(rootBundle.load('assets/fonts/Satisfy-Regular.ttf'));
    final jameelLoader = FontLoader('Jameel')
      ..addFont(rootBundle.load('assets/fonts/Jameel-Noori-Nastaleeq-Regular.ttf'));

    await Future.wait([
      playfairLoader.load(),
      satisfyLoader.load(),
      jameelLoader.load(),
    ]);
  });

  Widget buildMyPoemsTestWidget(MyPoemsState state) {
    final myPoemsBloc = MyPoemsBloc()..emit(state);
    final authBloc = DummyAuthBloc(authRepository: DummyAuthRepository());

    return MultiBlocProvider(
      providers: [
        BlocProvider<MyPoemsBloc>.value(value: myPoemsBloc),
        BlocProvider<AuthBloc>.value(value: authBloc),
      ],
      child: const MaterialApp(
        home: MyPoemsScreen(
          userEmail: 'test@example.com',
          skipConnectivityCheck: true,
        ),
      ),
    );
  }

  group('MyPoemsScreen Golden Tests', () {
    goldenTest(
      'renders correctly on iPhone 13, S21, and Pixel 6',
      fileName: 'my_poems_screen_ui',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'iPhone 13',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildMyPoemsTestWidget(MyPoemsLoaded([
                {
                  'id': 'p1',
                  'title': 'Winds of Thought',
                  'author': 'test@example.com',
                  'mood': 'reflective',
                  'stanza': 'In silence, minds wander...',
                  'fullPoem': 'Full content...',
                }
              ])),
            ),
          ),
          GoldenTestScenario(
            name: 'Galaxy S21',
            child: SizedBox(
              width: 360,
              height: 800,
              child: buildMyPoemsTestWidget(MyPoemsLoaded([
                {
                  'id': 'p2',
                  'title': 'Loneliness',
                  'author': 'test@example.com',
                  'mood': 'sad',
                  'stanza': 'Echoes of silence call...',
                  'fullPoem': 'Full loneliness poem...',
                }
              ])),
            ),
          ),
          GoldenTestScenario(
            name: 'Pixel 6',
            child: SizedBox(
              width: 412,
              height: 915,
              child: buildMyPoemsTestWidget(MyPoemsLoaded([])), // no poems
            ),
          ),
        ],
      ),
    );
  });
}

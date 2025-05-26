import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alchemist/alchemist.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ghalib/screens/home_screen.dart';
import 'package:ghalib/Bloc/user_bloc.dart';
import 'package:ghalib/Bloc/user_state.dart';
import 'package:ghalib/Bloc/bloc.dart';
import 'package:ghalib/Bloc/state.dart';
import 'package:ghalib/Bloc/event.dart';
import 'package:ghalib/services/user_services.dart';

class MockUserService extends Mock implements UserService {}

class MockAuthBloc extends Mock implements AuthBloc {}

class FakeAuthState extends Fake implements AuthState {}

class FakeAuthEvent extends Fake implements AuthEvent {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HomeUserBloc homeUserBloc;
  late MockAuthBloc mockAuthBloc;
  late MockUserService mockUserService;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;

    registerFallbackValue(FakeAuthState());
    registerFallbackValue(FakeAuthEvent());

    // Mock Firebase Core
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

    // Prevent Firebase Auth from initializing
    const MethodChannel firebaseAuth = MethodChannel('plugins.flutter.io/firebase_auth');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      firebaseAuth,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getCurrentUser') {
          return {'uid': 'mock_uid', 'email': 'mocak@email.com'};
        }
        return null;
      },
    );

    // Load fonts
    final playfairLoader = FontLoader('PlayfairDisplay')
      ..addFont(rootBundle.load('assets/fonts/PlayfairDisplay-Regular.ttf'));
    final satisfyLoader = FontLoader('Satisfy')
      ..addFont(rootBundle.load('assets/fonts/Satisfy-Regular.ttf'));

    await Future.wait([playfairLoader.load(), satisfyLoader.load()]);
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockUserService = MockUserService();

    when(() => mockAuthBloc.state).thenReturn(AuthInitial());
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

    // Stubbed behavior
    when(() => mockUserService.getUserName()).thenAnswer((_) async => 'Anfa');
    when(() => mockUserService.getCurrentUserEmail()).thenReturn('mock@email.com');

    homeUserBloc = HomeUserBloc(userService: mockUserService);
    homeUserBloc.emit(HomeUserLoaded('Anfa'));
  });

  group('HomeScreen Golden Tests', () {
    goldenTest(
      'HomeScreen UI on multiple devices',
      fileName: 'home_screen_ui',
      builder: () => GoldenTestGroup(
        children: [
          for (final device in [
            {'name': 'Samsung S21', 'width': 360.0, 'height': 800.0},
            {'name': 'iPhone 13', 'width': 390.0, 'height': 844.0},
            {'name': 'Pixel 5', 'width': 393.0, 'height': 851.0},
            
          ])
            GoldenTestScenario(
              name: device['name'] as String,
              child: SizedBox(
                width: device['width'] as double,
                height: device['height'] as double,
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider<HomeUserBloc>.value(value: homeUserBloc),
                    BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                  ],
                  child: MaterialApp(
                    home: HomeScreen(userService: mockUserService), 
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  });
}

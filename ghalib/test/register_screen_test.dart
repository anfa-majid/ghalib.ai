import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alchemist/alchemist.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:ghalib/screens/register_screen.dart';
import 'package:ghalib/Bloc/bloc.dart';
import 'package:ghalib/Bloc/event.dart';
import 'package:ghalib/Bloc/state.dart';
import 'package:ghalib/services/auth_repository.dart';

// Dummy AuthRepository with no-op implementations
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

// Dummy AuthBloc that emits UI states
class DummyAuthBloc extends AuthBloc {
  DummyAuthBloc() : super(authRepository: DummyAuthRepository());

  void emitState(AuthState state) => emit(state);

  @override
  void add(AuthEvent event) {
    if (event is LocalErrorOccurred) {
      emit(ShowError(event.message));
    }
  }
}

void main() {
  late DummyAuthBloc bloc;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    bloc = DummyAuthBloc();
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      home: BlocProvider<AuthBloc>.value(
        value: bloc,
        child: const RegisterScreen(),
      ),
    );
  }

  group('RegisterScreen Golden Tests', () {
    goldenTest(
      'Default UI on iPhone 13 and Samsung S21',
      fileName: 'register_screen_default_ui',
      pumpBeforeTest: (tester) async {
        bloc.emitState(AuthInitial());
        await tester.pumpAndSettle();
      },
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(height: 844),
        children: [
          GoldenTestScenario(
            name: 'iPhone 13 (390x844)',
            child: SizedBox(width: 390, height: 844, child: buildTestableWidget()),
          ),
          GoldenTestScenario(
            name: 'Samsung S21 (360x800)',
            child: SizedBox(width: 360, height: 800, child: buildTestableWidget()),
          ),
        ],
      ),
    );

    goldenTest(
      'Shows error on validation failure',
      fileName: 'register_screen_error_ui',
      pumpBeforeTest: (tester) async {
        bloc.emitState(ShowError('Please fill in all fields.'));
        await tester.pumpAndSettle();
      },
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints.tightFor(height: 844),
        children: [
          GoldenTestScenario(
            name: 'iPhone 13 (390x844)',
            child: SizedBox(width: 390, height: 844, child: buildTestableWidget()),
          ),
          GoldenTestScenario(
            name: 'Samsung S21 (360x800)',
            child: SizedBox(width: 360, height: 800, child: buildTestableWidget()),
          ),
        ],
      ),
    );
  });
}

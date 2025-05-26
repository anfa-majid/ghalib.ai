import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alchemist/alchemist.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ghalib/screens/write_poem_screen.dart';
import 'package:ghalib/Bloc/write_poem_bloc.dart';
import 'package:ghalib/Bloc/write_poem_state.dart';
import 'package:ghalib/Bloc/connectivity_bloc.dart';
import 'package:ghalib/services/user_services.dart';

/// Dummy UserService for testing
class DummyUserService implements UserService {
  @override
  String? getCurrentUserEmail() => 'test@example.com';

  @override
  Future<String?> getUserName() async => 'Test User';
}

/// Dummy WritePoemBloc with state emitter for control
class DummyWritePoemBloc extends WritePoemBloc {
  void emitState(WritePoemState state) => emit(state);
}

/// Silent (mocked) ConnectivityBloc for tests
class SilentConnectivityBloc extends ConnectivityBloc {
  SilentConnectivityBloc() : super.silent();

  @override
  void add(ConnectivityEvent event) {
    // Do nothing in test
  }

  @override
  Stream<ConnectivityState> mapEventToState(ConnectivityEvent event) async* {
    yield state;
  }
}

class WritePoemScreenWithMocks extends StatelessWidget {
  final WritePoemBloc bloc;
  final ConnectivityBloc connectivityBloc;

  const WritePoemScreenWithMocks({
    super.key,
    required this.bloc,
    required this.connectivityBloc,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<WritePoemBloc>.value(value: bloc),
          BlocProvider<ConnectivityBloc>.value(value: connectivityBloc),
        ],
        child: WritePoemScreen(userService: DummyUserService()),
      ),
    );
  }
}

void main() {
  late DummyWritePoemBloc writePoemBloc;
  late ConnectivityBloc silentConnectivityBloc;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    writePoemBloc = DummyWritePoemBloc();
    silentConnectivityBloc = SilentConnectivityBloc();
  });

  Widget buildTestableWidget() {
    return WritePoemScreenWithMocks(
      bloc: writePoemBloc,
      connectivityBloc: silentConnectivityBloc,
    );
  }

  group('WritePoemScreen Golden Tests', () {
    goldenTest(
      'Default UI (iPhone 13, S21, Pixel 6)',
      fileName: 'write_poem_screen_default_ui',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'iPhone 13 (390x844)',
            child: SizedBox(width: 390, height: 844, child: buildTestableWidget()),
          ),
          GoldenTestScenario(
            name: 'Samsung S21 (360x800)',
            child: SizedBox(width: 360, height: 800, child: buildTestableWidget()),
          ),
          GoldenTestScenario(
            name: 'Pixel 6 (412x915)',
            child: SizedBox(width: 412, height: 915, child: buildTestableWidget()),
          ),
        ],
      ),
      pumpBeforeTest: (tester) async {
        writePoemBloc.emitState(WritePoemInitial());
        await tester.pumpAndSettle();
      },
    );

    goldenTest(
      'Validation error state shown',
      fileName: 'write_poem_screen_validation_errors',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'iPhone 13 - errors',
            child: SizedBox(width: 390, height: 844, child: buildTestableWidget()),
          ),
          GoldenTestScenario(
            name: 'Samsung S21 - errors',
            child: SizedBox(width: 360, height: 800, child: buildTestableWidget()),
          ),
          GoldenTestScenario(
            name: 'Pixel 6 - errors',
            child: SizedBox(width: 412, height: 915, child: buildTestableWidget()),
          ),
        ],
      ),
      pumpBeforeTest: (tester) async {
        writePoemBloc.emitState(WritePoemValidationState(
          titleError: 'Please enter a title',
          poemError: 'Please write your poem',
        ));
        await tester.pumpAndSettle();
      },
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alchemist/alchemist.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

import 'package:ghalib/Bloc/explore_bloc.dart';
import 'package:ghalib/Bloc/explore_event.dart';
import 'package:ghalib/Bloc/explore_state.dart';
import 'package:ghalib/Bloc/connectivity_bloc.dart';
import 'package:ghalib/screens/explore_screen.dart';

void main() {
  group('ExploreScreen Golden Tests', () {
    late ExploreBloc exploreBloc;
    late ConnectivityBloc silentConnectivityBloc;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      GoogleFonts.config.allowRuntimeFetching = false;

      SharedPreferences.setMockInitialValues({
        'searchHistory': [
          'The Road Not Taken|Frost',
          'Sonnet 18|Shakespeare',
        ],
      });

      final playfairFont = FontLoader('PlayfairDisplay')
        ..addFont(rootBundle.load('assets/fonts/PlayfairDisplay-Regular.ttf'));
      await playfairFont.load();
    });

    setUp(() {
      exploreBloc = ExploreBloc();
      silentConnectivityBloc = ConnectivityBloc.silent(); // ✅ no platform streams triggered
    });

    goldenTest(
      'ExploreScreen UI renders correctly on S21 and iPhone 13',
      fileName: 'explore_screen_ui',
      pumpBeforeTest: (tester) async {
        exploreBloc.add(LoadSearchHistory());
        await tester.pumpAndSettle();
      },
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Samsung S21',
            child: SizedBox(
              width: 360,
              height: 800,
              child: MaterialApp(
                home: MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: exploreBloc),
                    BlocProvider<ConnectivityBloc>.value(value: silentConnectivityBloc),
                  ],
                  child: const ExploreScreen(),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'iPhone 13',
            child: SizedBox(
              width: 390,
              height: 844,
              child: MaterialApp(
                home: MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: exploreBloc),
                    BlocProvider<ConnectivityBloc>.value(value: silentConnectivityBloc),
                  ],
                  child: const ExploreScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'ExploreScreen shows form validation errors (iPhone 13 only)',
      fileName: 'explore_screen_form_errors',
      pumpBeforeTest: (tester) async {
        exploreBloc.emit(ExploreValidationState(
          titleError: 'Please enter a title',
          authorError: 'Please enter an author',
          lineError: null,
          history: ['Ghazal|Mir'],
        ));
        await tester.pumpAndSettle();
      },
      builder: () => GoldenTestScenario(
        name: 'iPhone 13 - Form Validation',
        child: SizedBox(
          width: 390,
          height: 844,
          child: MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: exploreBloc),
                BlocProvider<ConnectivityBloc>.value(value: silentConnectivityBloc),
              ],
              child: const ExploreScreen(),
            ),
          ),
        ),
      ),
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'Bloc/bloc.dart';
import 'Bloc/event.dart';
import 'Bloc/state.dart';
import 'screens/get_started.dart';
import 'screens/poem_detail_screen.dart';
import 'widgets/navbar.dart';
import 'services/auth_repository.dart';
import 'services/poem_service.dart';
import 'Bloc/navigation_bloc.dart';
import 'Bloc/explore_bloc.dart';
import 'Bloc/explore_event.dart';
import 'Bloc/my_poems_bloc.dart';
import 'Bloc/connectivity_bloc.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeNotifications();
  await _checkPoetryOfTheDay();
  runApp(const MyApp());
}

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings settings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(settings);
}

Future<void> _checkPoetryOfTheDay() async {
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('poem')
        .where('isPoetryOfTheDay', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      await PoetryService.generateAndUploadPoetry();
      return;
    }

    final doc = snapshot.docs.first;
    final data = doc.data() as Map<String, dynamic>;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final now = DateTime.now();

    if (createdAt == null ||
        createdAt.year != now.year ||
        createdAt.month != now.month ||
        createdAt.day != now.day) {
      await PoetryService.generateAndUploadPoetry();
    }
  } catch (e) {
    print("Error in _checkPoetryOfTheDay: $e");
    await PoetryService.generateAndUploadPoetry();
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthBloc _authBloc;
  late final ConnectivityBloc _connectivityBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(authRepository: AuthRepository());
    _connectivityBloc = ConnectivityBloc()..add(CheckConnectivity());
    Future.microtask(() {
      _authBloc.add(AppStarted());
    });
  }

  @override
  void dispose() {
    _authBloc.close();
    _connectivityBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider(create: (_) => NavigationBloc()),
        BlocProvider(create: (_) => ExploreBloc()..add(LoadSearchHistory())),
        BlocProvider(create: (_) => MyPoemsBloc()),
        BlocProvider.value(value: _connectivityBloc),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Ghalib.ai',
        theme: ThemeData.dark(),
        navigatorObservers: [routeObserver],
        onGenerateRoute: (settings) {
          if (settings.name == '/poemDetail') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: _authBloc,
                child: PoemDetailScreen(
                  id: args['id'],
                  title: args['title'],
                  author: args['author'],
                  mood: args['mood'],
                  stanza: args['stanza'],
                  fullPoem: args['fullPoem'],
                ),
              ),
            );
          }

          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text("Route not found", style: TextStyle(color: Colors.white))),
            ),
          );
        },
        home: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is Authenticated) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainScaffold()),
                  (_) => false,
                );
              });
            } else if (state is Unauthenticated || state is UserNotRegistered) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const GetStartedScreen()),
                  (_) => false,
                );
              });
            }
          },
          child: const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
          ),
        ),
      ),
    );
  }
}

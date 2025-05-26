import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/poetry_of_the_day.dart';
import '../widgets/category_chip.dart';
import '../widgets/favourites.dart';
import '../Bloc/user_bloc.dart';
import '../Bloc/user_event.dart';
import '../Bloc/user_state.dart';
import '../Bloc/bloc.dart';
import '../Bloc/event.dart';
import '../Bloc/state.dart';
import '../services/user_services.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  final UserService? userService;

  const HomeScreen({Key? key, this.userService}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  late final UserService _userService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _userService = widget.userService ?? UserService();
    final userEmail = _userService.getCurrentUserEmail();
    if (userEmail != null) {
      context.read<AuthBloc>().add(LoadFavorites(userEmail));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final userEmail = _userService.getCurrentUserEmail();
    if (state == AppLifecycleState.resumed && userEmail != null) {
      context.read<AuthBloc>().add(LoadFavorites(userEmail));
    }
  }

  @override
  void didPopNext() {
    final userEmail = _userService.getCurrentUserEmail();
    if (userEmail != null) {
      context.read<AuthBloc>().add(LoadFavorites(userEmail));
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 18) return "Good Afternoon";
    return "Good Evening";
  }

  Widget buildTopBar(String userName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ghalib.ai',
            style: TextStyle(
              fontFamily: 'Satisfy',
              fontSize: 40,
              fontWeight: FontWeight.w400,
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: [Color(0xFFE040FB), Color(0xFF9C27B0)],
                ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${getGreeting()}, $userName',
            style: const TextStyle(
              fontFamily: 'PlayfairDisplay',
              color: Colors.white70,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'PlayfairDisplay',
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => HomeUserBloc(userService: _userService)..add(FetchUserName()),
        ),
        BlocProvider.value(value: context.read<AuthBloc>()),
      ],
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ChatGPT Image Apr 28, 2025, 09_35_55 PM.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is FavoriteAdded) {
                  final userEmail = _userService.getCurrentUserEmail();
                  if (userEmail != null) {
                    context.read<AuthBloc>().add(LoadFavorites(userEmail));
                  }
                }
              },
              child: BlocBuilder<HomeUserBloc, HomeUserState>(
                builder: (context, state) {
                  if (state is HomeUserLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.purpleAccent),
                    );
                  } else if (state is HomeUserLoaded) {
                    final userName = state.userName ?? 'User';
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildTopBar(userName),
                          const SizedBox(height: 20),
                          const PoetryOfDayCard(),
                          const SizedBox(height: 30),
                          buildSectionTitle("I'm feeling..."),
                          const SizedBox(height: 12),
                          const CategoryChips(),
                          const SizedBox(height: 30),
                          buildSectionTitle('Your Favorites'),
                          const SizedBox(height: 12),
                          const FavoritesCarousel(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    );
                  } else if (state is HomeUserError) {
                    return Center(
                      child: const Text(
                        "Failed to load user",
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

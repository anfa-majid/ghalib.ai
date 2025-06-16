import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../Bloc/bloc.dart'; 
import '../Bloc/event.dart';
import '../Bloc/state.dart'; 
import '../Bloc/my_poems_bloc.dart';
import '../Bloc/my_poems_event.dart';
import '../Bloc/my_poems_state.dart';
import '../widgets/poem_card.dart';
import '../utils/cache.dart';
import '../main.dart';
import '../widgets/shimmer_grey.dart';
import '../model/poem_model.dart';

class MyPoemsScreen extends StatefulWidget {
  final String? userEmail;  
  final bool skipConnectivityCheck; 

  const MyPoemsScreen({
    super.key,
    this.userEmail,
    this.skipConnectivityCheck = false,
  });

  @override
  State<MyPoemsScreen> createState() => _MyPoemsScreenState();
}

class _MyPoemsScreenState extends State<MyPoemsScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  late String userEmail;
  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    userEmail = widget.userEmail ??
        FirebaseAuth.instance.currentUser?.email?.trim().toLowerCase() ??
        '';

    if (!widget.skipConnectivityCheck) {
      Future.microtask(() => _checkConnectivityAndLoad());
    } else {
      // Directly load from blocs without connectivity check (issues with testing)
      context.read<MyPoemsBloc>().add(LoadMyPoems(userEmail));
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
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    context.read<AuthBloc>().add(LoadFavorites(userEmail));
  }

  Future<void> _checkConnectivityAndLoad() async {
    final connected =
        (await Connectivity().checkConnectivity()) != ConnectivityResult.none;

    if (connected) {
      isOffline = false;
      context.read<MyPoemsBloc>().add(LoadMyPoems(userEmail));
      context.read<AuthBloc>().add(LoadFavorites(userEmail));
    } else {
      isOffline = true;

      final cachedMine = await Cache.loadPoems("cached_mypoems_$userEmail");
      final cachedFavs = await Cache.loadPoems("cached_favorites_$userEmail");

      context.read<MyPoemsBloc>().add(LoadMyPoemsFromCache(cachedMine));
      context.read<AuthBloc>().add(LoadFavoritesFromCache(cachedFavs));
    }
  }

  Widget _buildPoemGrid({
    required List<Map<String, dynamic>> poems,
    required bool isLoading,
    bool showDelete = false,
  }) {
    if (isLoading) {
      return const Shimmerload();
    }

    if (poems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: Text("No poems found.", style: TextStyle(color: Colors.white60)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: poems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 24,
          crossAxisSpacing: 16,
          childAspectRatio: 1.05,
        ),
        itemBuilder: (_, idx) {
          final poemMap = poems[idx];
          final poem = Poem.fromMap(poemMap['id'], {
            'title': poemMap['title'],
            'author': poemMap['author'],
            'moodTag': poemMap['mood'],
            'stanza': poemMap['stanza'],
            'content': poemMap['fullPoem'],
            'highlightLine': '',
            'isPoetryOfTheDay': false,
            'createdAt': null,
          });
          
          return Transform.rotate(
            angle: -0.052,
            child: PoemCard(poem: poem, userEmail: userEmail, showDelete: showDelete),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<MyPoemsBloc, MyPoemsState>(
          listener: (context, state) {
            if (state is MyPoemsLoaded) {
              Cache.savePoems("cached_mypoems_$userEmail", state.poems);
            }
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is FavoritesLoaded) {
              Cache.savePoems("cached_favorites_$userEmail", state.poems);
            }
          },
        ),
      ],
      child: BlocBuilder<MyPoemsBloc, MyPoemsState>(
        builder: (context, myPoemState) {
          return BlocBuilder<AuthBloc, AuthState>(
            builder: (context, favState) {
              final List<Map<String, dynamic>> myPoems =
                  myPoemState is MyPoemsLoaded ? myPoemState.poems : [];

              final List<Map<String, dynamic>> favorites =
                  favState is FavoritesLoaded ? favState.poems : [];

              return Container(
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
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          "Ghalib's Corner",
                          style: TextStyle(
                            fontFamily: 'Satisfy',
                            fontSize: 36,
                            fontWeight: FontWeight.w400,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [Color(0xFFE040FB), Color(0xFF9C27B0)],
                              ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "See what you've written or saved",
                          style: GoogleFonts.playfairDisplay(
                            textStyle: const TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (isOffline)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "⚠️ You're offline. Showing cached poems.",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        TabBar(
                          controller: _tabController,
                          labelColor: Colors.purpleAccent,
                          unselectedLabelColor: Colors.white70,
                          indicatorColor: Colors.purpleAccent,
                          tabs: const [
                            Tab(text: "My Poems"),
                            Tab(text: "My Favorites"),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              SingleChildScrollView(
                                  child: _buildPoemGrid(
                                poems: myPoems,
                                isLoading: myPoemState is MyPoemsLoading,
                                showDelete: true,
                              )),
                              SingleChildScrollView(
                                  child: _buildPoemGrid(
                                poems: favorites,
                                isLoading: favState is FavoritesLoading,
                              )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

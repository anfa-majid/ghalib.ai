import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../screens/home_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/get_started.dart';
import '../screens/write_poem_screen.dart';
import '../Bloc/write_poem_bloc.dart';
import '../Bloc/navigation_bloc.dart';
import '../Bloc/bloc.dart';
import '../Bloc/event.dart';
import '../Bloc/explore_bloc.dart';
import '../Bloc/explore_event.dart';
import '../screens/my_poem_screen.dart';
import '../Bloc/connectivity_bloc.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({Key? key}) : super(key: key);

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline, color: Colors.white),
                title: const Text('Change Password', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Change password coming soon!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text('Logout', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  context.read<AuthBloc>().add(LogoutRequested());
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const GetStartedScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon) {
    return BlocBuilder<NavigationBloc, NavigationState>(
      builder: (context, state) {
        final isSelected = state.currentIndex == index;
        return GestureDetector(
          onTap: () {
            if (index == 4) {
              _showProfileMenu(context);
            } else {
              context.read<NavigationBloc>().add(NavigateTo(index));
            }
          },
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(
              icon,
              color: isSelected ? Colors.purpleAccent : Colors.white70,
              size: 26,
            ),
          ),
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  final authBloc = context.read<AuthBloc>();

  final screens = [
    BlocProvider.value(value: authBloc, child: const HomeScreen()),
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authBloc),
        BlocProvider(create: (_) => ExploreBloc()..add(LoadSearchHistory())),
      ],
      child: const ExploreScreen(),
    ),
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authBloc),
        BlocProvider(create: (_) => WritePoemBloc()),
      ],
      child:  WritePoemScreen(),
    ),
    BlocProvider.value(value: authBloc, child: const MyPoemsScreen()),
    const Placeholder(), // Profile
  ];

  return Stack(
    children: [
      Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ChatGPT Image Apr 28, 2025, 09_35_55 PM.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
          ),
        ),
      ),
      BlocBuilder<ConnectivityBloc, ConnectivityState>(
        builder: (context, connState) {
          return Scaffold(
            extendBody: true,
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                if (!connState.isOnline)
                  Container(
                    width: double.infinity,
                    color: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Center(
                      child: Text(
                        "⚠️ You're offline",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                Expanded(
                  child: SafeArea(
                    bottom: false,
                    child: BlocBuilder<NavigationBloc, NavigationState>(
                      builder: (context, state) {
                        return screens[state.currentIndex];
                      },
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Container(
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.grey[900]?.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(context, 0, Icons.home),
                        _buildNavItem(context, 1, Icons.explore),
                        const SizedBox(width: 48),
                        _buildNavItem(context, 3, Icons.favorite_border),
                        _buildNavItem(context, 4, Icons.person_outline),
                      ],
                    ),
                    Positioned(
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: FloatingActionButton(
                          backgroundColor: Colors.white,
                          onPressed: () {
                            context.read<NavigationBloc>().add(NavigateTo(2));
                          },
                          shape: const CircleBorder(),
                          child: Image.asset(
                            'assets/quill-pen.png',
                            width: 26,
                            height: 26,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ],
  );
}
}
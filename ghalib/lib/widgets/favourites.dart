import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Bloc/bloc.dart';
import '../Bloc/event.dart';
import '../Bloc/state.dart';
import '../screens/poem_detail_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import '../model/poem_model.dart';

class FavoritesCarousel extends StatefulWidget {
  const FavoritesCarousel({Key? key}) : super(key: key);

  @override
  State<FavoritesCarousel> createState() => _FavoritesCarouselState();
}

class _FavoritesCarouselState extends State<FavoritesCarousel> {
  late PageController controller;

  @override
  void initState() {
    super.initState();
    controller = PageController(viewportFraction: 0.82);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
  return const Padding(
    padding: EdgeInsets.all(16),
    child: Text(
      "Favorites unavailable in test mode",
      style: TextStyle(color: Colors.white54),
    ),
  );
}

    final user = FirebaseAuth.instance.currentUser;

    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) =>
          curr is FavoritesLoading || curr is FavoritesLoaded || curr is FavoritesError,
      builder: (context, state) {
        if (state is FavoritesLoading) {
          return const SizedBox(
            height: 130,
            child: Center(
              child: CircularProgressIndicator(color: Colors.purpleAccent),
            ),
          );
        } else if (state is FavoritesLoaded) {
          final favoritePoems = state.poems;

          if (favoritePoems.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "No favorites yet",
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          return SizedBox(
            height: 130,
            child: PageView.builder(
              controller: controller,
              itemCount: favoritePoems.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final poemMap = favoritePoems[index];
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

                return Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PoemDetailScreen(
                              id: poem.id,
                              title: poem.title,
                              author: poem.author,
                              mood: poem.moodTag,
                              stanza: poem.stanza,
                              fullPoem: poem.content,
                            ),
                          ),
                        ).then((_) {
                          if (user != null && context.mounted) {
                            context.read<AuthBloc>().add(LoadFavorites(user.email!));
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(77),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                            ),
                            const BoxShadow(
                              color: Color(0x55000000),
                              spreadRadius: -6,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 30, top: 10),
                            child: Text(
                              poem.title,
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Jameel',
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 2,
                                    color: Colors.black54,
                                  )
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        iconSize: 22,
                        color: Colors.white,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Remove from Favorites',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF2C003E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Text('Remove from Favorites?', style: TextStyle(color: Colors.white)),
                              content: const Text('Are you sure you want to remove this poem?',
                                  style: TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Remove', style: TextStyle(color: Colors.pinkAccent)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && user != null) {
                            context.read<AuthBloc>().add(RemovePoemFromFavorites(
                                  userEmail: user.email!,
                                  poemId: poem.id,
                                ));
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        } else if (state is FavoritesError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(state.message, style: const TextStyle(color: Colors.redAccent)),
          );
        } else {
          return const SizedBox(height: 130);
        }
      },
    );
  }
}

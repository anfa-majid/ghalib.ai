import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/poem_service.dart'; 
import '../screens/poem_detail_screen.dart'; 
import 'package:ghalib/widgets/shimmer_loader.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Bloc/bloc.dart';
import '../Bloc/event.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({Key? key}) : super(key: key);

  String getRandomMessage(String mood) {
    final List<String> phrases = [
      'Summoning poetic whispers...',
      'Dusting off old verses...',
      'Calling upon Ghalib...',
      'Whispering to Dickinson...',
      'Letting Rumi speak...',
      'Floating words for "$mood"...',
      'Searching Shakespeare\'s soul...',
      'Pulling out a dream from Auden...',
    ];
    phrases.shuffle();
    return phrases.first;
  }

  @override
  Widget build(BuildContext context) {
    final moods = [
      'Love', 'Sad', 'Hope', 'Nostalgia',
      'Freedom', 'Happiness', 'Life', 'Death',
      'Nature', 'Beauty', 'Longing', 'Dreams',
    ];

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: moods.length,
        itemBuilder: (context, index) {
          final mood = moods[index];

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () async {
                final message = getRandomMessage(mood);

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => ShimmerLoader(message: message),
                );

                final poem = await PoetryService.generatePoemByMood(mood);
                Navigator.of(context).pop(); // remove loading dialog

                if (poem != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PoemDetailScreen(
                        id: poem['id'],
                        title: poem['title'],
                        author: poem['author'],
                        mood: poem['mood'],
                        stanza: poem['stanza'],
                        fullPoem: poem['fullPoem'],
                      ),
                    ),
                  ).then((_) {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      context.read<AuthBloc>().add(LoadFavorites(user.email!));
                    }
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Couldn’t fetch a poem right now 🥲"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.03),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purpleAccent.withOpacity(0.2),
                      blurRadius: 6,
                      spreadRadius: 2,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    mood,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

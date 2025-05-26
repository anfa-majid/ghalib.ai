import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Bloc/bloc.dart'; 
import '../Bloc/event.dart';
import '../screens/poem_detail_screen.dart';
import '../Bloc/my_poems_bloc.dart';
import '../Bloc/my_poems_event.dart';

class PoemCard extends StatelessWidget {
  final Map<String, dynamic> poem;
  final bool showDelete;
  final String userEmail;

  const PoemCard({
    super.key,
    required this.poem,
    required this.userEmail,
    this.showDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PoemDetailScreen(
              id: poem['id'] ?? '',
              title: poem['title'] ?? 'Untitled',
              author: poem['author'] ?? 'Unknown',
              mood: poem['mood'] ?? 'unknown',
              stanza: poem['stanza'] ?? '',
              fullPoem: poem['fullPoem'] ?? poem['stanza'] ?? '',
            ),
          ),
        ).then((_) {
          if (context.mounted && userEmail.isNotEmpty) {
            context.read<AuthBloc>().add(LoadFavorites(userEmail));
          }
        });
      },
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poem['title'] ?? 'Untitled',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w400, // Use w400 to match your available font
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        '"${poem['stanza'] ?? ''}"',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                          fontFamily: 'Jameel',
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (showDelete)
            Positioned(
              top: 6,
              right: 6,
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: const Color(0xFF2C003E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text(
                            "Delete Poem?",
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            "Are you sure you want to delete this poem?",
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(color: Colors.white60),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.pinkAccent),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && poem['id'] != null) {
                        context.read<MyPoemsBloc>().add(
                          DeletePoem(userEmail: userEmail, poemId: poem['id']),
                        );
                      }
                    },
              ),
            ),
        ],
      ),
    );
  }
}

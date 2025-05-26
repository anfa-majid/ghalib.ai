import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Bloc/bloc.dart';
import '../Bloc/event.dart';
import '../Bloc/state.dart';
import '../services/user_services.dart';
import '../widgets/offline_banner.dart';

class PoemDetailScreen extends StatefulWidget {
  final String id;
  final String title;
  final String author;
  final String mood;
  final String stanza;
  final String fullPoem;
  final UserService? userService;

  const PoemDetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.author,
    required this.mood,
    required this.stanza,
    required this.fullPoem,
    this.userService,
  });

  @override
  State<PoemDetailScreen> createState() => _PoemDetailScreenState();
}

class _PoemDetailScreenState extends State<PoemDetailScreen> {
  bool _previouslyFavorite = false;
  bool _hasLoadedFavorites = false;
  late final UserService _userService;

  // Flag to skip connectivity check during tests
  final bool skipConnectivityCheck =
      const bool.fromEnvironment('SKIP_CONNECTIVITY_CHECK', defaultValue: false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userService = widget.userService ?? UserService();

    if (!_hasLoadedFavorites) {
      final email = _userService.getCurrentUserEmail();
      if (email != null && widget.id.isNotEmpty) {
        if (!skipConnectivityCheck) {
          Connectivity().checkConnectivity().then((result) {
            if (result != ConnectivityResult.none) {
              context.read<AuthBloc>().add(LoadFavorites(email));
            }
          });
        } else {
          context.read<AuthBloc>().add(LoadFavorites(email));
        }
        _hasLoadedFavorites = true;
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getCachedFavorites(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString("cached_favorites_$email");
    if (jsonString == null) return [];
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = _userService.getCurrentUserEmail();

    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (userEmail != null && context.mounted) {
                if (!skipConnectivityCheck) {
                  final connectivity = await Connectivity().checkConnectivity();
                  if (connectivity != ConnectivityResult.none) {
                    Navigator.pop(context);
                    return;
                  }
                }
                context.read<AuthBloc>().add(
                      LoadFavoritesFromCache(await _getCachedFavorites(userEmail)),
                    );
              }
              Navigator.pop(context);
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/ChatGPT Image Apr 28, 2025, 09_35_55 PM.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
            Column(
              children: [
                const OfflineBanner(),
                Expanded(
                  child: BlocConsumer<AuthBloc, AuthState>(
                    listener: (context, state) {
                      if (state is FavoriteAdded) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Added to favorites"),
                            backgroundColor: Colors.purpleAccent,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } else if (state is FavoritesLoaded) {
                        final isNowFavorite = state.poems.any((poem) => poem['id'] == widget.id);
                        if (_previouslyFavorite && !isNowFavorite) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Removed from favorites."),
                              backgroundColor: Colors.purple,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                        _previouslyFavorite = isNowFavorite;
                      }
                    },
                    builder: (context, state) {
                      final isLoading = state is FavoritesLoading;
                      final isFavorite = state is FavoritesLoaded &&
                          state.poems.any((poem) => poem['id'] == widget.id);

                      if (state is FavoritesLoaded) {
                        _previouslyFavorite = isFavorite;
                      }

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Satisfy',
                                  fontSize: 40,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.purpleAccent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            GestureDetector(
                              onLongPress: () async {
                                await Clipboard.setData(ClipboardData(text: widget.fullPoem));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Poem copied to clipboard 📋"),
                                    backgroundColor: Colors.purple,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: SelectableText(
                                widget.fullPoem,
                                textAlign: TextAlign.justify,
                                style: const TextStyle(
                                  fontSize: 26,
                                  color: Colors.white,
                                  height: 2.4,
                                  fontFamily: 'Jameel',
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Center(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: 'Mood: ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white54,
                                        fontFamily: 'Jameel',
                                      ),
                                    ),
                                    TextSpan(
                                      text: '${widget.mood}   ',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white70,
                                        fontFamily: 'Jameel',
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const TextSpan(text: "   "),
                                    TextSpan(
                                      text: "- ${widget.author}",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.white70,
                                        fontStyle: FontStyle.italic,
                                        fontFamily: 'Jameel',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: (isLoading || userEmail == null)
                                        ? null
                                        : isFavorite
                                            ? () {
                                                context.read<AuthBloc>().add(
                                                      RemovePoemFromFavorites(
                                                        userEmail: userEmail,
                                                        poemId: widget.id,
                                                      ),
                                                    );
                                              }
                                            : () {
                                                context.read<AuthBloc>().add(
                                                      AddPoemToFavorites(
                                                        userEmail: userEmail,
                                                        poemId: widget.id,
                                                      ),
                                                    );
                                              },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      backgroundColor: const Color(0xFFAB47BC),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    icon: isLoading
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Icon(
                                            isFavorite ? Icons.favorite : Icons.favorite_outline,
                                            color: Colors.white,
                                          ),
                                    label: Text(
                                      isFavorite
                                          ? "Remove from Favorites"
                                          : isLoading
                                              ? "Adding..."
                                              : "Add to Favorites",
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final textToCopy = '"${widget.title}"\n\n${widget.fullPoem}';
                                      await Clipboard.setData(ClipboardData(text: textToCopy));
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Poem copied to clipboard"),
                                            backgroundColor: Colors.purple,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      backgroundColor: const Color(0xFF7E57C2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    icon: const Icon(Icons.copy, color: Colors.white),
                                    label: const Text("Copy All", style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

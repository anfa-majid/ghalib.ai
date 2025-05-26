import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/shimmer_loader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../Bloc/bloc.dart';
import '../Bloc/event.dart';
import '../screens/poem_detail_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
String? _lastPoemId; 

class PoetryOfDayCard extends StatelessWidget {
  const PoetryOfDayCard({Key? key}) : super(key: key);

  void _sendPoemNotification(String title, String line) async {
    const androidDetails = AndroidNotificationDetails(
      'poem_channel',
      'Poem Notifications',
      channelDescription: 'Daily poem alerts',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Poetry of the Day',
      '"$line"\n— $title',
      notificationDetails,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0),
    child: Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: const Center(
        child: Text(
          'Poetry of the Day',
          style: TextStyle(color: Colors.white54),
        ),
      ),
    ),
  );
}

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('poem')
          .where('isPoetryOfTheDay', isEqualTo: true)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerLoader(message: "Fetching today's verse...");
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No poetry for today",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        final line = data['highlightLine'] ?? data['content'] ?? '';
        final author = data['author'] ?? 'Unknown';
        final title = data['title'] ?? 'Untitled';

        // Trigger notification only if new
        if (_lastPoemId != doc.id) {
          _lastPoemId = doc.id;
          Future.microtask(() => _sendPoemNotification(title, line));
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PoemDetailScreen(
                  id: doc.id,
                  title: title,
                  author: author,
                  mood: data['moodTag'] ?? 'unknown',
                  stanza: data['stanza'] ?? '',
                  fullPoem: data['content'] ?? '',
                ),
              ),
            ).then((_) {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                context.read<AuthBloc>().add(LoadFavorites(user.email!));
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(13),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withAlpha(51)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withAlpha(102),
                        blurRadius: 30,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Poetry of the Day',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '"$line"',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontStyle: FontStyle.italic,
                          height: 1.8,
                          fontFamily: 'Jameel',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "- $author",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Jameel',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

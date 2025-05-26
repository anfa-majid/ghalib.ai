import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../Bloc/write_poem_bloc.dart';
import '../Bloc/write_poem_event.dart';
import '../Bloc/write_poem_state.dart';
import '../Bloc/connectivity_bloc.dart';
import '../services/user_services.dart';
import '../widgets/custom_textfield.dart';

class WritePoemScreen extends StatelessWidget {
  final UserService userService;

  WritePoemScreen({super.key, UserService? userService})
      : userService = userService ?? UserService();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WritePoemBloc(),
      child: BlocBuilder<ConnectivityBloc, ConnectivityState>(
        builder: (context, connState) {
          final isOnline = connState.isOnline;

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
              body: Stack(
                children: [
                  SafeArea(
                    child: BlocConsumer<WritePoemBloc, WritePoemState>(
                      listener: (context, state) {
                        final bloc = context.read<WritePoemBloc>();
                        if (state is WritePoemGenerated) {
                          bloc.poemController.text = state.lines + '\n';
                        } else if (state is WritePoemSaved) {
                          bloc.add(TriggerSuccessAnimationEvent());
                        } else if (state is WritePoemError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.message)),
                          );
                        }
                      },
                      builder: (context, state) {
                        final bloc = context.read<WritePoemBloc>();
                        String? titleError;
                        String? poemError;

                        if (state is WritePoemValidationState) {
                          titleError = state.titleError;
                          poemError = state.poemError;
                        }

                        return ListView(
                          padding: const EdgeInsets.all(24),
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    'Deewan-e-Ghalib',
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
                                  const SizedBox(height: 6),
                                  Text(
                                    "Craft your own verse or let AI inspire you",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.playfairDisplay(
                                      textStyle: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),
                            CustomTextField(
                              hintText: 'Poem Title',
                              controller: bloc.titleController,
                              errorText: titleError,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: bloc.selectedMood,
                              dropdownColor: Colors.black87,
                              iconEnabledColor: Colors.white,
                              style: const TextStyle(color: Colors.white),
                              items: bloc.moods
                                  .map((mood) => DropdownMenuItem(
                                        value: mood,
                                        child: Text(mood),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                bloc.add(ChangeMoodEvent(mood: value!));
                                if (bloc.aiStarterSelected && isOnline) {
                                  bloc.add(GenerateStarterLinesEvent(mood: value));
                                }
                              },
                              decoration: const InputDecoration(
                                labelText: 'Mood',
                                labelStyle: TextStyle(color: Colors.white70),
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white10,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Start with AI suggestions?",
                                    style: TextStyle(color: Colors.white)),
                                Switch(
                                  value: bloc.aiStarterSelected,
                                  onChanged: isOnline
                                      ? (value) {
                                          bloc.add(ToggleAiStarterEvent(enabled: value));
                                          if (value) {
                                            bloc.add(GenerateStarterLinesEvent(mood: bloc.selectedMood));
                                          }
                                        }
                                      : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: bloc.poemController,
                              maxLines: 10,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Write your poem',
                                labelStyle: const TextStyle(color: Colors.white70),
                                border: const OutlineInputBorder(),
                                alignLabelWithHint: true,
                                filled: true,
                                fillColor: Colors.white10,
                                errorText: poemError,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isOnline ? Colors.purpleAccent : Colors.grey,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: isOnline
                                  ? () async {
                                      final title = bloc.titleController.text.trim();
                                      final content = bloc.poemController.text.trim();
                                      final userEmail =
                                          userService.getCurrentUserEmail() ?? 'Anonymous';

                                      bloc.add(SavePoemEvent(
                                        title: title,
                                        author: userEmail,
                                        mood: bloc.selectedMood,
                                        content: content,
                                      ));
                                    }
                                  : null,
                              icon: const Icon(Icons.save, color: Colors.white),
                              label: const Text('Save Poem', style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton.icon(
                                onPressed: () async {
                                  final bloc = context.read<WritePoemBloc>();
                                  final isTitleEmpty = bloc.titleController.text.trim().isEmpty;
                                  final isPoemEmpty = bloc.poemController.text.trim().isEmpty;

                                  if (isTitleEmpty && isPoemEmpty) {
                                    await showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        backgroundColor: const Color(0xFF2C003E),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        title: const Text(
                                          "Nothing to reset!",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        content: const Text(
                                          "Please write something before attempting to reset.",
                                          style: TextStyle(color: Colors.white70),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text(
                                              "OK",
                                              style: TextStyle(color: Colors.pinkAccent),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    return;
                                  }

                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: const Color(0xFF2C003E),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: const Text(
                                        "Reset All?",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: const Text(
                                        "This will clear the title, mood, and poem.",
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
                                            "Reset",
                                            style: TextStyle(color: Colors.pinkAccent),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    bloc.add(WritePoemReset());
                                  }
                                },
                                icon: const Icon(Icons.refresh, size: 18, color: Colors.white70),
                                label: const Text('Reset All', style: TextStyle(color: Colors.white70)),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  BlocBuilder<WritePoemBloc, WritePoemState>(
                    builder: (context, state) {
                      if (state is ShowSuccessAnimationState) {
                        return Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(102),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Lottie.asset(
                                      'assets/Animation - 1747504556242.json',
                                      width: 160,
                                      repeat: false,
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Poem saved successfully!',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

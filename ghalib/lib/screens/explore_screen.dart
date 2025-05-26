import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Bloc/explore_bloc.dart';
import '../Bloc/explore_event.dart';
import '../Bloc/explore_state.dart';
import '../Bloc/connectivity_bloc.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/shimmer_loader.dart';
import '../screens/poem_detail_screen.dart';
import '../Bloc/bloc.dart';
import '../main.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  late TabController _tabController;
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _lineController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<ExploreBloc>().add(LoadSearchHistory());

    _titleController.addListener(() {
      context.read<ExploreBloc>().add(ResetExplore());
    });
    _authorController.addListener(() {
      context.read<ExploreBloc>().add(ResetExplore());
    });
    _lineController.addListener(() {
      context.read<ExploreBloc>().add(ResetExplore());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    _tabController.dispose();
    routeObserver.unsubscribe(this);
    _titleController.dispose();
    _authorController.dispose();
    _lineController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    context.read<ExploreBloc>().add(LoadSearchHistory());
  }

  void _handleSearchByTitle(bool isOnline) {
    if (!isOnline) return;
    final title = _titleController.text.trim();
    final author = _authorController.text.trim();
    context.read<ExploreBloc>().add(SearchByTitleAndAuthor(title: title, author: author));
  }

  void _handleSearchByLine(bool isOnline) {
    if (!isOnline) return;
    final line = _lineController.text.trim();
    context.read<ExploreBloc>().add(SearchByLine(line: line));
  }

  Widget _buildSearchButton(VoidCallback onPressed, bool isLoading, bool isOnline, {String? errorMessage}) {
    return Column(
      children: [
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.redAccent, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        if (!isOnline)
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text("You are offline", style: TextStyle(color: Colors.redAccent)),
          ),
        ElevatedButton(
          onPressed: isOnline ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFAB47BC),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text("Search", style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildForm(List<Widget> fields) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(18),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: fields),
        ),
      ),
    );
  }

  Widget _buildSearchHistoryList(List<String> history, bool isOnline) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Searches',
                  style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => context.read<ExploreBloc>().add(ClearSearchHistory()),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text("Clear", style: TextStyle(color: Colors.pinkAccent, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.separated(
              itemCount: history.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white24),
              itemBuilder: (_, index) {
                final entry = history[index];
                final parts = entry.split('|');
                final title = parts[0];
                final author = parts.length > 1 ? parts[1] : 'Unknown';

                return ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -3),
                  leading: const Icon(Icons.history, color: Colors.white70, size: 20),
                  title: Text(title, style: const TextStyle(color: Colors.white)),
                  subtitle: Text('by $author', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.white38),
                    onPressed: () => context.read<ExploreBloc>().add(RemoveSearchHistoryEntry(entry)),
                  ),
                  onTap: isOnline
                      ? () {
                          _titleController.text = title;
                          _authorController.text = author;
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const ShimmerLoader(message: "Searching poem..."),
                          );
                          final bloc = context.read<ExploreBloc>();
                          bloc.add(ResetExplore());
                          Future.delayed(const Duration(milliseconds: 100), () {
                            bloc.add(SearchByTitleAndAuthor(title: title, author: author));
                          });
                        }
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      builder: (context, connState) {
        final isOnline = connState.isOnline;

        return BlocListener<ExploreBloc, ExploreState>(
          listener: (context, state) async {
            if (state is ExploreLoading) {
              if (ModalRoute.of(context)?.isCurrent ?? true) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const ShimmerLoader(message: "Searching poem..."),
                );
              }
            } else if (state is ExploreLoaded) {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: context.read<AuthBloc>()),
                      BlocProvider.value(value: context.read<ExploreBloc>()),
                    ],
                    child: PoemDetailScreen(
                      id: state.poem['id'] ?? '',
                      title: state.poem['title'],
                      author: state.poem['author'],
                      mood: state.poem['mood'],
                      stanza: state.poem['stanza'],
                      fullPoem: state.poem['fullPoem'],
                    ),
                  ),
                ),
              );
              context.read<ExploreBloc>().add(ResetExplore());

              final title = _titleController.text.trim();
              final author = _authorController.text.trim();
              context.read<ExploreBloc>().add(AddSearchHistory('$title|$author'));
            } else if (state is ExploreError) {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            }
          },
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
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'Ghalib.ai Explorer',
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
                      "Explore timeless poetry from Rumi, Ghalib & more",
                      style: GoogleFonts.playfairDisplay(
                          textStyle: const TextStyle(color: Colors.white70, fontSize: 16)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: DefaultTabController(
                        length: 2,
                        child: Column(
                          children: [
                            TabBar(
                              controller: _tabController,
                              labelColor: Colors.purpleAccent,
                              unselectedLabelColor: Colors.white70,
                              indicatorColor: Colors.purpleAccent,
                              tabs: const [
                                Tab(text: "By Title & Poet"),
                                Tab(text: "By Line"),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: BlocBuilder<ExploreBloc, ExploreState>(
                                builder: (context, state) {
                                  String? titleError;
                                  String? authorError;
                                  String? lineError;
                                  String? errorMessage;
                                  List<String> history = [];

                                  if (state is ExploreValidationState) {
                                    titleError = state.titleError;
                                    authorError = state.authorError;
                                    lineError = state.lineError;
                                    history = state.history;
                                  } else if (state is ExploreError) {
                                    errorMessage = state.message;
                                  } else if (state is SearchHistoryLoaded) {
                                    history = state.history;
                                  }

                                  return TabBarView(
                                    controller: _tabController,
                                    children: [
                                      SingleChildScrollView(
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        child: Column(
                                          children: [
                                            const SizedBox(height: 30),
                                            _buildForm([
                                              CustomTextField(
                                                hintText: "Enter poem title",
                                                controller: _titleController,
                                                errorText: titleError,
                                              ),
                                              const SizedBox(height: 16),
                                              CustomTextField(
                                                hintText: "Enter poet name",
                                                controller: _authorController,
                                                errorText: authorError,
                                              ),
                                              const SizedBox(height: 24),
                                              _buildSearchButton(
                                                () => _handleSearchByTitle(isOnline),
                                                state is ExploreLoading,
                                                isOnline,
                                                errorMessage: errorMessage,
                                              ),
                                            ]),
                                            _buildSearchHistoryList(history, isOnline),
                                            const SizedBox(height: 40),
                                          ],
                                        ),
                                      ),
                                      SingleChildScrollView(
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        child: Column(
                                          children: [
                                            const SizedBox(height: 30),
                                            _buildForm([
                                              CustomTextField(
                                                hintText: "Enter a line from a poem",
                                                controller: _lineController,
                                                errorText: lineError,
                                              ),
                                              const SizedBox(height: 24),
                                              _buildSearchButton(
                                                () => _handleSearchByLine(isOnline),
                                                state is ExploreLoading,
                                                isOnline,
                                                errorMessage: errorMessage,
                                              ),
                                            ]),
                                            _buildSearchHistoryList(history, isOnline),
                                            const SizedBox(height: 40),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'login_screen.dart';
import '../Bloc/bloc.dart'; 

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({Key? key}) : super(key: key);

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> with TickerProviderStateMixin {
  late AnimationController _textController;
  late Animation<double> _fadeAnimation;
  late AnimationController _buttonElevationController;
  late Animation<double> _buttonElevationAnimation;

  late AuthBloc authBloc; 
  @override
  void initState() {
    super.initState();
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _textController, curve: Curves.easeIn);
    _textController.forward();

    _buttonElevationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _buttonElevationAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _buttonElevationController, curve: Curves.easeOutCubic),
    );
    _buttonElevationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    authBloc = BlocProvider.of<AuthBloc>(context);
  }

  @override
  void dispose() {
    _textController.dispose();
    _buttonElevationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/pexels-seymasungr-1499342462-27773645_50.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(color: Colors.black.withAlpha(77)),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black87,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 12),
                    RichText(
                      textAlign: TextAlign.left,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                        children: [
                          const TextSpan(text: 'Unleash Your\nInner ', style: TextStyle(color: Colors.white)),
                          TextSpan(
                            text: 'Ghalib',
                            style: TextStyle(
                              fontFamily: 'Satisfy',
                              fontSize: 50,
                              fontWeight: FontWeight.normal,
                              foreground: Paint()
                                ..shader = const LinearGradient(
                                  colors: [Color(0xFF9C27B0), Color(0xFFE040FB)],
                                ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Bringing Poetry to Life, One Verse at a Time.',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        height: 1.6,
                      ),
                    ),
                    const Spacer(flex: 5),
                    AnimatedBuilder(
                      animation: _buttonElevationAnimation,
                      builder: (context, child) {
                        return SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider.value(
                                    value: authBloc, 
                                    child: const LoginScreen(),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: _buttonElevationAnimation.value,
                              backgroundColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF9C27B0), Color(0xFFE040FB)],
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Center(
                                child: Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

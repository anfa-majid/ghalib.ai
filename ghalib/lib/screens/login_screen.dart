import 'dart:ui';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/google_button.dart';
import '../Bloc/bloc.dart';
import '../Bloc/event.dart';
import '../Bloc/state.dart';
import 'register_screen.dart';
import '../widgets/navbar.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScaffold()),
            (route) => false,
          );
        }
      },

      builder: (context, state) {
        final isLoading = state is Loading;
        String? customErrorMessage;

        if (state is LoginFailed || state is ShowError) {
          customErrorMessage = (state as dynamic).message;
        } else if (state is UserNotRegistered) {
          customErrorMessage = "You are not registered. Please register first.";
        }

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
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
              ),
              Center(
                child: Container(
                  width: size.width * 0.85,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: kDebugMode
                          ? const BoxConstraints(maxHeight: 700)  // Fix for tests/debug mode
                          : const BoxConstraints(),               // No constraint in release mode
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Welcome Back',
                            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Login to continue your poetic journey.',
                            style: TextStyle(fontSize: 15, color: Colors.white70),
                          ),
                          const SizedBox(height: 28),
                          CustomTextField(
                            hintText: 'Email Address',
                            controller: _emailController,
                            borderColor: Colors.white24,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            hintText: 'Password',
                            controller: _passwordController,
                            obscureText: true,
                            borderColor: Colors.white24,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              final email = _emailController.text.trim();
                              final password = _passwordController.text.trim();
                              if (email.isEmpty || password.isEmpty) {
                                context.read<AuthBloc>().add(
                                  LocalErrorOccurred("Please fill in both fields."),
                                );
                              } else {
                                context.read<AuthBloc>().add(
                                  LoginWithEmailPasswordRequested(email: email, password: password),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF9C27B0), Color(0xFFE040FB)],
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: SizedBox(
                                height: 50,
                                width: double.infinity,
                                child: Center(
                                  child: isLoading
                                      ? const SpinKitFadingCircle(color: Colors.white, size: 40)
                                      : const Text(
                                          'Login',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (customErrorMessage != null)
                            Text(
                              customErrorMessage,
                              style: const TextStyle(color: Colors.redAccent),
                              textAlign: TextAlign.center,
                            ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.white24)),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('or', style: TextStyle(color: Colors.white60)),
                              ),
                              Expanded(child: Divider(color: Colors.white24)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          GoogleButton(
                            text: 'Continue with Google',
                            onPressed: () {
                              context.read<AuthBloc>().add(LoginRequested());
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(color: Colors.white70),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                  );
                                },
                                child: const Text(
                                  "Register",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

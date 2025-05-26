import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/google_button.dart';
import '../Bloc/state.dart';
import '../Bloc/bloc.dart';
import '../Bloc/event.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
        }
      },
      builder: (context, state) {
        String? customErrorMessage;

        if (state is LoginFailed || state is ShowError) {
          customErrorMessage = (state as dynamic).message;
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
                  child: Container(color: Colors.black.withAlpha(127)),
                ),
              ),
              Center(
                child: Container(
                  width: size.width * 0.85,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withAlpha(51)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(64),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Create Account',
                          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          hintText: 'Full Name',
                          controller: _nameController,
                          borderColor: Colors.white24,
                        ),
                        const SizedBox(height: 16),
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
                            final name = _nameController.text.trim();
                            final email = _emailController.text.trim();
                            final password = _passwordController.text.trim();

                            if (name.isEmpty || email.isEmpty || password.isEmpty) {
                              context.read<AuthBloc>().add(
                                LocalErrorOccurred("Please fill in all fields."),
                              );
                            } else if (password.length < 6) {
                              context.read<AuthBloc>().add(
                                LocalErrorOccurred("Password must be at least 6 characters."),
                              );
                            } else {
                              context.read<AuthBloc>().add(
                                RegisterWithEmailPasswordRequested(
                                  email: email,
                                  password: password,
                                  userName: name,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 0,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF9C27B0), Color(0xFFE040FB)],
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const SizedBox(
                              height: 50,
                              width: double.infinity,
                              child: Center(
                                child: Text(
                                  'Register',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GoogleButton(
                          text: 'Register with Google',
                          onPressed: () {
                            context.read<AuthBloc>().add(RegisterWithGoogleRequested());
                          },
                        ),
                        const SizedBox(height: 20),
                        if (customErrorMessage != null)
                          Text(
                            customErrorMessage,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account? ", style: TextStyle(color: Colors.white70)),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                              },
                              child: const Text(
                                "Login",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
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

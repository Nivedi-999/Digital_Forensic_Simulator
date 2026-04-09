import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future authenticate() async {
    setState(() => isLoading = true);

    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      body: Stack(
        children: [
          // 🔵 GLOW BACKGROUND
          Positioned(top: -100, left: -80, child: _glowCircle()),
          Positioned(
              bottom: -120,
              right: -80,
              child: _glowCircle(color: const Color(0xFFB026FF))),

          // 💎 GLASS CARD
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 25),
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: isLogin
                          ? const Color(0xFF00F0FF)
                          : const Color(0xFFB026FF),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isLogin
                            ? const Color(0xFF00F0FF)
                            : const Color(0xFFB026FF))
                            .withOpacity(0.6),
                        blurRadius: 30,
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLogin ? "ACCESS SYSTEM" : "CREATE ACCOUNT",
                        style: TextStyle(
                          color: isLogin
                              ? const Color(0xFF00F0FF)
                              : const Color(0xFFB026FF),
                          fontSize: 22,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 25),

                      _input("Email", emailController),
                      const SizedBox(height: 15),
                      _input("Password", passwordController, isPassword: true),

                      const SizedBox(height: 25),

                      GestureDetector(
                        onTap: isLoading ? null : authenticate,
                        child: _button(),
                      ),

                      const SizedBox(height: 15),

                      GestureDetector(
                        onTap: () {
                          setState(() => isLogin = !isLogin);
                        },
                        child: Text(
                          isLogin
                              ? "No account? Sign Up"
                              : "Already have account? Login",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 🔄 LOADING
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00F0FF),
              ),
            )
        ],
      ),
    );
  }

  Widget _glowCircle({Color color = const Color(0xFF00F0FF)}) {
    return Container(
      height: 250,
      width: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.3),
      ),
    );
  }

  Widget _input(String hint, TextEditingController controller,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.black.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _button() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: isLogin
              ? [const Color(0xFF00F0FF), const Color(0xFF0088FF)]
              : [const Color(0xFFB026FF), const Color(0xFF6A00FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: (isLogin
                ? const Color(0xFF00F0FF)
                : const Color(0xFFB026FF))
                .withOpacity(0.8),
            blurRadius: 25,
          )
        ],
      ),
      child: Center(
        child: Text(
          isLogin ? "LOGIN" : "SIGN UP",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
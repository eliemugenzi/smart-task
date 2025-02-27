// screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smarttask/components/button_component.dart';
import 'package:smarttask/utils/styles.dart'; // Assuming CustomStyles is defined here

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Animation duration
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    // Navigate to login after a delay (e.g., 2 seconds)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.goNamed('login'); // Adjust based on your GoRouter setup
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4A90E2), // Light blue at the top
                  Color(0xFF2D6CC0), // Darker blue at the bottom
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Opacity(
                  opacity: _controller.value, // Use animation value for fade effect
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Optional: Add a logo or icon
                      // Padding(
                      //   padding: const EdgeInsets.only(bottom: 20.0),
                      //   child: Image.asset(
                      //     'assets/smarttask_logo.png', // Replace with your logo path or use Text if no logo
                      //     width: 100.0,
                      //     height: 100.0,
                      //   ),
                      // ),
                      // Welcome text
                      Text(
                        'Welcome to',
                        style: CustomStyles.textLabelStyle.copyWith(
                          fontSize: 20.0,
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      // Brand name
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 32.0),
                        child: Text(
                          'SMART TASK',
                          style: CustomStyles.textLabelStyle.copyWith(
                            fontSize: 36.0,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Get started button
                      CustomButton(
                        text: 'Get started',
                        onPressed: () {
                          context.goNamed('signup'); // Navigate to signup screen
                        },
                        backgroundColor: Colors.white,
                        textColor: Colors.blue,
                      ),
                      const SizedBox(height: 16.0),
                      // Sign in link
                      TextButton(
                        onPressed: () {
                          context.goNamed('login'); // Navigate to login screen
                        },
                        child: Text(
                          'Already have an account? Sign in',
                          style: CustomStyles.textLabelStyle.copyWith(
                            fontSize: 16.0,
                            color: Colors.white,
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
      ),
    );
  }
}
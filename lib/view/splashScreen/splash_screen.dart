import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home.dart';
import '../login.dart';
import 'intro.dart';

class MysplashScreen extends StatefulWidget {
  const MysplashScreen({super.key});

  @override
  State<MysplashScreen> createState() => _MysplashScreenState();
}


class _MysplashScreenState extends State<MysplashScreen> {
  @override
  void initState() {
    super.initState();
    handleNavigation();
  }

  Future<void> handleNavigation() async {
    // This ensures the splash screen is visible for at least 2 seconds
    final splashTimer = Future.delayed(const Duration(seconds: 2));

    // Check if intro is completed
    final prefs = await SharedPreferences.getInstance();
    final isIntroCompleted = prefs.getBool('isIntroCompleted') ?? false;

    // Create a stream subscription to properly wait for auth state
    bool hasNavigated = false;

    // Properly declare the subscription variable first
    late final StreamSubscription<User?> subscription;

    // Then assign to it
    subscription = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      // Only navigate if we haven't already
      if (!hasNavigated && mounted) {
        // Wait for splash timer to complete
        await splashTimer;

        hasNavigated = true;

        if (!isIntroCompleted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => OnboardingPage()),
          );
        } else if (user != null) {
          print("User is logged in: ${user.email}");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          print("No user logged in, navigating to login screen");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        }

        // Clean up subscription
        subscription.cancel();
      }
    });

    // Add a timeout in case auth takes too long
    await Future.delayed(const Duration(seconds: 5));

    if (!hasNavigated && mounted) {
      hasNavigated = true;
      subscription.cancel();

      if (!isIntroCompleted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OnboardingPage()),
        );
      } else {
        // Default to login if auth check times out
        print("Auth check timed out, defaulting to login screen");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Your existing build method...
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: Center(
        child: Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            gradient: LinearGradient(
              colors: [Colors.orange.shade300, Colors.deepOrange.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: ClipOval(
              child: Image.asset(
                'assets/l.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ano/utils/notificationService.dart';
import 'package:ano/view/splashScreen/splash_screen.dart';

import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Define a top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
}







Future<void> checkForPlayStoreUpdates(BuildContext context) async {
  try {
    print('Checking for Play Store updates...');
    AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
    if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
      print("Update available: Version ${updateInfo.availableVersionCode}");
      await InAppUpdate.performImmediateUpdate();
    } else {
      print("No updates available.");
    }
  } catch (e) {
    print("Failed to check for updates: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('App starting...');

  // Initialize Firebase
  await Firebase.initializeApp();
  print('Firebase initialized');



  // Set the background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  print('Firebase messaging background handler set');

  // Initialize notification service
  await NotificationService().initialize();
  print('Notification service initialized');


  runApp(
    // Wrap your entire app with ProviderScope
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  // Time when the app went to background (for tracking background time)
  DateTime? _pausedTime;

  // Use the global instance
  // No need to create a new instance here

  // Minimum time app needs to be in background to show ad when resumed
  final Duration _minBackgroundDuration = const Duration(seconds: 30);
  bool _isInitialAdShown = false;

  @override
  void initState() {
    super.initState();
    print('MyApp initializing...');
    WidgetsBinding.instance.addObserver(this);


    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForPlayStoreUpdates(context);
    });
  }

  @override
  void dispose() {
    print('Disposing MyApp');
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drive Notes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MysplashScreen(),
    );
  }
}
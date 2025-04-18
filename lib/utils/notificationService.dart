import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Notification channel for Android
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // Initialize notifications for all platforms

  Future<bool> sendNotificationToToken({
    required String token,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Your FastAPI server endpoint for sending to tokens
      final Uri url = Uri.parse('https://chandugeesala0-allnotify.hf.space/send_notification_to_token');

      // Prepare request body
      final requestBody = {
        'title': title,
        'body': body,
        'token': token,
        'data': data
      };

      print('Sending notification to token: $token');

      // Make POST request to your FastAPI server
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          print('Successfully sent notification to token');
          return true;
        } else {
          print('Server returned error: ${responseData['error']}');
          return false;
        }
      } else {
        print('Failed to send notification. Status code: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending notification to token: $e');
      return false;
    }
  }





  Future<bool> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Your FastAPI server endpoint
      final Uri url = Uri.parse('https://chandugeesala0-allnotify.hf.space/send_notification');

      // Prepare request body
      final requestBody = {
        'title': title,
        'body': body,
        'topic': topic,
        'data': data
      };

      print('Sending notification to $url: $requestBody');

      // Make POST request to your FastAPI server
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          print('Successfully sent notification to topic: $topic');
          return true;
        } else {
          print('Server returned error: ${responseData['error']}');
          return false;
        }
      } else {
        print('Failed to send notification. Status code: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending notification to topic: $e');
      return false;
    }
  }


  Future<void> initialize() async {
    // Initialize local notifications
    await _initLocalNotifications();

    // Check and request permissions
    await checkAndRequestPermissions();

    // Setup FCM token handling
    await _setupTokenHandling();

    // Setup message handlers
    _setupMessageHandlers();

    // Subscribe to 'all' topic by default
    await subscribeToTopic('all');
  }



  Future<void> _initLocalNotifications() async {
    // Initialize Android settings
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize iOS settings
    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // Initialize settings for all platforms
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification taps here
        print('Notification clicked: ${response.payload}');
        // You can add navigation logic here
      },
    );

    // Create notification channel for Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // This method will be called each time the app opens
  Future<bool> checkAndRequestPermissions() async {
    // Check current permission status for FCM
    NotificationSettings currentSettings = await _firebaseMessaging.getNotificationSettings();

    // If permissions are not authorized, request them
    if (currentSettings.authorizationStatus != AuthorizationStatus.authorized) {
      // Request permissions for Firebase Messaging
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
        announcement: false,
        carPlay: false,
      );

      print('User granted FCM permission: ${settings.authorizationStatus}');

      // For Android 13+ (API level 33+), request permission using the appropriate method
      if (Platform.isAndroid) {
        // This is the correct way to request permission on newer Flutter Local Notifications versions
        // Flutter Local Notifications will use the Android permission system for Android 13+
        // For older Android versions, this will have no effect as permissions are granted by default
        final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

        if (androidPlugin != null) {
          // The correct way depends on your flutter_local_notifications version
          // For newer versions:
          try {
            final bool? granted = await androidPlugin.requestNotificationsPermission();
            print('Android notification permission granted: $granted');
          } catch (e) {
            // If the method doesn't exist (older versions), this will be caught
            print('Android notification permission request method not available: $e');

            // For older versions or if the method doesn't exist, we can use this approach
            try {
              final bool? granted = await androidPlugin.areNotificationsEnabled();
              print('Android notifications enabled: $granted');
            } catch (e) {
              print('Could not check Android notification status: $e');
            }
          }
        }
      }

      return settings.authorizationStatus == AuthorizationStatus.authorized;
    }

    print('Notification permissions already granted');
    return true;
  }

  Future<void> _setupTokenHandling() async {
    // Get the token
    String? token = await _firebaseMessaging.getToken();

    if (token != null) {
      // Store token in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', token);
      print('Stored FCM Token: $token');

      // Here you would typically send this token to your backend
      // await sendTokenToServer(token);
    }

    // Listen for token refreshes
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', newToken);
      print('Updated FCM Token: $newToken');

      // Update token on your server
      // await sendTokenToServer(newToken);
    });
  }

  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    // Handle when the app is opened from a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // Navigate to relevant screen based on the notification data
      // Navigator.pushNamed(context, '/notification_details', arguments: message);
    });
  }

  Future<void> checkInitialMessage() async {
    // Check if the app was opened from a terminated state via notification
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('App launched by notification!');
      // Handle navigation based on the notification data
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data['route'],
      );
    }
  }

  // Method to subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  // Method to unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  // Method to manually send a local notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }
}
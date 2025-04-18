// lib/services/auth_service.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Dio _dio = Dio();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.file', // Access to files created by the app
      'https://www.googleapis.com/auth/drive.appdata', // Access to application data folder
    ],
  );

  // Stream to check authentication state
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  // Validate email domain specifically for your college
  bool isValidCollegeEmail(String email) {
    final trimmedEmail = email.trim().toLowerCase();
    final validDomains = ['@rguktn.ac.in', '@rguktsklm.ac.in', '@gmail.com'];

    // Check for specific allowed test email
    if (trimmedEmail == 'panindiatrip1464@gmail.com') {
      return true;
    }

    // Check for allowed domains
    return validDomains.any((domain) => trimmedEmail.endsWith(domain));
  }

  // Check if user is signed in
  Future<bool> isSignedIn() async {
    return _auth.currentUser != null && await _googleSignIn.isSignedIn();
  }

  // Google Sign-In with Firebase Auth and Drive permissions
  Future<User?> signInWithGoogle() async {
    try {
      // Sign out first to clear any previous sessions
      await _googleSignIn.signOut();

      // Force account selection to prevent automatic reuse of invalid account
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google Sign-In cancelled');
        return null;
      }

      // Debug log: Print the email received from Google Sign-In
      print('Received email from Google Sign-In: ${googleUser.email}');

      // Validate college email domain
      if (!isValidCollegeEmail(googleUser.email)) {
        print('Invalid college email: ${googleUser.email}');
        // Sign out to prevent the invalid account from being cached
        await _googleSignIn.signOut();
        throw Exception('Invalid college email. Please use an approved email domain.');
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Store tokens securely
      await _secureStorage.write(key: 'accessToken', value: googleAuth.accessToken);
      await _secureStorage.write(key: 'idToken', value: googleAuth.idToken);

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential authResult = await _auth.signInWithCredential(credential);
      final User? user = authResult.user;

      if (user != null) {
        await _storeUserDetails(user);
      }

      return user;
    } catch (e) {
      print('Error during Google Sign-In: $e');
      // Ensure we're signed out on any error
      await _googleSignIn.signOut();
      rethrow;
    }
  }

  // Store User Details in Firestore
  Future<void> _storeUserDetails(User user) async {
    try {
      final userData = {
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoURL': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      };

      // Store or update user details in Firestore
      await _firestore.collection('users').doc(user.uid).set(
          userData,
          SetOptions(merge: true)
      );
      print('User details stored successfully');
    } catch (e) {
      print('Error storing user details: $e');
    }
  }

  // Get Drive client
  Future<drive.DriveApi?> getDriveApi() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) {
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Fix: Convert expiry time to UTC
      final expiryTime = DateTime.now().toUtc().add(const Duration(hours: 1));

      final AccessCredentials credentials = AccessCredentials(
        AccessToken(
          'Bearer',
          googleAuth.accessToken!,
          expiryTime, // Using UTC time for expiry
        ),
        null, // refreshToken not needed with Google Sign-In
        [
          'https://www.googleapis.com/auth/drive.file',
          'https://www.googleapis.com/auth/drive.appdata',
        ],
      );

      final client = authenticatedClient(
        clientViaApiKey(''), // Replace with your API key if needed
        credentials,
      );

      return drive.DriveApi(client);
    } catch (e) {
      print('Error getting Drive API: $e');
      return null;
    }
  }

  // Check for token expiration and refresh if needed
  Future<String?> getValidAccessToken() async {
    try {
      String? accessToken = await _secureStorage.read(key: 'accessToken');

      if (accessToken == null) {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
        if (googleUser == null) {
          return null;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        accessToken = googleAuth.accessToken;

        // Update stored token
        await _secureStorage.write(key: 'accessToken', value: accessToken);
      }

      return accessToken;
    } catch (e) {
      print('Error getting valid access token: $e');
      return null;
    }
  }

  // Sign Out Method
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      await _secureStorage.delete(key: 'accessToken');
      await _secureStorage.delete(key: 'idToken');
      print('User signed out successfully');
    } catch (e) {
      print('Error during sign out: $e');
    }
  }

  // Get Current Firebase User - this is the method used in HomeScreen
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  // Get Current Google User
  Future<GoogleSignInAccount?> getCurrentGoogleUser() async {
    return _googleSignIn.currentUser;
  }
}

// Riverpod provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});
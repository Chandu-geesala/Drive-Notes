import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ano/viewModel/authService.dart';
// User profile model class (Add this to your models directory)
class UserProfile {
  final String? displayName;
  final String? email;
  final String? photoUrl;

  UserProfile({
    this.displayName,
    this.email,
    this.photoUrl,
  });
}

// User provider (Add this to your providers directory)
final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final user = await authService.getCurrentUser();

  if (user == null) {
    throw Exception('User not signed in');
  }

  return UserProfile(
    displayName: user.displayName,
    email: user.email,
    photoUrl: user.photoURL,
  );
});
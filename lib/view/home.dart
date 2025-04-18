// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ano/viewModel/authService.dart';
import 'package:ano/providers/notes_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:heroicons/heroicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart'; // Added Lottie import
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Added notifications import

import '../providers/theme_provider.dart';
import 'notes_screen.dart';
import 'package:ano/viewModel/drive_service.dart';
import 'package:intl/intl.dart';
import 'package:ano/view/login.dart';


class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isFirstLaunch = false;
  bool _showWelcomeAnimation = false;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _initializeNotifications();
    _checkIfFirstLaunch();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  Future<void> _checkIfFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstLaunch = !(prefs.getBool('has_launched_before') ?? false);

    if (_isFirstLaunch) {
      // Set the flag for future launches
      await prefs.setBool('has_launched_before', true);

      setState(() {
        _showWelcomeAnimation = true;
      });

      // Get user name for notification
      final authService = ref.read(authServiceProvider);
      final user = await authService.getCurrentUser();
      final userName = user?.displayName?.split(' ')[0] ?? 'User';

      // Wait a moment and then show notification
      Future.delayed(const Duration(seconds: 2), () {
        _showWelcomeNotification(userName);
      });

      // Hide animation after it plays
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _showWelcomeAnimation = false;
          });
        }
      });
    }
  }

  Future<void> _showWelcomeNotification(String userName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'welcome_channel',
      'Welcome Notifications',
      channelDescription: 'Notifications for welcoming users',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
    DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Welcome to DriveNotes!',
      'Welcome $userName! This is Chandu, adding more features is my hobby. Enjoy the app!',
      platformChannelSpecifics,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final notesAsync = ref.watch(notesProvider);
    final isDarkMode = ref.watch(themeProvider);

    // App theme colors
    final primaryColor = const Color(0xFF4ECDC4);
    final backgroundColor = isDarkMode ? const Color(0xFF1A202C) : const Color(0xFFF7F9FB);
    final cardColor = isDarkMode ? const Color(0xFF2D3748) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.grey[700];

    // Update animation controller based on theme
    if (isDarkMode) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: isDarkMode ? const Color(0xFF2D3748) : primaryColor,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: Image.asset(
                    'assets/l.png',
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            title: Text(
              'DriveNotes',
              style: GoogleFonts.quicksand(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            actions: [

              IconButton(
                icon: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),
                  firstChild: const Icon(
                    Icons.light_mode,
                    color: Colors.white,
                  ),
                  secondChild: const Icon(
                    Icons.dark_mode,
                    color: Colors.black,
                  ),
                  crossFadeState: isDarkMode
                      ? CrossFadeState.showFirst  // Show light_mode (sun) icon in dark mode
                      : CrossFadeState.showSecond, // Show dark_mode (moon) icon in light mode
                ),
                onPressed: () {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              ),

              // Logout Button
              IconButton(
                icon: const HeroIcon(
                  HeroIcons.arrowRightOnRectangle,
                  style: HeroIconStyle.solid,
                  color: Colors.redAccent,
                  size: 22,
                ),
                onPressed: () async {
                  await authService.signOut();
                  if (!mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // User greeting header
              FutureBuilder(
                future: authService.getCurrentUser(),
                builder: (context, snapshot) {
                  final userName = snapshot.data?.displayName?.split(' ')[0] ?? 'User';

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF2D3748) : primaryColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white,
                              child: snapshot.data?.photoURL != null
                                  ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: snapshot.data!.photoURL!,
                                  placeholder: (context, url) => const CircularProgressIndicator(),
                                  errorWidget: (context, url, error) => const Icon(Icons.person),
                                  fit: BoxFit.cover,
                                  width: 48,
                                  height: 48,
                                ),
                              )
                                  : const Icon(Icons.person, color: Color(0xFF4ECDC4)),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, $userName! 👋',
                                  style: GoogleFonts.quicksand(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Ready to organize your thoughts?',
                                  style: GoogleFonts.quicksand(
                                    fontSize: 15,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),

              // Notes content
              Expanded(
                child: notesAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  ),
                  error: (error, stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading notes:',
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          error.toString(),
                          style: TextStyle(color: secondaryTextColor),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.read(notesProvider.notifier).refreshNotes();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                  data: (notes) {
                    if (notes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_alt_outlined,
                              size: 80,
                              color: isDarkMode ? Colors.white38 : Colors.grey[400],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No notes yet',
                              style: GoogleFonts.quicksand(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tap + to create your first note',
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                _createNewNote(context, ref);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Create New Note'),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: primaryColor,
                      onRefresh: () => ref.read(notesProvider.notifier).refreshNotes(),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.95,
                          ),
                          itemCount: notes.length,
                          itemBuilder: (context, index) {
                            final note = notes[index];
                            final formattedDate = note.modifiedTime != null
                                ? DateFormat('MMM d, yyyy').format(note.modifiedTime!)
                                : 'Unknown date';

                            // Note card colors
                            final noteColors = [
                              isDarkMode ? const Color(0xFF3B506E) : const Color(0xFFE3F6F5),
                              isDarkMode ? const Color(0xFF564256) : const Color(0xFFFFF1E6),
                              isDarkMode ? const Color(0xFF374151) : const Color(0xFFE2ECE9),
                              isDarkMode ? const Color(0xFF474973) : const Color(0xFFEBF4F0),
                            ];
                            final cardBackground = noteColors[index % noteColors.length];

                            return GestureDetector(
                              onTap: () => _openNote(context, ref, note),
                              onLongPress: () => _showDeleteDialog(context, ref, note),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cardBackground,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: isDarkMode
                                              ? Colors.white.withOpacity(0.2)
                                              : primaryColor.withOpacity(0.2),
                                          child: Icon(
                                            Icons.description,
                                            size: 16,
                                            color: isDarkMode ? Colors.white : primaryColor,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.more_vert,
                                            color: isDarkMode ? Colors.white70 : Colors.black54,
                                            size: 20,
                                          ),
                                          onPressed: () => _showOptionsBottomSheet(context, ref, note),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      note.name,
                                      style: GoogleFonts.quicksand(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 12,
                                          color: secondaryTextColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          formattedDate,
                                          style: GoogleFonts.quicksand(
                                            fontSize: 12,
                                            color: secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _createNewNote(context, ref);
            },
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),

        // Welcome Lottie Animation Overlay (conditionally displayed)
        if (_showWelcomeAnimation)
          Container(
            color: backgroundColor.withOpacity(0.9),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: Lottie.asset(
                    'assets/wel.json',
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to DriveNotes!',
                  style: GoogleFonts.quicksand(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _createNewNote(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteScreen.create(),
      ),
    ).then((_) {
      // Refresh the notes list when returning from note screen
      ref.read(notesProvider.notifier).refreshNotes();
    });
  }

  void _openNote(BuildContext context, WidgetRef ref, NoteItem note) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteScreen.edit(noteId: note.id, noteTitle: note.name),
      ),
    ).then((_) {
      // Refresh the notes list when returning from note screen
      ref.read(notesProvider.notifier).refreshNotes();
    });
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, NoteItem note) {
    final isDarkMode = ref.read(themeProvider);
    final dialogBackgroundColor = isDarkMode ? const Color(0xFF2D3748) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Note',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${note.name}"?',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(notesProvider.notifier).deleteNote(note.id);
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showOptionsBottomSheet(BuildContext context, WidgetRef ref, NoteItem note) {
    final isDarkMode = ref.read(themeProvider);
    final sheetBackgroundColor = isDarkMode ? const Color(0xFF2D3748) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final primaryColor = const Color(0xFF4ECDC4);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const HeroIcon(
                HeroIcons.pencil,
                style: HeroIconStyle.solid,
                color: Color(0xFF4ECDC4),
              ),
              title: Text(
                'Edit Note',
                style: TextStyle(color: textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _openNote(context, ref, note);
              },
            ),
            ListTile(
              leading: const HeroIcon(
                HeroIcons.share,
                style: HeroIconStyle.solid,
                color: Color(0xFF4ECDC4),
              ),
              title: Text(
                'Share Note',
                style: TextStyle(color: textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                // Implement share functionality
              },
            ),
            ListTile(
              leading: const HeroIcon(
                HeroIcons.trash,
                style: HeroIconStyle.solid,
                color: Colors.red,
              ),
              title: Text(
                'Delete Note',
                style: TextStyle(color: textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context, ref, note);
              },
            ),
          ],
        ),
      ),
    );
  }
}
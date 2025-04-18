import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ano/viewModel/authService.dart';
import 'home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Check if dark mode is enabled
  bool isDarkMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.signInWithGoogle();

      setState(() {
        _isLoading = false;
      });

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        _showErrorSnackBar('Login failed. Please try again');
      }
    } catch (e, stacktrace) {
      setState(() {
        _isLoading = false;
      });

      _showErrorSnackBar('Login failed, please use your college email');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(10),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get theme mode
    final darkMode = isDarkMode(context);

    // Dynamic colors based on theme
    final gradientStartColor = darkMode ? Color(0xFF1E3A5F) : Color(0xFF4ECDC4);
    final gradientEndColor = darkMode ? Color(0xFF0F1C2E) : Color(0xFF45B7D1);
    final cardColor = darkMode ? Color(0xFF1E2430) : Colors.white;
    final textColor = darkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = darkMode ? Colors.white70 : Colors.black54;
    final buttonTextColor = darkMode ? Colors.white : Colors.black87;
    final buttonColor = darkMode ? Color(0xFF3A4D6B) : Colors.white;
    final highlightColor = darkMode ? Color(0xFF64FFDA) : Color(0xFF4ECDC4);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradientStartColor,
              gradientEndColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeInAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Card Container
                    Container(
                      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // App Logo with shadow
                          Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: highlightColor.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child:   ClipOval(
                              child: Image.asset(
                                'assets/l.png',
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(height: 24),

                          // App Name with custom font
                          Text(
                            'Drive Notes',
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: highlightColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 12),

                          // Welcome Text
                          Text(
                            'Your notes, synced with Google Drive ',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.quicksand(
                              fontSize: 16,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 40),

                          // Google Sign In Button
                          _isLoading
                              ? SizedBox(
                            height: 50,
                            width: 50,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(highlightColor),
                              strokeWidth: 3,
                            ),
                          )
                              : Container(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                foregroundColor: buttonTextColor,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                              ),
                              icon: Container(
                                height: 25,
                                width: 25,
                                padding: EdgeInsets.all(2),
                                child: Image.asset(
                                  'assets/gg.png',
                                  height: 24,
                                  width: 24,
                                ),
                              ),
                              label: Text(
                                'Sign in with Google',
                                style: GoogleFonts.quicksand(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: _handleSignIn,
                            ),
                          ),
                          SizedBox(height: 24),

                          // College Email Notice - Improved from red text
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: darkMode
                                  ? Colors.blueGrey.shade900.withOpacity(0.6)
                                  : Colors.blueGrey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: highlightColor.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: highlightColor,
                                ),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    ' You need to grant Drive permissions for this app to work',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.quicksand(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Version info at bottom
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Text(
                       ''
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
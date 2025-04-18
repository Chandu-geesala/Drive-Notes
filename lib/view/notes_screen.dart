// lib/screens/note_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ano/providers/notes_provider.dart';
import 'package:ano/viewModel/drive_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import '../providers/theme_provider.dart';


class NoteScreen extends ConsumerStatefulWidget {
  final String? noteId;
  final String? noteTitle;
  final bool isEditing;

  const NoteScreen._({
    this.noteId,
    this.noteTitle,
    required this.isEditing,
    Key? key,
  }) : super(key: key);

  // Factory constructor for creating a new note
  factory NoteScreen.create() {
    return const NoteScreen._(isEditing: false);
  }

  // Factory constructor for editing an existing note
  factory NoteScreen.edit({required String noteId, required String noteTitle}) {
    return NoteScreen._(
      noteId: noteId,
      noteTitle: noteTitle,
      isEditing: true,
    );
  }

  @override
  ConsumerState<NoteScreen> createState() => _NoteScreenState();
}

class _NoteScreenState extends ConsumerState<NoteScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late AnimationController _animationController;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _contentChanged = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.noteTitle);
    _contentController = TextEditingController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _contentController.addListener(() {
      if (!_isLoading) {
        setState(() {
          _contentChanged = true;
        });
      }
    });

    if (widget.isEditing && widget.noteId != null) {
      _loadNoteContent();
    }
  }

  Future<void> _loadNoteContent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final content = await ref.read(noteContentProvider(widget.noteId!).future);
      if (content != null) {
        setState(() {
          _contentController.text = content;
          _contentChanged = false;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error loading note: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text;

    if (title.isEmpty) {
      _showErrorSnackbar('Please enter a title for your note');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.isEditing && widget.noteId != null) {
        // Update existing note
        final driveService = ref.read(driveServiceProvider);
        final success = await driveService.updateNote(widget.noteId!, content);

        if (success) {
          _showSuccessSnackbar('Note updated successfully');
          setState(() {
            _contentChanged = false;
          });
          Navigator.of(context).pop();
        } else {
          _showErrorSnackbar('Failed to update note. Please try again.');
        }
      } else {
        // Create new note
        await ref.read(notesProvider.notifier).createNote(title, content);
        _showSuccessSnackbar('Note created successfully');
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackbar('Error saving note: ${e.toString()}');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_contentChanged) {
      // Show dialog if content was changed
      final isDarkMode = ref.read(themeProvider);
      final dialogBackgroundColor = isDarkMode ? const Color(0xFF2D3748) : Colors.white;
      final textColor = isDarkMode ? Colors.white : Colors.black;

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: dialogBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber),
              const SizedBox(width: 1),
              Text(
                'Unsaved Changes',
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          content: Text(
            'You have unsaved changes. Are you sure you want to discard them?',
            style: GoogleFonts.quicksand(color: textColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Stay',
                style: GoogleFonts.quicksand(
                  color: const Color(0xFF4ECDC4),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.red.shade900 : Colors.red.shade50,
                foregroundColor: isDarkMode ? Colors.white : Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Discard Changes',
                style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider);

    // App theme colors
    final primaryColor = const Color(0xFF4ECDC4);
    final backgroundColor = isDarkMode ? const Color(0xFF1A202C) : const Color(0xFFF7F9FB);
    final cardColor = isDarkMode ? const Color(0xFF2D3748) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.grey[700];
    final iconColor = isDarkMode ? Colors.white70 : primaryColor;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: isDarkMode ? const Color(0xFF2D3748) : primaryColor,
          leading: IconButton(
            icon: const HeroIcon(
              HeroIcons.arrowLeft,
              style: HeroIconStyle.solid,
              color: Colors.white,
            ),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          title: Text(
            widget.isEditing ? 'Edit Note' : 'New Note',
            style: GoogleFonts.quicksand(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          actions: [
            if (_contentChanged && !_isSaving)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.edit_outlined, color: Colors.white, size: 18),
              ),
            _isSaving
                ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
                : Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton.icon(
                onPressed: _saveNote,
                icon: const HeroIcon(
                  HeroIcons.check,
                  style: HeroIconStyle.solid,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  'Save',
                  style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? const Color(0xFF4A5568) : Colors.white24,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                isDarkMode ? const Color(0xFF2D3748) : primaryColor,
                backgroundColor,
              ],
              stops: const [0.0, 0.2],
            ),
          ),
          child: _isLoading
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: primaryColor),
                const SizedBox(height: 16),
                Text(
                  'Loading note content...',
                  style: GoogleFonts.quicksand(color: textColor),
                ),
              ],
            ),
          )
              : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: GoogleFonts.quicksand(
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: cardColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        prefixIcon: HeroIcon(
                          HeroIcons.documentText,
                          style: HeroIconStyle.solid,
                          color: iconColor,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      readOnly: widget.isEditing, // Title can't be edited for existing notes
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.65,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        hintText: 'Start typing your note...',
                        hintStyle: GoogleFonts.quicksand(
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w400,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: cardColor,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                      maxLines: null,
                      expands: true,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        height: 1.5,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: _isLoading || widget.isEditing == false
            ? null
            : Container(
          height: 60,
          decoration: BoxDecoration(
            color: cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const HeroIcon(
                HeroIcons.clock,
                style: HeroIconStyle.outline,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Last edited: ${widget.noteTitle != null ? 'Today' : 'Unknown'}',
                style: GoogleFonts.quicksand(
                  color: secondaryTextColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
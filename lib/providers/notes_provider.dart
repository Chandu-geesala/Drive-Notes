// lib/providers/notes_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ano/viewModel/drive_service.dart';

// State notifier to handle notes list
class NotesNotifier extends AsyncNotifier<List<NoteItem>> {
  @override
  Future<List<NoteItem>> build() async {
    return await _fetchNotes();
  }

  Future<List<NoteItem>> _fetchNotes() async {
    final driveService = ref.read(driveServiceProvider);
    return await driveService.listNotes();
  }

  Future<void> refreshNotes() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchNotes);
  }

  Future<void> createNote(String title, String content) async {
    final driveService = ref.read(driveServiceProvider);
    await driveService.createNote(title, content);
    refreshNotes();
  }

  Future<void> deleteNote(String fileId) async {
    final driveService = ref.read(driveServiceProvider);
    final success = await driveService.deleteNote(fileId);
    if (success) {
      refreshNotes();
    }
  }
}

// Provider for notes state
final notesProvider = AsyncNotifierProvider<NotesNotifier, List<NoteItem>>(() {
  return NotesNotifier();
});

// Provider for a specific note content
final noteContentProvider = FutureProvider.family<String?, String>((ref, fileId) async {
  final driveService = ref.read(driveServiceProvider);
  return await driveService.getNoteContent(fileId);
});
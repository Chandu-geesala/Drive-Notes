import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ano/viewModel/authService.dart';

class NoteItem {
  final String id;
  final String name;
  final String? content;
  final DateTime? modifiedTime;

  NoteItem({
    required this.id,
    required this.name,
    this.content,
    this.modifiedTime,
  });

  factory NoteItem.fromDriveFile(drive.File file) {
    return NoteItem(
      id: file.id ?? '',
      name: file.name?.replaceAll('.txt', '') ?? 'Untitled Note',
      modifiedTime: file.modifiedTime,
    );
  }
}

class DriveService {
  final AuthService _authService;
  static const String folderName = 'DriveNotes';
  String? _driveNotesFolderId;

  DriveService(this._authService);

  // Get or create DriveNotes folder
  Future<String?> getDriveNotesFolderId() async {
    if (_driveNotesFolderId != null) return _driveNotesFolderId;

    final driveApi = await _authService.getDriveApi();
    if (driveApi == null) return null;

    // Search for existing DriveNotes folder
    final folderList = await driveApi.files.list(
      q: "name='$folderName' and mimeType='application/vnd.google-apps.folder' and trashed=false",
      spaces: 'drive',
    );

    // Return existing folder ID if found
    if (folderList.files != null && folderList.files!.isNotEmpty) {
      _driveNotesFolderId = folderList.files!.first.id;
      return _driveNotesFolderId;
    }

    // Create new folder if not found
    final folder = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final createdFolder = await driveApi.files.create(folder);
    _driveNotesFolderId = createdFolder.id;
    return _driveNotesFolderId;
  }

  // List all notes from the DriveNotes folder
  Future<List<NoteItem>> listNotes() async {
    final driveApi = await _authService.getDriveApi();
    if (driveApi == null) return [];

    final folderId = await getDriveNotesFolderId();
    if (folderId == null) return [];

    final fileList = await driveApi.files.list(
      q: "'$folderId' in parents and mimeType='text/plain' and trashed=false",
      spaces: 'drive',
      orderBy: 'modifiedTime desc',
        $fields: 'files(id, name, modifiedTime)'
    );

    if (fileList.files == null) return [];

    return fileList.files!
        .map((file) => NoteItem.fromDriveFile(file))
        .toList();
  }

  // Create a new note
  Future<NoteItem?> createNote(String title, String content) async {
    final driveApi = await _authService.getDriveApi();
    if (driveApi == null) return null;

    final folderId = await getDriveNotesFolderId();
    if (folderId == null) return null;

    // Ensure the title has a .txt extension
    String fileName = title.endsWith('.txt') ? title : '$title.txt';

    // Create the file metadata
    final file = drive.File()
      ..name = fileName
      ..parents = [folderId]
      ..mimeType = 'text/plain';

    // Convert content to bytes
    final bytes = utf8.encode(content);

    // Upload the file
    final result = await driveApi.files.create(
      file,
      uploadMedia: drive.Media(
        Stream.value(bytes),
        bytes.length,
      ),
    );

    return result.id != null
        ? NoteItem(
      id: result.id!,
      name: title,
      content: content,
      modifiedTime: DateTime.now(),
    )
        : null;
  }

  // Get the content of a note
  Future<String?> getNoteContent(String fileId) async {
    final driveApi = await _authService.getDriveApi();
    if (driveApi == null) return null;

    final media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final List<int> dataStore = [];
    await for (final data in media.stream) {
      dataStore.addAll(data);
    }

    return utf8.decode(dataStore);
  }

  // Update an existing note
  Future<bool> updateNote(String fileId, String content) async {
    final driveApi = await _authService.getDriveApi();
    if (driveApi == null) return false;

    // Convert content to bytes
    final bytes = utf8.encode(content);

    try {
      await driveApi.files.update(
        drive.File(),
        fileId,
        uploadMedia: drive.Media(
          Stream.value(bytes),
          bytes.length,
        ),
      );
      return true;
    } catch (e) {
      print('Error updating note: $e');
      return false;
    }
  }

  // Delete a note
  Future<bool> deleteNote(String fileId) async {
    final driveApi = await _authService.getDriveApi();
    if (driveApi == null) return false;

    try {
      await driveApi.files.delete(fileId);
      return true;
    } catch (e) {
      print('Error deleting note: $e');
      return false;
    }
  }
}

// Riverpod provider for DriveService
final driveServiceProvider = Provider<DriveService>((ref) {
  final authService = ref.watch(authServiceProvider);
  return DriveService(authService);
});
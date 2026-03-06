// lib/core/services/drive_backup_service.dart
//
// Google Drive backup using the user's Supabase access token.
//
// HOW IT WORKS:
//   • Each user has ONE file in their personal Drive: "plume_backup.json"
//   • The file ID is cached in SharedPreferences after first creation
//   • Backup  = serialize all transactions → upload/update the file
//   • Restore = download the file → import into Hive
//
// GOOGLE CLOUD SETUP (one-time, free):
//   1. console.cloud.google.com → New project "Plume"
//   2. APIs & Services → Enable "Google Drive API"
//   3. OAuth 2.0 → Create credentials → Android app
//      → Package name: com.yourname.plume
//      → SHA-1: run `keytool -list -v -keystore debug.keystore`
//   4. Add "https://www.googleapis.com/auth/drive.file" scope
//   NOTE: drive.file scope = only files created by THIS app. Very safe.
//
// The Supabase access token is a JWT — we use it to call the Drive REST API
// directly with the googleapis package (no google_sign_in SDK needed).

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../services/auth_service.dart';
import '../../data/datasources/local_datasource.dart';

class DriveBackupService {
  static final DriveBackupService _i = DriveBackupService._();
  factory DriveBackupService() => _i;
  DriveBackupService._();

  static const String _driveApiBase   = 'https://www.googleapis.com/drive/v3';
  static const String _uploadApiBase  = 'https://www.googleapis.com/upload/drive/v3';
  static const String _fileName       = 'plume_backup.json';
  static const String _mimeType       = 'application/json';
  static const String _driveScope     = 'https://www.googleapis.com/auth/drive.file';

  String? get _token => AuthService().accessToken;

  // ── PUBLIC API ────────────────────────────────────────────────────────────

  /// Full backup: serialize all local data → upload to Drive.
  /// Returns null on success, error message on failure.
  Future<String?> backup() async {
    if (_token == null) return 'Non connecté. Connectez-vous pour sauvegarder.';
    try {
      final data    = LocalDataSource().exportAllAsJson();
      final payload = jsonEncode({
        'version':      1,
        'backedUpAt':   DateTime.now().toIso8601String(),
        'transactions': data,
      });

      final fileId = await _getOrCreateFileId();
      if (fileId == null) return 'Impossible de créer le fichier de sauvegarde.';

      await _uploadContent(fileId, payload);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.lastSyncKey,
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
      return null; // success
    } catch (e) {
      return 'Erreur de sauvegarde : $e';
    }
  }

  /// Restore: download from Drive → import into Hive (merge, no duplicates).
  /// Returns number of transactions restored, or throws.
  Future<int> restore() async {
    if (_token == null) throw Exception('Non connecté.');

    final fileId = await _findExistingFileId();
    if (fileId == null) throw Exception('Aucune sauvegarde trouvée pour ce compte.');

    final content = await _downloadContent(fileId);
    final json    = jsonDecode(content) as Map<String, dynamic>;
    final txList  = (json['transactions'] as List).cast<Map<String, dynamic>>();
    await LocalDataSource().importFromJson(txList);
    return txList.length;
  }

  /// Returns the DateTime of the last successful sync, or null.
  Future<DateTime?> lastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString(AppConstants.lastSyncKey);
    if (ts == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(int.parse(ts));
  }

  // ── DRIVE FILE MANAGEMENT ─────────────────────────────────────────────────

  Future<String?> _getOrCreateFileId() async {
    // Check cache first
    final prefs    = await SharedPreferences.getInstance();
    final cachedId = prefs.getString(AppConstants.driveFileIdKey);
    if (cachedId != null) return cachedId;

    // Search Drive for existing file
    final existingId = await _findExistingFileId();
    if (existingId != null) {
      await prefs.setString(AppConstants.driveFileIdKey, existingId);
      return existingId;
    }

    // Create new file
    final newId = await _createEmptyFile();
    if (newId != null) {
      await prefs.setString(AppConstants.driveFileIdKey, newId);
    }
    return newId;
  }

  Future<String?> _findExistingFileId() async {
    final uri = Uri.parse(
      '$_driveApiBase/files'
      '?q=name%3D%22$_fileName%22%20and%20trashed%3Dfalse'
      '&fields=files(id,name)'
      '&spaces=drive',
    );
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) return null;
    final files = (jsonDecode(res.body)['files'] as List);
    if (files.isEmpty) return null;
    return files.first['id'] as String;
  }

  Future<String?> _createEmptyFile() async {
    final uri = Uri.parse('$_driveApiBase/files');
    final res = await http.post(
      uri,
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'name': _fileName, 'mimeType': _mimeType}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) return null;
    return jsonDecode(res.body)['id'] as String;
  }

  Future<void> _uploadContent(String fileId, String content) async {
    final uri = Uri.parse('$_uploadApiBase/files/$fileId?uploadType=media');
    final res = await http.patch(
      uri,
      headers: {..._headers, 'Content-Type': _mimeType},
      body: utf8.encode(content),
    );
    if (res.statusCode != 200) {
      throw Exception('Upload failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<String> _downloadContent(String fileId) async {
    final uri = Uri.parse('$_driveApiBase/files/$fileId?alt=media');
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode != 200) {
      throw Exception('Download failed: ${res.statusCode}');
    }
    return utf8.decode(res.bodyBytes);
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_token',
    'Accept': 'application/json',
  };
}
// lib/core/utils/backup_service.dart
//
// Email-based backup/restore — no cloud account required.
// Flow:
//   BACKUP:  encode all transactions as Base64 JSON → compose an email to the
//            user's own address with the data as body → user saves it in their inbox.
//   RESTORE: user pastes the backup text → we decode and import.
//
// This approach works 100% offline-first and requires no server or API key.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/datasources/local_datasource.dart';

class BackupService {
  static final BackupService _instance = BackupService._();
  factory BackupService() => _instance;
  BackupService._();

  static const String _header = 'MONNAIE_BACKUP_V1:';

  // ── BACKUP ────────────────────────────────────────────────────────────────

  /// Encode all transactions and share / send as email.
  Future<void> sendBackupByEmail({required String email}) async {
    final data    = LocalDataSource().exportAllAsJson();
    final jsonStr = jsonEncode(data);
    final encoded = base64Encode(utf8.encode(jsonStr));
    final payload = '$_header$encoded';

    final now      = DateTime.now();
    final dateStr  = '${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year}';
    final subject  = 'Plume – Sauvegarde du $dateStr';
    final body     = 'Conservez cet email pour restaurer vos données Plume.\n\n$payload';

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback: share as text
      await Share.share(
        body,
        subject: subject,
      );
    }
  }

  // ── RESTORE ───────────────────────────────────────────────────────────────

  /// Returns true if the paste looks like a valid backup payload.
  bool isValidBackup(String text) {
    return text.trim().startsWith(_header);
  }

  /// Decodes and imports backup data. Returns the number of transactions restored.
  Future<int> restoreFromText(String text) async {
    final trimmed = text.trim();
    if (!trimmed.startsWith(_header)) {
      throw FormatException('Ce texte ne contient pas une sauvegarde Monnaie valide.');
    }
    final encoded  = trimmed.substring(_header.length);
    final jsonStr  = utf8.decode(base64Decode(encoded));
    final data     = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
    await LocalDataSource().importFromJson(data);
    return data.length;
  }
}
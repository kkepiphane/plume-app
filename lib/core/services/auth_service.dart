// lib/core/services/auth_service.dart
//
// OTP email auth via Supabase.
//
// ── SETUP SUPABASE POUR RECEVOIR UN CODE (pas un lien) ───────────────────────
// Dans votre dashboard Supabase :
//   1. Authentication → Email Templates → "Magic Link"
//      Remplacez le contenu du template par :
//
//      Subject: Votre code Plume
//      Body:
//        Votre code de connexion Plume : {{ .Token }}
//        Ce code expire dans 60 minutes.
//
//   2. Authentication → Settings :
//      - "Enable email confirmations" → OFF  (sinon double confirmation)
//      - "Mailer OTP Expiry" → 3600 (1h)
//      - "OTP length" → 6
//
// Avec ces réglages, l'utilisateur reçoit un email avec JUSTE le code à 6 chiffres,
// sans lien de confirmation.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class AuthService {
  static final AuthService _i = AuthService._();
  factory AuthService() => _i;
  AuthService._();

  SupabaseClient get _c => Supabase.instance.client;

  // ── Init ──────────────────────────────────────────────────────────────────
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  // ── State ─────────────────────────────────────────────────────────────────
  bool    get isLoggedIn    => _c.auth.currentSession != null;
  String? get currentEmail  => _c.auth.currentUser?.email;
  String? get currentUserId => _c.auth.currentUser?.id;
  String? get accessToken   => _c.auth.currentSession?.accessToken;

  // ── Step 1: Envoyer le code OTP ───────────────────────────────────────────
  /// Retourne null si succès, message d'erreur sinon.
  Future<String?> sendOtp(String email) async {
    try {
      await _c.auth.signInWithOtp(
        email: email.trim().toLowerCase(),
        shouldCreateUser: true,  // crée le compte si c'est la 1ère fois
      );
      return null;
    } on AuthException catch (e) {
      return _friendlyError(e.message);
    } catch (_) {
      return 'Erreur réseau. Vérifiez votre connexion.';
    }
  }

  // ── Step 2: Vérifier le code OTP ──────────────────────────────────────────
  /// Retourne null si succès, message d'erreur sinon.
  Future<String?> verifyOtp(String email, String otp) async {
    try {
      final res = await _c.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: otp.trim(),
        type:  OtpType.email,
      );
      if (res.session == null) return 'Code invalide ou expiré.';

      // Persist pour future session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.authEmailKey,  email.trim().toLowerCase());
      await prefs.setString(AppConstants.authUserIdKey, res.user!.id);
      return null;
    } on AuthException catch (e) {
      return _friendlyError(e.message);
    } catch (_) {
      return 'Code invalide. Vérifiez et réessayez.';
    }
  }

  // ── Restore session (au démarrage de l'app) ───────────────────────────────
  Future<bool> restoreSession() async {
    try {
      if (_c.auth.currentSession != null) return true;
      final res = await _c.auth.refreshSession();
      return res.session != null;
    } catch (_) { return false; }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try { await _c.auth.signOut(); } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.authEmailKey);
    await prefs.remove(AppConstants.authUserIdKey);
    await prefs.remove(AppConstants.driveFileIdKey);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _friendlyError(String msg) {
    if (msg.contains('rate limit'))  return 'Trop de tentatives. Attendez quelques minutes.';
    if (msg.contains('invalid'))     return 'Code invalide ou expiré.';
    if (msg.contains('not confirm')) return 'Email non reconnu. Vérifiez l\'adresse.';
    return msg;
  }
}
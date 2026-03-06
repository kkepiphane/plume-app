// lib/core/services/auth_service.dart
//
// OTP email auth via Supabase — lightweight, no Google SDK needed.
//
// SETUP (once in Supabase dashboard):
//   1. supabase.com → New project (free)
//   2. Authentication → Providers → Email → enable "OTP / Magic Link"
//   3. Fill in lib/core/config/supabase_config.dart with your URL + anon key

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

  bool   get isLoggedIn    => _c.auth.currentSession != null;
  String? get currentEmail => _c.auth.currentUser?.email;
  String? get currentUserId=> _c.auth.currentUser?.id;
  String? get accessToken  => _c.auth.currentSession?.accessToken;

  // ── OTP Step 1: send code ─────────────────────────────────────────────────

  /// Returns null on success, or an error message.
  Future<String?> sendOtp(String email) async {
    try {
      await _c.auth.signInWithOtp(
        email: email.trim().toLowerCase(),
        shouldCreateUser: true,
      );
      return null;
    } on AuthException catch (e) { return e.message; }
    catch (_) { return 'Erreur réseau. Vérifiez votre connexion.'; }
  }

  // ── OTP Step 2: verify code ───────────────────────────────────────────────

  /// Returns null on success, or an error message.
  Future<String?> verifyOtp(String email, String otp) async {
    try {
      final res = await _c.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: otp.trim(),
        type: OtpType.email,
      );
      if (res.session == null) return 'Code invalide ou expiré.';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.authEmailKey,  email.trim().toLowerCase());
      await prefs.setString(AppConstants.authUserIdKey, res.user!.id);
      return null;
    } on AuthException catch (e) { return e.message; }
    catch (_) { return 'Code invalide. Réessayez.'; }
  }

  // ── Session restore (app start) ───────────────────────────────────────────

  Future<bool> restoreSession() async {
    try {
      final session = _c.auth.currentSession;
      if (session != null) return true;
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
}
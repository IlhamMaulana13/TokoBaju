import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String baseUrl = 'http://192.168.1.4:8080';

  // ─────────────────────────────────────────────────────────────────────────
  // REGISTER — me-return role dari backend setelah sinkronisasi
  // ─────────────────────────────────────────────────────────────────────────
  Future<String?> register(String email, String password, String name) async {
    final UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (cred.user != null) {
      await cred.user!.updateDisplayName(name);
      await cred.user!.reload();
    }

    debugPrint('✅ Registrasi Firebase berhasil. UID: ${cred.user?.uid}');
    return _syncAndGetRole(cred, name: name);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LOGIN — me-return role ('admin' | 'customer') atau null jika gagal
  // ─────────────────────────────────────────────────────────────────────────
  Future<String?> login(String email, String password) async {
    final UserCredential cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    debugPrint('✅ Login Firebase berhasil. UID: ${cred.user?.uid}');
    return _syncAndGetRole(cred);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRIVATE: hit /api/auth/sync, parse JSON, return role string
  // ─────────────────────────────────────────────────────────────────────────
  Future<String?> _syncAndGetRole(UserCredential cred, {String? name}) async {
    final user = cred.user;
    if (user == null) {
      debugPrint('❌ UserCredential.user == null setelah Firebase auth');
      return null;
    }

    // Ambil Firebase ID Token
    final String? token = await user.getIdToken();
    if (token == null) {
      debugPrint('❌ Gagal mengambil Firebase ID Token');
      return null;
    }

    final String finalName =
        name ?? user.displayName ?? user.email?.split('@')[0] ?? 'User';
    final String finalEmail = user.email ?? '';

    // Ambil FCM Token
    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint('🔑 FCM Token: $fcmToken');
    } catch (e) {
      debugPrint('⚠️ Gagal mengambil FCM Token: $e');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': finalName,
          'email': finalEmail,
          'fcm_token': fcmToken,
        }),
      );

      debugPrint('📡 /api/auth/sync → ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Parse role dari response JSON: { "user": { "role": "admin" | "customer" } }
        final String role = jsonDecode(response.body)['user']['role'];
        debugPrint('✅ Role diterima dari backend: $role');
        return role;
      } else {
        debugPrint(
            '❌ Sync backend gagal: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error saat hit /api/auth/sync: $e');
      return null;
    }
  }
}

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Ubah [IP_ADDRESS] dengan IP Address host Anda jika testing di device fisik,
  // atau gunakan 10.0.2.2 jika menggunakan emulator Android bawaan.
  static const String baseUrl = 'http://192.168.1.5:8080';

  // Helper untuk melakukan sinkronisasi data user dari Firebase ke backend Golang.
  // Me-return nilai `role` dari response JSON backend ('customer' atau 'admin').
  Future<String?> _syncUserWithBackend(UserCredential userCredential, {String? name}) async {
    final user = userCredential.user;
    if (user == null) return null;

    try {
      // Ambil Firebase ID Token
      String? token = await user.getIdToken();
      if (token == null) {
        debugPrint('❌ Gagal mengambil Firebase ID Token');
        return null;
      }

      final String finalName = name ?? user.displayName ?? user.email?.split('@')[0] ?? 'User';
      final String finalEmail = user.email ?? '';

      // POST ke endpoint /api/auth/sync
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': finalName,
          'email': finalEmail,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Sinkronisasi Data User ke Backend Berhasil! Response: ${response.body}');
        // Parse role dari response JSON Golang: { "user": { "role": "admin" } }
        final Map<String, dynamic> body = jsonDecode(response.body);
        final String? role = body['user']?['role'] as String?;
        debugPrint('✅ Role user: $role');
        return role;
      } else {
        debugPrint('❌ Sinkronisasi Data User ke Backend Gagal: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Terjadi Error saat melakukan sinkronisasi ke backend: $e');
      return null;
    }
  }

  Future<UserCredential?> registerWithEmailPassword(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Perbarui nama profil pengguna di Firebase Auth
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
        await userCredential.user!.reload();
      }

      debugPrint('✅ Registrasi Berhasil di Firebase! UID: ${userCredential.user?.uid}');

      // Sinkronisasi data user ke backend Golang setelah berhasil Register
      await _syncUserWithBackend(userCredential, name: name);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Error Registrasi: $e');
      rethrow;
    }
  }

  /// Login dengan email & password.
  /// Me-return Map berisi:
  /// - `credential`: UserCredential
  /// - `role`: String? ('admin' atau 'customer')
  Future<Map<String, dynamic>?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ Login Berhasil di Firebase! UID: ${userCredential.user?.uid}');

      // Sinkronisasi data user ke backend Golang setelah berhasil Login, ambil role
      final String? role = await _syncUserWithBackend(userCredential);

      return {
        'credential': userCredential,
        'role': role ?? 'customer', // default ke customer jika sync gagal
      };
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Error Login: $e');
      rethrow;
    }
  }
}

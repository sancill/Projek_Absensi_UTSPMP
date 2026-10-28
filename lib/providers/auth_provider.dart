import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Dipanggil oleh authStateChanges listener di main.dart (P04)
  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  /// Pendaftaran akun baru via Firebase Auth
  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _user = cred.user;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _pesanError(e.code);
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Masuk dengan email & password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _user = cred.user;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _pesanError(e.code);
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Keluar dari sesi login
  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  /// Pemetaan pesan error bahasa Indonesia menggunakan algoritma if-else (Sesuai Materi P04)
  String _pesanError(String code) {
    if (code == 'user-not-found' ||
        code == 'invalid-credential' ||
        code == 'wrong-password') {
      return 'Email atau password yang Anda masukkan salah.';
    } else if (code == 'email-already-in-use') {
      return 'Email ini sudah terdaftar. Silakan login.';
    } else if (code == 'weak-password') {
      return 'Password terlalu lemah. Minimal 6 karakter.';
    } else if (code == 'invalid-email') {
      return 'Format penulisan email tidak valid.';
    } else if (code == 'configuration-not-found') {
      return 'Firebase Auth belum aktif: Aktifkan Email/Password di Firebase Console.';
    } else if (code == 'network-request-failed') {
      return 'Koneksi internet bermasalah. Periksa jaringan Anda.';
    } else if (code == 'too-many-requests') {
      return 'Terlalu banyak percobaan gagal. Silakan tunggu beberapa saat.';
    } else {
      return 'Gagal melakukan autentikasi ($code).';
    }
  }
}

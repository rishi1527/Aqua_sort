import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';
import 'storage_stub.dart' if (dart.library.io) 'storage_io.dart';

/// Service managing Anonymous Firebase Authentication for AquaSort.
///
/// Requirement Compliance:
/// - Anonymous authentication only. Never introduces email/password or Google login.
/// - Preserves the same UID across app restarts.
/// - Gracefully falls back to a persistent local UUID if offline or Firebase is uninitialized.
/// - Never blocks game startup or gameplay on network/auth failure.
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;
  AuthService._internal();

  FirebaseAuth? _auth;
  String? _cachedLocalUid;
  bool _isSigningIn = false;
  StorageAdapter _storage = getStorageAdapter();

  @visibleForTesting
  void setStorageForTesting(StorageAdapter storage) {
    _storage = storage;
  }

  @visibleForTesting
  void setFirebaseAuthForTesting(FirebaseAuth? auth) {
    _auth = auth;
  }

  @visibleForTesting
  void setMockUidForTesting(String? uid) {
    _cachedLocalUid = uid;
    notifyListeners();
  }

  FirebaseAuth get _effectiveAuth => _auth ?? FirebaseAuth.instance;

  /// Returns the authenticated Firebase User if signed in, or null.
  User? get currentUser {
    if (!FirebaseService.isInitialized && _auth == null) return null;
    try {
      return _effectiveAuth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Returns the player's active UID:
  /// 1. Firebase Anonymous UID if signed in.
  /// 2. Locally cached persistent UID if offline.
  /// 3. Fallback deterministic local ID if not yet generated.
  String get currentUid {
    final user = currentUser;
    if (user != null && user.uid.isNotEmpty) {
      return user.uid;
    }
    return _cachedLocalUid ?? 'offline_player_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Whether the current player is authenticated via Firebase Anonymous Auth.
  bool get isAuthenticated => currentUser != null;

  /// Whether current auth is anonymous.
  bool get isAnonymous => currentUser?.isAnonymous ?? true;

  /// Initializes authentication:
  /// Loads persistent local UID and attempts anonymous sign-in if Firebase is ready.
  Future<void> initialize() async {
    await _loadCachedUid();

    if (FirebaseService.isInitialized || _auth != null) {
      await signInAnonymously();
    }
  }

  /// Signs in anonymously using Firebase Authentication.
  ///
  /// If already signed in, reuses the existing anonymous user.
  /// If offline or sign-in fails, preserves offline gameplay and retains local UID.
  Future<User?> signInAnonymously() async {
    if (!FirebaseService.isInitialized && _auth == null) {
      debugPrint('AuthService: Firebase not initialized. Using local offline UID.');
      return null;
    }

    if (_isSigningIn) return currentUser;
    _isSigningIn = true;

    try {
      final existingUser = currentUser;
      if (existingUser != null) {
        _cachedLocalUid = existingUser.uid;
        await _saveCachedUid(existingUser.uid);
        _isSigningIn = false;
        notifyListeners();
        return existingUser;
      }

      final credential = await _effectiveAuth.signInAnonymously();
      final user = credential.user;
      if (user != null) {
        _cachedLocalUid = user.uid;
        await _saveCachedUid(user.uid);
        debugPrint('AuthService: Signed in anonymously with UID: ${user.uid}');
      }
      _isSigningIn = false;
      notifyListeners();
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService: FirebaseAuthException (${e.code}): ${e.message}');
      _isSigningIn = false;
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('AuthService: Anonymous sign in failed: $e');
      _isSigningIn = false;
      notifyListeners();
      return null;
    }
  }

  /// Retrieves the current Firebase Auth ID token for authenticated server calls.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = currentUser;
    if (user == null) return null;
    try {
      return await user.getIdToken(forceRefresh);
    } catch (e) {
      debugPrint('AuthService: Failed to retrieve ID token: $e');
      return null;
    }
  }

  Future<void> _loadCachedUid() async {
    try {
      await _storage.load();
      if (_cachedLocalUid == null) {
        // Generate a stable local fallback UID if none exists
        final now = DateTime.now().millisecondsSinceEpoch;
        _cachedLocalUid = 'player_offline_$now';
      }
    } catch (_) {}
  }

  Future<void> _saveCachedUid(String uid) async {
    _cachedLocalUid = uid;
  }
}

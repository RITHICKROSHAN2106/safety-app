import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fba;

import '../../models/app_user.dart';

class AuthState {
  final AppUser? user;
  final bool loading;
  final bool initialized;
  final String? error;

  const AuthState({
    this.user,
    this.loading = false,
    this.initialized = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AppUser? user,
    bool clearUser = false,
    bool? loading,
    bool? initialized,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      loading: loading ?? this.loading,
      initialized: initialized ?? this.initialized,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthCubit extends Cubit<AuthState> {
  final fba.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  StreamSubscription<fba.User?>? _authSub;

  AuthCubit({fba.FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? fba.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(const AuthState(loading: true)) {
    unawaited(_handleAuthUser(_auth.currentUser));

    _authSub = _auth.authStateChanges().listen(_handleAuthUser,
        onError: (Object error, StackTrace stackTrace) {
      emit(AuthState(
        loading: false,
        initialized: true,
        error: 'Authentication listener failed: $error',
      ));
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on fba.FirebaseAuthException catch (e) {
      emit(state.copyWith(
        loading: false,
        error: _mapAuthError(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: 'Sign in failed: $e',
      ));
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (displayName != null && displayName.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
        await credential.user?.reload();
      }

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'displayName': displayName?.trim(),
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on fba.FirebaseAuthException catch (e) {
      emit(state.copyWith(
        loading: false,
        error: _mapAuthError(e),
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: 'Registration failed: $e',
      ));
    }
  }

  Future<void> signOut() async {
    emit(state.copyWith(loading: true, clearError: true));
    await _auth.signOut();
  }

  Future<void> refreshProfile() async {
    await _handleAuthUser(_auth.currentUser);
  }

  Future<void> _handleAuthUser(fba.User? firebaseUser) async {
    if (firebaseUser == null) {
      emit(const AuthState(initialized: true));
      return;
    }

    final basicUser = AppUser(
      uid: firebaseUser.uid,
      displayName: firebaseUser.displayName,
      email: firebaseUser.email,
      phoneNumber: firebaseUser.phoneNumber,
    );

    // Emit immediately so splash can navigate without waiting on Firestore.
    emit(AuthState(
      user: basicUser,
      loading: false,
      initialized: true,
    ));

    try {
      final profileDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get()
          .timeout(const Duration(seconds: 2));

      if (profileDoc.exists) {
        final data = profileDoc.data() ?? {};
        final enrichedUser = basicUser.copyWith(
          displayName: (data['displayName'] ?? basicUser.displayName) as String?,
          phoneNumber: (data['phoneNumber'] ?? basicUser.phoneNumber) as String?,
          emergencyContactIds: data['emergencyContactIds'] != null
              ? List<String>.from(data['emergencyContactIds'] as List)
              : basicUser.emergencyContactIds,
        );

        emit(state.copyWith(user: enrichedUser, initialized: true, loading: false));
      } else {
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(basicUser.toJson(), SetOptions(merge: true));
      }
    } catch (e) {
      emit(state.copyWith(
        user: basicUser,
        loading: false,
        initialized: true,
        error: 'Profile sync delayed: $e',
      ));
    }
  }

  String _mapAuthError(fba.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address appears to be invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Please choose a stronger password (min 6 characters).';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Authentication error (${e.code}).';
    }
  }

  @override
  Future<void> close() async {
    await _authSub?.cancel();
    return super.close();
  }
}

/// Auth Cubit
/// Manages authentication state and user session
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

// Auth States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;

  AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// Auth Cubit
class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthCubit() : super(AuthInitial()) {
    _checkAuthStatus();
  }

  // Check current auth status
  void _checkAuthStatus() {
    _auth.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser != null) {
        _loadUserData(firebaseUser.uid);
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  // Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final user = UserModel.fromMap(doc.data()!);
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Failed to load user data'));
    }
  }

  // Register new user
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      emit(AuthLoading());

      // Create Firebase user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user document
        final user = UserModel(
          uid: credential.user!.uid,
          email: email,
          name: name,
          phone: phone,
          createdAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.uid).set(user.toMap());

        emit(AuthAuthenticated(user));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_getAuthErrorMessage(e.code)));
    } catch (e) {
      emit(AuthError('Registration failed: $e'));
    }
  }

  // Login user
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      emit(AuthLoading());

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Auth state listener will handle loading user data
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_getAuthErrorMessage(e.code)));
    } catch (e) {
      emit(AuthError('Login failed: $e'));
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Logout failed'));
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    }
  }

  // Update user profile
  Future<void> updateProfile(UserModel updatedUser) async {
    try {
      await _firestore
          .collection('users')
          .doc(updatedUser.uid)
          .update(updatedUser.toMap());

      emit(AuthAuthenticated(updatedUser));
    } catch (e) {
      emit(AuthError('Failed to update profile'));
    }
  }

  // Get current user
  UserModel? getCurrentUser() {
    if (state is AuthAuthenticated) {
      return (state as AuthAuthenticated).user;
    }
    return null;
  }

  // Convert Firebase error codes to user-friendly messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      default:
        return 'Authentication error occurred';
    }
  }
}

/// Guardian Cubit
/// Manages guardian contacts and operations
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/guardian_model.dart';

// Guardian States
abstract class GuardianState extends Equatable {
  @override
  List<Object?> get props => [];
}

class GuardianInitial extends GuardianState {}

class GuardianLoading extends GuardianState {}

class GuardianLoaded extends GuardianState {
  final List<Guardian> guardians;

  GuardianLoaded(this.guardians);

  @override
  List<Object?> get props => [guardians];
}

class GuardianError extends GuardianState {
  final String message;

  GuardianError(this.message);

  @override
  List<Object?> get props => [message];
}

// Guardian Cubit
class GuardianCubit extends Cubit<GuardianState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GuardianCubit() : super(GuardianInitial());

  // Load guardians for user
  Future<void> loadGuardians(String userId) async {
    try {
      emit(GuardianLoading());

      final snapshot = await _firestore
          .collection('guardians')
          .where('userId', isEqualTo: userId)
          .get();

      final guardians = snapshot.docs
          .map((doc) => Guardian.fromMap(doc.data()))
          .toList();

      // Sort: primary first, then by name
      guardians.sort((a, b) {
        if (a.isPrimary && !b.isPrimary) return -1;
        if (!a.isPrimary && b.isPrimary) return 1;
        return a.name.compareTo(b.name);
      });

      emit(GuardianLoaded(guardians));
    } catch (e) {
      emit(GuardianError('Failed to load guardians'));
    }
  }

  // Add guardian
  Future<void> addGuardian({
    required String userId,
    required String name,
    required String phone,
    String? email,
    String? relationship,
    bool isPrimary = false,
  }) async {
    try {
      // If setting as primary, unset other primaries first
      if (isPrimary) {
        await _unsetOtherPrimaries(userId);
      }

      final guardian = Guardian(
        id: const Uuid().v4(),
        userId: userId,
        name: name,
        phone: phone,
        email: email,
        relationship: relationship,
        isPrimary: isPrimary,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('guardians')
          .doc(guardian.id)
          .set(guardian.toMap());

      // Reload guardians
      await loadGuardians(userId);
    } catch (e) {
      emit(GuardianError('Failed to add guardian'));
    }
  }

  // Update guardian
  Future<void> updateGuardian(String userId, Guardian guardian) async {
    try {
      // If setting as primary, unset other primaries first
      if (guardian.isPrimary) {
        await _unsetOtherPrimaries(userId, excludeId: guardian.id);
      }

      final updatedGuardian = guardian.copyWith(updatedAt: DateTime.now());

      await _firestore
          .collection('guardians')
          .doc(updatedGuardian.id)
          .update(updatedGuardian.toMap());

      // Reload guardians
      await loadGuardians(userId);
    } catch (e) {
      emit(GuardianError('Failed to update guardian'));
    }
  }

  // Delete guardian
  Future<void> deleteGuardian(String userId, String guardianId) async {
    try {
      await _firestore.collection('guardians').doc(guardianId).delete();

      // Reload guardians
      await loadGuardians(userId);
    } catch (e) {
      emit(GuardianError('Failed to delete guardian'));
    }
  }

  // Set guardian as primary
  Future<void> setPrimaryGuardian(String userId, String guardianId) async {
    try {
      // Unset all other primaries
      await _unsetOtherPrimaries(userId, excludeId: guardianId);

      // Set this guardian as primary
      await _firestore.collection('guardians').doc(guardianId).update({
        'isPrimary': true,
        'updatedAt': Timestamp.now(),
      });

      // Reload guardians
      await loadGuardians(userId);
    } catch (e) {
      emit(GuardianError('Failed to set primary guardian'));
    }
  }

  // Unset other primaries
  Future<void> _unsetOtherPrimaries(String userId,
      {String? excludeId}) async {
    final snapshot = await _firestore
        .collection('guardians')
        .where('userId', isEqualTo: userId)
        .where('isPrimary', isEqualTo: true)
        .get();

    for (var doc in snapshot.docs) {
      if (excludeId == null || doc.id != excludeId) {
        await doc.reference.update({'isPrimary': false});
      }
    }
  }

  // Get guardian list
  List<Guardian> getGuardians() {
    if (state is GuardianLoaded) {
      return (state as GuardianLoaded).guardians;
    }
    return [];
  }

  // Get primary guardian
  Guardian? getPrimaryGuardian() {
    if (state is GuardianLoaded) {
      final guardians = (state as GuardianLoaded).guardians;
      try {
        return guardians.firstWhere((g) => g.isPrimary);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Get guardian count
  int getGuardianCount() {
    return getGuardians().length;
  }
}

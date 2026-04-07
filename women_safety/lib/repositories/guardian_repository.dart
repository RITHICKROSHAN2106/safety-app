import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/guardian.dart';
import '../services/emergency_cache_service.dart';

/// Provides read access to guardian data without relying on widget state.
class GuardianRepository {
  GuardianRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Loads all guardians for the given user, ordering primary contacts first.
  Future<List<Guardian>> fetchGuardiansForUser(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final ids =
          (userDoc.data()?['emergencyContactIds'] as List?)
              ?.map((dynamic e) => '$e')
              .toList() ??
          <String>[];

      if (ids.isEmpty) {
        return <Guardian>[];
      }

      final futures = ids.map((id) async {
        final doc = await _firestore.collection('guardians').doc(id).get();
        if (!doc.exists) return null;
        return Guardian.fromJson({
          'id': doc.id,
          ...(doc.data() ?? <String, dynamic>{}),
        });
      });

      final results = await Future.wait(futures);
      final guardians = results.whereType<Guardian>().toList()
        ..sort((a, b) {
          if (a.isPrimary == b.isPrimary) {
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
          return a.isPrimary ? -1 : 1;
        });

      await EmergencyCacheService.cacheGuardians(
        userId: userId,
        guardians: guardians,
      );
      await EmergencyCacheService.cacheEmergencyContacts(
        userId: userId,
        contacts: guardians
            .map(
              (g) => {
                'name': g.name,
                'phone': g.phone,
                'relationship': g.relationship,
                'isPrimary': g.isPrimary,
              },
            )
            .toList(),
      );

      return guardians;
    } catch (_) {
      final cached = await EmergencyCacheService.getCachedGuardians(userId);
      if (cached.isNotEmpty) {
        cached.sort((a, b) {
          if (a.isPrimary == b.isPrimary) {
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
          return a.isPrimary ? -1 : 1;
        });
      }
      return cached;
    }
  }
}

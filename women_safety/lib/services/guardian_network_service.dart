import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'whatsapp_service.dart';
import 'package:flutter/foundation.dart';

/// 🤝 Guardian Network Service - Connect with nearby safety volunteers
class GuardianNetworkService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Register as a volunteer guardian
  static Future<bool> registerAsVolunteer({
    required String userId,
    required String name,
    required String phone,
    double radiusKm = 5.0,
  }) async {
    try {
      final position = await Geolocator.getCurrentPosition();
      
      await _firestore.collection('volunteer_guardians').doc(userId).set({
        'userId': userId,
        'name': name,
        'phone': phone,
        'location': GeoPoint(position.latitude, position.longitude),
        'radiusKm': radiusKm,
        'isActive': true,
        'registeredAt': FieldValue.serverTimestamp(),
        'helpCount': 0,
        'rating': 5.0,
        'verified': false,
      });

      debugPrint('✅ Registered as volunteer guardian');
      return true;
    } catch (e) {
      debugPrint('❌ Register volunteer error: $e');
      return false;
    }
  }

  /// Find nearby volunteers when emergency occurs
  static Future<List<Map<String, dynamic>>> findNearbyVolunteers({
    required Position userPosition,
    double radiusKm = 2.0,
  }) async {
    try {
      // In production, use Firestore geoqueries
      final volunteers = await _firestore
          .collection('volunteer_guardians')
          .where('isActive', isEqualTo: true)
          .get();

      final nearbyVolunteers = <Map<String, dynamic>>[];
      
      for (final doc in volunteers.docs) {
        final data = doc.data();
        final location = data['location'] as GeoPoint;
        
        final distance = Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          location.latitude,
          location.longitude,
        ) / 1000; // Convert to km
        
        if (distance <= radiusKm) {
          nearbyVolunteers.add({
            ...data,
            'distance': distance,
            'volunteerId': doc.id,
          });
        }
      }

      // Sort by distance
      nearbyVolunteers.sort((a, b) => 
        (a['distance'] as double).compareTo(b['distance'] as double)
      );

      debugPrint('✅ Found ${nearbyVolunteers.length} nearby volunteers');
      return nearbyVolunteers;
    } catch (e) {
      debugPrint('❌ Find volunteers error: $e');
      return [];
    }
  }

  /// Alert nearby volunteers about emergency
  static Future<void> alertNearbyVolunteers({
    required String userId,
    required Position position,
  }) async {
    try {
      final volunteers = await findNearbyVolunteers(
        userPosition: position,
        radiusKm: 2.0,
      );

      for (final volunteer in volunteers.take(5)) {
        // Alert via WhatsApp with simple message (avoid null SOSAlert)
        final message = '''🚨 Nearby Emergency Alert

A user needs help near your location.
Distance: ${(volunteer['distance'] as double).toStringAsFixed(2)} km
Location: https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}

Please stay alert and offer help if safe to do so.
- Women Safety App''';
        await WhatsAppService.sendSimpleMessage(
          phoneNumber: volunteer['phone'],
          message: message,
          contactName: volunteer['name'],
        );

        // Store alert in database
        await _firestore.collection('volunteer_alerts').add({
          'userId': userId,
          'volunteerId': volunteer['volunteerId'],
          'location': GeoPoint(position.latitude, position.longitude),
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
        });
      }

      debugPrint('✅ ${volunteers.length} volunteers alerted');
    } catch (e) {
      debugPrint('❌ Alert volunteers error: $e');
    }
  }

  /// Accept help request as volunteer
  static Future<bool> acceptHelpRequest(String alertId) async {
    try {
      await _firestore.collection('volunteer_alerts').doc(alertId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Help request accepted');
      return true;
    } catch (e) {
      debugPrint('❌ Accept help error: $e');
      return false;
    }
  }

  /// Rate volunteer after help
  static Future<void> rateVolunteer(String volunteerId, double rating) async {
    try {
      final doc = await _firestore.collection('volunteer_guardians').doc(volunteerId).get();
      final currentRating = doc.data()?['rating'] ?? 5.0;
      final helpCount = doc.data()?['helpCount'] ?? 0;
      
      final newRating = ((currentRating * helpCount) + rating) / (helpCount + 1);
      
      await _firestore.collection('volunteer_guardians').doc(volunteerId).update({
        'rating': newRating,
        'helpCount': FieldValue.increment(1),
      });

      debugPrint('✅ Volunteer rated: $rating stars');
    } catch (e) {
      debugPrint('❌ Rate volunteer error: $e');
    }
  }

  /// Toggle volunteer active status
  static Future<void> setActiveStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('volunteer_guardians').doc(userId).update({
        'isActive': isActive,
        'lastStatusChange': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Volunteer active status set to $isActive');
    } catch (e) {
      debugPrint('❌ Set active status error: $e');
    }
  }
}

/// SOS Service
/// Core service handling SOS alerts, countdown, alarm, and evidence capture
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/sos_log_model.dart';
import '../models/guardian_model.dart';
import '../models/location_model.dart';
import 'location_share_service.dart';
import 'whatsapp_service.dart';
import 'sms_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationShareService _locationService = LocationShareService();
  final WhatsAppService _whatsappService = WhatsAppService();
  final SmsService _smsService = SmsService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  Timer? _countdownTimer;
  int _countdown = 5;
  StreamController<int>? _countdownController;

  // Countdown stream
  Stream<int> get countdownStream {
    _countdownController ??= StreamController<int>.broadcast();
    return _countdownController!.stream;
  }

  // Start SOS countdown
  void startCountdown({
    required VoidCallback onComplete,
    required VoidCallback onCancel,
  }) {
    _countdown = 5;
    _countdownController?.add(_countdown);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdown--;
      _countdownController?.add(_countdown);

      if (_countdown <= 0) {
        timer.cancel();
        onComplete();
      }
    });
  }

  // Cancel countdown
  void cancelCountdown() {
    _countdownTimer?.cancel();
    _countdown = 5;
    _countdownController?.add(_countdown);
  }

  // Play alarm sound
  Future<void> playAlarm() async {
    try {
      // Using a system sound as placeholder
      // In production, add custom alarm sound to assets/sounds/alarm.mp3
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
    } catch (e) {
      // Fallback: continue without sound
      print('Failed to play alarm: $e');
    }
  }

  // Stop alarm
  Future<void> stopAlarm() async {
    await _audioPlayer.stop();
  }

  // Trigger full SOS alert
  Future<SosLog> triggerSosAlert({
    required String userId,
    required String userName,
    required List<Guardian> guardians,
  }) async {
    try {
      // 1. Get current location
      LocationModel? location = await _locationService.getCurrentLocation();
      if (location == null) {
        throw Exception('Failed to get location');
      }

      // 2. Play alarm
      await playAlarm();

      // 3. Create SOS log
      final sosLog = SosLog(
        id: const Uuid().v4(),
        userId: userId,
        latitude: location.latitude,
        longitude: location.longitude,
        address: location.address,
        timestamp: DateTime.now(),
        status: 'triggered',
        alertsSent: [],
      );

      // 4. Send alerts to all guardians
      List<String> alertsSent = [];

      for (Guardian guardian in guardians) {
        // Send WhatsApp alert
        try {
          await _whatsappService.sendSosAlert(
            phoneNumber: guardian.phone,
            userName: userName,
            latitude: location.latitude,
            longitude: location.longitude,
            address: location.address,
          );
          alertsSent.add('whatsapp');
        } catch (e) {
          print('WhatsApp failed for ${guardian.phone}: $e');
        }

        // Send SMS alert
        try {
          await _smsService.sendSosAlert(
            phoneNumber: guardian.phone,
            userName: userName,
            latitude: location.latitude,
            longitude: location.longitude,
            address: location.address,
          );
          alertsSent.add('sms');
        } catch (e) {
          print('SMS failed for ${guardian.phone}: $e');
        }

        // Auto-call primary guardian
        if (guardian.isPrimary) {
          try {
            await makeEmergencyCall(guardian.phone);
            alertsSent.add('call');
          } catch (e) {
            print('Call failed for ${guardian.phone}: $e');
          }
        }
      }

      // 5. Save SOS log to Firestore
      final updatedLog = sosLog.copyWith(alertsSent: alertsSent);
      await _firestore
          .collection('sos_logs')
          .doc(updatedLog.id)
          .set(updatedLog.toMap());

      return updatedLog;
    } catch (e) {
      throw Exception('Failed to trigger SOS: $e');
    }
  }

  // Make emergency call
  Future<void> makeEmergencyCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      throw Exception('Cannot make phone call');
    }
  }

  // Capture audio evidence (placeholder)
  Future<String?> captureAudioEvidence() async {
    // TODO: Implement audio recording
    // Use flutter_sound to record audio
    // Upload to Firebase Storage
    // Return download URL
    return null;
  }

  // Capture image evidence (placeholder)
  Future<String?> captureImageEvidence() async {
    // TODO: Implement image capture
    // Use camera or image_picker
    // Upload to Firebase Storage
    // Return download URL
    return null;
  }

  // Get user's SOS history
  Future<List<SosLog>> getSosHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('sos_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) => SosLog.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to get SOS history: $e');
    }
  }

  // Update SOS log status
  Future<void> updateSosStatus(String sosId, String status) async {
    await _firestore.collection('sos_logs').doc(sosId).update({
      'status': status,
    });
  }

  // Dispose resources
  void dispose() {
    _countdownTimer?.cancel();
    _countdownController?.close();
    _audioPlayer.dispose();
  }
}

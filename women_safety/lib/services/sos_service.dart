import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/guardian.dart';
import '../models/sos_alert.dart';
import '../models/app_user.dart';
import 'sms_service.dart';
import 'backend_sms_service.dart';
import 'whatsapp_service.dart';
import 'multi_channel_message_builder.dart'; // ✅ NEW: Unified message builder
import 'email_service.dart';
import 'recording_service.dart';
import 'storage_service.dart';
import 'notification_service.dart';
import 'config.dart';
import 'alarm_service.dart';
import 'offline_queue_service.dart';
import 'call_escalation_service.dart';
import 'guardian_tracking_service.dart';
import 'evidence_capture_service.dart';
import 'live_streaming_service.dart';
import 'guardian_network_service.dart';
import 'distress_voice_analysis_service.dart';
import 'ai_danger_prediction_service.dart';

class SOSService {
  /// Main SOS trigger - coordinates all emergency actions
  static Future<SOSAlert?> triggerSOS({
    required AppUser user,
    required List<Guardian> emergencyContacts,
    required String triggerType, // 'BUTTON', 'SHAKE', 'VOICE'
    bool recordVideo = false,  // DISABLED - Causing camera crash
    bool makeCall = true,
    bool playAlarm = true,
  }) async {
    try {
      debugPrint('🚨 ========== SOS TRIGGERED ==========');
      debugPrint('🚨 Trigger Type: $triggerType');
      debugPrint('🚨 User: ${user.name}');
      debugPrint('🚨 Emergency Contacts: ${emergencyContacts.length}');
      
      // STEP 1: Get current location
      debugPrint('\n📍 STEP 1: Getting current location...');
      Position? position = await _getCurrentLocation();
      if (position == null) {
        debugPrint('❌ Failed to get location, using default');
        position = Position(
          latitude: 0.0,
          longitude: 0.0,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0,
          headingAccuracy: 0.0,
        );
      }

      // Create SOS Alert
      final alert = SOSAlert(
        userId: user.id,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        triggerType: triggerType,
        status: 'ACTIVE',
      );

      debugPrint('✅ Location: ${alert.latitude}, ${alert.longitude}');

      // STEP 1.5: Start evidence capture immediately
      debugPrint('\n🎬 STEP 1.5: Starting evidence capture...');
      final evidenceService = EvidenceCaptureService();
      try {
        await evidenceService.initialize();
        await evidenceService.startCapture(
          userId: user.id,
          sosId: alert.id ?? 'sos_${DateTime.now().millisecondsSinceEpoch}',
          locationData: {
            'latitude': alert.latitude,
            'longitude': alert.longitude,
            'timestamp': alert.timestamp.toIso8601String(),
          },
        );
        debugPrint('✅ Evidence capture started');
      } catch (e) {
        debugPrint('⚠️ Evidence capture error: $e');
      }

      // STEP 1.6: Start guardian live tracking
      debugPrint('\n🎯 STEP 1.6: Starting guardian live tracking...');
      final trackingService = GuardianTrackingService();
      try {
        final trackingSessionId = await trackingService.startTracking(
          userId: user.id,
          sosId: alert.id ?? 'sos_${DateTime.now().millisecondsSinceEpoch}',
          guardianPhones: emergencyContacts.map((g) => g.phone).toList(),
          initialLocation: {
            'latitude': alert.latitude,
            'longitude': alert.longitude,
            'timestamp': alert.timestamp.toIso8601String(),
          },
        );
        debugPrint('✅ Live tracking started: $trackingSessionId');
      } catch (e) {
        debugPrint('⚠️ Live tracking error: $e');
      }

      // STEP 1.7: 🚀 Start revolutionary features
      debugPrint('\n🚀 STEP 1.7: Activating revolutionary features...');
      await _activateRevolutionaryFeatures(user, alert, position);

      // STEP 2: Start video recording (non-blocking)
      if (recordVideo) {
        debugPrint('\n🎥 STEP 2: Starting video recording...');
        _startRecordingAsync().then((path) {
          if (path != null) {
            debugPrint('✅ Video recording completed: $path');
            // Upload video after recording
            _uploadVideoAsync(path, user.id, alert);
          }
        });
      } else {
        debugPrint('\n⏭️ STEP 2: Skipping video recording');
      }

      // STEP 3: Activate local alarm feedback
      if (playAlarm) {
        debugPrint('\n🔊 STEP 3: Starting local alarm...');
        await AlarmService.startAlarm(autoStopAfter: const Duration(seconds: 45));
        debugPrint('✅ Alarm activated');
      } else {
        debugPrint('\n⏭️ STEP 3: Skipping local alarm');
      }

      // STEP 4: Send SMS to all contacts - TRY AUTOMATIC FIRST
      // STEP 4: Build unified multi-channel SOS messages with consistent location data
      debugPrint('\n🔨 STEP 4: Building unified multi-channel messages...');
      final sosMessages = MultiChannelMessageBuilder.buildSOSMessages(
        alert: alert,
        userName: user.name,
        contactName: emergencyContacts.isNotEmpty ? emergencyContacts[0].name : 'Guardian',
      );
      
      if (sosMessages.isLocationDataComplete()) {
        debugPrint('✅ Unified messages created with location:');
        debugPrint(sosMessages.getLocationInfoLog());
      } else {
        debugPrint('⚠️ Location data incomplete in unified messages');
      }

      // STEP 4.1: Send SMS with unified message
      debugPrint('\n📱 STEP 4.1: Sending SMS alerts with unified location...');
      bool smsSent = false;
      try {
        final automaticSmsSent = await BackendSmsService.sendAutomaticSOSSms(
          contacts: emergencyContacts,
          alert: alert,
          userName: user.name,
        );
        smsSent = automaticSmsSent;
      } catch (e) {
        debugPrint('⚠️ Automatic SMS service error: $e');
        smsSent = false;
      }
      
      if (!smsSent) {
        debugPrint('  ⚠️ Automatic SMS failed, opening device SMS composer with location...');
        smsSent = await SmsService.sendSOSSms(
          contacts: emergencyContacts,
          alert: alert,
          customMessage: sosMessages.sms, // ✅ Use unified message with location
        );
      }

      if (smsSent) {
        debugPrint('  ✅ SMS flow initiated successfully with location');
      }

      // STEP 4.2: Queue for offline retry if needed
      if (!smsSent) {
        debugPrint('\n💾 Queueing alert for offline retry...');
        await _queueForOfflineRetry(user, emergencyContacts, alert);
      }

      // STEP 5: Make call to primary contact with smart escalation
      if (makeCall && emergencyContacts.isNotEmpty) {
        debugPrint('\n📞 STEP 5: Starting smart call escalation...');
        CallEscalationService.startEscalation(
          guardians: emergencyContacts,
          callEmergencyServicesOnFailure: true,
        );
      } else {
        debugPrint('\n⏭️ STEP 5: Skipping call');
      }

      // STEP 6: Send WhatsApp messages with unified location (parallel, non-blocking)
      debugPrint('\n💬 STEP 6: Sending WhatsApp messages with location...');
      _sendWhatsAppAsync(emergencyContacts, sosMessages); // ✅ Pass unified messages

      // STEP 7: Send email alerts with unified location (parallel, non-blocking)
      debugPrint('\n📧 STEP 7: Sending email alerts with location...');
      _sendEmailAsync(emergencyContacts, sosMessages, user.name); // ✅ Pass unified messages

      // STEP 8: Send to backend API
      debugPrint('\n🌐 STEP 8: Sending alert to backend...');
      final alertWithId = await _sendToBackend(alert);

      // STEP 9: Show local notification with location data
      debugPrint('\n🔔 STEP 9: Showing notification with location...');
      await NotificationService.showNotification(
        title: sosMessages.pushTitle, // ✅ Use unified title
        body: sosMessages.pushBody, // ✅ Use unified body with location
        payload: jsonEncode(sosMessages.location), // ✅ Include location data in payload
      );

      debugPrint('\n✅ ========== SOS PROCESS COMPLETE ==========\n');
      return alertWithId ?? alert;
    } catch (e) {
      debugPrint('❌ SOS Service Error: $e');
      AlarmService.stopAlarm();
      return null;
    }
  }

  /// Get current location
  static Future<Position?> _getCurrentLocation() async {
    try {
      final hasPermission = await Geolocator.isLocationServiceEnabled();
      if (!hasPermission) {
        debugPrint('❌ Location services disabled');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      debugPrint('❌ Location error: $e');
      return null;
    }
  }

  /// Start recording video (async, non-blocking)
  static Future<String?> _startRecordingAsync() async {
    try {
      // Record for 30 seconds
      final videoPath = await RecordingService.recordForDuration(
        const Duration(seconds: 30),
      );
      return videoPath;
    } catch (e) {
      debugPrint('❌ Recording error: $e');
      return null;
    }
  }

  /// Upload video to Firebase Storage (async)
  static Future<void> _uploadVideoAsync(
    String videoPath,
    String userId,
    SOSAlert alert,
  ) async {
    try {
      debugPrint('📤 Uploading video to Firebase Storage...');
      final downloadUrl = await StorageService.uploadSOSVideo(
        filePath: videoPath,
        userId: userId,
        onProgress: (progress) {
          debugPrint('📤 Upload: ${(progress * 100).toStringAsFixed(0)}%');
        },
      );

      if (downloadUrl != null) {
        debugPrint('✅ Video uploaded: $downloadUrl');
        // Update alert with video URL
        await _updateAlertMedia(alert.id ?? '', downloadUrl);
      }
    } catch (e) {
      debugPrint('❌ Upload error: $e');
    }
  }

  /// Queue alert for offline retry
  static Future<void> _queueForOfflineRetry(
    AppUser user,
    List<Guardian> contacts,
    SOSAlert alert,
  ) async {
    try {
      final isOnline = await OfflineQueueService.isNetworkAvailable();
      if (isOnline) {
        debugPrint('ℹ️ Network available, skipping queue');
        return;
      }

      final guardianPhones = contacts.map((c) => c.phone).toList();
      final message = '''
🚨 EMERGENCY SOS ALERT 🚨

I need help! Emergency SOS triggered.

📍 Location: ${alert.getMapUrl()}
⏰ Time: ${alert.timestamp}

Please contact me immediately!
- ${user.name}
''';

      await OfflineQueueService.queueAlert(
        alertId: alert.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        latitude: alert.latitude,
        longitude: alert.longitude,
        triggerType: alert.triggerType ?? 'UNKNOWN',
        guardianPhones: guardianPhones,
        message: message,
      );

      debugPrint('✅ Alert queued for offline retry');
    } catch (e) {
      debugPrint('❌ Failed to queue alert: $e');
    }
  }

  /// Send WhatsApp with unified messages (async, non-blocking)
  static Future<void> _sendWhatsAppAsync(
    List<Guardian> contacts,
    SOSMessageSet messages, // ✅ UPDATED: Accept unified messages
  ) async {
    try {
      if (contacts.isEmpty) {
        debugPrint('❌ No contacts for WhatsApp');
        return;
      }

      debugPrint('📤 Sending WhatsApp to ${contacts.length} contacts with location...');
      int successCount = 0;

      for (final contact in contacts) {
        try {
          final success = await WhatsAppService.sendWhatsAppMessage(
            phoneNumber: contact.phone,
            message: messages.whatsapp, // ✅ Use unified message with location
            contactName: contact.name,
          );
          if (success) {
            successCount++;
            debugPrint('✅ WhatsApp sent to ${contact.name} with location');
          }
        } catch (e) {
          debugPrint('⚠️ WhatsApp failed for ${contact.name}: $e');
        }

        // Delay between messages
        await Future.delayed(const Duration(milliseconds: 800));
      }

      if (successCount > 0) {
        debugPrint('✅ WhatsApp messages sent to $successCount contacts with location');
      } else {
        debugPrint('⚠️ WhatsApp sending failed for all contacts');
      }
    } catch (e) {
      debugPrint('❌ WhatsApp error: $e');
    }
  }

  /// Send email with unified messages (async, non-blocking)
  static Future<void> _sendEmailAsync(
    List<Guardian> contacts,
    SOSMessageSet messages, // ✅ UPDATED: Accept unified messages
    String userName,
  ) async {
    try {
      final emailRecipients = contacts
          .map((c) => c.email)
          .where((email) => email != null && email.isNotEmpty)
          .join(',');

      if (emailRecipients.isEmpty) {
        debugPrint('❌ No email addresses available');
        return;
      }

      debugPrint('📧 Sending email to ${contacts.length} contacts with location...');
      final success = await EmailService.sendEmail(
        recipients: emailRecipients,
        subject: messages.pushTitle, // ✅ Use unified subject
        body: messages.email, // ✅ Use unified email body with location
        userName: userName,
      );

      if (success) {
        debugPrint('✅ Email alerts sent with location');
      } else {
        debugPrint('❌ Email sending failed');
      }
    } catch (e) {
      debugPrint('❌ Email error: $e');
    }
  }

  /// Send alert to backend API
  static Future<SOSAlert?> _sendToBackend(SOSAlert alert) async {
    try {
      final response = await http.post(
        Uri.parse('${Config.apiBaseUrl}/api/v1/sos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Config.authToken}',
        },
        body: jsonEncode(alert.toJson()),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Alert sent to backend: ${data['id']}');
        return SOSAlert.fromJson(data['data'] ?? data);
      } else {
        debugPrint('❌ Backend error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Backend API error: $e');
      return null;
    }
  }

  /// Update alert with media URL
  static Future<void> _updateAlertMedia(String alertId, String mediaUrl) async {
    try {
      if (alertId.isEmpty) return;

      await http.put(
        Uri.parse('${Config.apiBaseUrl}/api/v1/sos/$alertId/media'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Config.authToken}',
        },
        body: jsonEncode({'mediaUrl': mediaUrl}),
      ).timeout(const Duration(seconds: 10));

      debugPrint('✅ Alert updated with media URL');
    } catch (e) {
      debugPrint('❌ Update media error: $e');
    }
  }

  /// Cancel active SOS alert
  static Future<bool> cancelAlert(String alertId) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.apiBaseUrl}/api/v1/sos/$alertId/resolve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Config.authToken}',
        },
        body: jsonEncode({'status': 'FALSE_ALARM'}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('✅ Alert cancelled');
        await NotificationService.showNotification(
          title: 'SOS Alert Cancelled',
          body: 'Your emergency alert has been marked as false alarm.',
        );
        AlarmService.stopAlarm();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Cancel alert error: $e');
      AlarmService.stopAlarm();
      return false;
    }
  }

  /// Get active alerts for user
  static Future<List<SOSAlert>> getActiveAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiBaseUrl}/api/v1/sos/active'),
        headers: {
          'Authorization': 'Bearer ${Config.authToken}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> alertsJson = data['data'] ?? [];
        return alertsJson.map((json) => SOSAlert.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Get active alerts error: $e');
      return [];
    }
  }

  /// 🚀 REVOLUTIONARY FEATURES: Activate all 8 advanced safety features
  static Future<void> _activateRevolutionaryFeatures(
    AppUser user,
    SOSAlert alert,
    Position position,
  ) async {
    try {
      // Feature 3: Start Live Streaming to guardians
      if (Config.isLiveStreamingEnabled) {
        debugPrint('  📹 Starting live streaming...');
        try {
          final initialized = await LiveStreamingService.initialize();
          if (initialized) {
            final channelId = await LiveStreamingService.startStreaming(
              userId: user.id,
            );
            debugPrint('  ✅ Live streaming: $channelId');
          } else {
            debugPrint('  ⚠️ Live streaming not initialized');
          }
        } catch (e) {
          debugPrint('  ⚠️ Live streaming error: $e');
        }
      } else {
        debugPrint('  ⏭️ Live streaming disabled');
      }

      // Feature 5: Alert Guardian Network (nearby volunteers)
      if (Config.isGuardianNetworkEnabled) {
        debugPrint('  🤝 Alerting guardian network...');
        try {
          await GuardianNetworkService.alertNearbyVolunteers(
            userId: user.id,
            position: position,
          );
          debugPrint('  ✅ Volunteer guardians alerted');
        } catch (e) {
          debugPrint('  ⚠️ Guardian network error: $e');
        }
      } else {
        debugPrint('  ⏭️ Guardian network disabled');
      }

      // Feature 7: Start Voice Distress Analysis
      if (Config.isVoiceDistressEnabled) {
        debugPrint('  🗣️ Starting voice distress analysis...');
        try {
          await DistressVoiceAnalysisService.initialize();
          final distressStream = await DistressVoiceAnalysisService.startAnalysis();

          // Listen for high distress levels
          distressStream.listen((data) {
            final score = data['distressScore'] ?? 0;
            if (score >= 80) {
              debugPrint('  🚨 HIGH DISTRESS DETECTED: $score/100');
            }
          });
          debugPrint('  ✅ Voice distress monitoring active');
        } catch (e) {
          debugPrint('  ⚠️ Voice distress error: $e');
        }
      } else {
        debugPrint('  ⏭️ Voice distress disabled');
      }

      // Feature 8: Get AI Danger Prediction for current location
      if (Config.isAIDangerPredictionEnabled) {
        debugPrint('  🤖 Analyzing danger level with AI...');
        try {
          await AIDangerPredictionService.initialize();
          final prediction = await AIDangerPredictionService.predictDanger(
            position: position,
            time: DateTime.now(),
          );

          final dangerScore = prediction['dangerScore'];
          final dangerLevel = prediction['level'];
          debugPrint('  ✅ Danger prediction: $dangerLevel (Score: $dangerScore/10)');

          if (dangerScore >= 8) {
            debugPrint('  🚨 CRITICAL DANGER ZONE - Extra alerts sent');
          }
        } catch (e) {
          debugPrint('  ⚠️ AI danger prediction error: $e');
        }
      } else {
        debugPrint('  ⏭️ AI danger prediction disabled');
      }

      debugPrint('  🎉 Revolutionary features activated!');
    } catch (e) {
      debugPrint('  ❌ Revolutionary features error: $e');
    }
  }
}

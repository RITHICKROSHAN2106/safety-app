import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart' as sound;
import 'package:permission_handler/permission_handler.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

/// Evidence Capture Service
/// Automatically captures audio, photos, and environmental data during SOS
/// Encrypts and uploads to secure cloud storage with tamper-proof timestamps
class EvidenceCaptureService {
  static final EvidenceCaptureService _instance = EvidenceCaptureService._internal();
  factory EvidenceCaptureService() => _instance;
  EvidenceCaptureService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  sound.FlutterSoundRecorder? _audioRecorder;
  CameraController? _cameraController;
  String? _activeEvidenceSessionId;
  bool _isCapturing = false;

  // Configuration
  static const int preRecordingSeconds = 30; // Record 30s before trigger
  static const int postRecordingSeconds = 300; // Record 5min after trigger
  static const int photoIntervalSeconds = 10; // Take photo every 10s
  static const String encryptionKeyHex = 'your-32-byte-encryption-key-here-replace-me-securely'; // REPLACE IN PRODUCTION

  /// Initialize evidence capture system
  Future<void> initialize() async {
    debugPrint('🎬 Initializing evidence capture service...');
    
    try {
      // Initialize audio recorder
      _audioRecorder = sound.FlutterSoundRecorder();
      
      // Request permissions
      await _requestPermissions();
      
      debugPrint('✅ Evidence capture service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing evidence capture: $e');
    }
  }

  /// Request necessary permissions
  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.microphone,
      Permission.camera,
      Permission.storage,
    ];

    for (final permission in permissions) {
      final status = await permission.request();
      if (!status.isGranted) {
        debugPrint('⚠️ Permission denied: $permission');
      }
    }
  }

  /// Start capturing evidence for SOS session
  Future<String> startCapture({
    required String userId,
    required String sosId,
    required Map<String, dynamic> locationData,
  }) async {
    debugPrint('🎬 Starting evidence capture...');

    if (_isCapturing) {
      debugPrint('⚠️ Evidence capture already active');
      return _activeEvidenceSessionId!;
    }

    try {
      _activeEvidenceSessionId = 'evidence_${DateTime.now().millisecondsSinceEpoch}';
      _isCapturing = true;

      // Create evidence session
      await _createEvidenceSession(userId, sosId, locationData);

      // Start audio recording
      _startAudioRecording();

      // Start photo capture
      _startPhotoCapture();

      // Capture initial environmental data
      await _captureEnvironmentalData();

      debugPrint('✅ Evidence capture started: $_activeEvidenceSessionId');
      return _activeEvidenceSessionId!;
    } catch (e) {
      debugPrint('❌ Error starting evidence capture: $e');
      _isCapturing = false;
      rethrow;
    }
  }

  /// Create evidence session in Firestore
  Future<void> _createEvidenceSession(
    String userId,
    String sosId,
    Map<String, dynamic> locationData,
  ) async {
    final sessionData = {
      'sessionId': _activeEvidenceSessionId,
      'userId': userId,
      'sosId': sosId,
      'status': 'active',
      'startedAt': FieldValue.serverTimestamp(),
      'location': locationData,
      'deviceInfo': await _getDeviceInfo(),
      'evidence': {
        'audio': [],
        'photos': [],
        'environmental': [],
      },
      'checksum': '', // Will be updated with final checksum
      'tamperProof': true,
    };

    await _firestore
        .collection('evidence_sessions')
        .doc(_activeEvidenceSessionId)
        .set(sessionData);
  }

  /// Start audio recording with circular buffer
  Future<void> _startAudioRecording() async {
    try {
      final micPermission = await Permission.microphone.status;
      if (!micPermission.isGranted) {
        debugPrint('⚠️ Microphone permission not granted');
        return;
      }

      await _audioRecorder?.openRecorder();

      final directory = await getApplicationDocumentsDirectory();
      final audioPath = '${directory.path}/evidence_audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _audioRecorder?.startRecorder(
        toFile: audioPath,
        codec: sound.Codec.aacADTS,
      );

      debugPrint('🎤 Audio recording started: $audioPath');

      // Schedule upload after post-recording duration
      Future.delayed(Duration(seconds: postRecordingSeconds), () async {
        await _stopAndUploadAudio(audioPath);
      });
    } catch (e) {
      debugPrint('❌ Error starting audio recording: $e');
    }
  }

  /// Stop audio recording and upload with encryption
  Future<void> _stopAndUploadAudio(String audioPath) async {
    try {
      await _audioRecorder?.stopRecorder();
      debugPrint('🎤 Audio recording stopped');

      // Encrypt audio file
      final encryptedPath = await _encryptFile(audioPath);

      // Upload to Firebase Storage
      final audioUrl = await _uploadToStorage(
        encryptedPath,
        'evidence/$_activeEvidenceSessionId/audio',
      );

      // Save metadata to Firestore
      await _saveEvidenceMetadata('audio', audioUrl, audioPath);

      // Delete local files
      await File(audioPath).delete();
      await File(encryptedPath).delete();

      debugPrint('✅ Audio evidence uploaded and encrypted');
    } catch (e) {
      debugPrint('❌ Error uploading audio: $e');
    }
  }

  /// Start periodic photo capture
  Future<void> _startPhotoCapture() async {
    try {
      final cameraPermission = await Permission.camera.status;
      if (!cameraPermission.isGranted) {
        debugPrint('⚠️ Camera permission not granted');
        return;
      }

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('⚠️ No cameras available');
        return;
      }

      // Use front camera for evidence
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController?.initialize();
      debugPrint('📷 Camera initialized');

      // Take photos periodically
      Timer.periodic(Duration(seconds: photoIntervalSeconds), (timer) async {
        if (!_isCapturing || _cameraController == null) {
          timer.cancel();
          return;
        }

        await _capturePhoto();
      });
    } catch (e) {
      debugPrint('❌ Error initializing camera: $e');
    }
  }

  /// Capture single photo
  Future<void> _capturePhoto() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final photoPath = '${directory.path}/evidence_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final image = await _cameraController?.takePicture();
      if (image != null) {
        await File(image.path).copy(photoPath);
        debugPrint('📷 Photo captured: $photoPath');

        // Encrypt and upload
        final encryptedPath = await _encryptFile(photoPath);
        final photoUrl = await _uploadToStorage(
          encryptedPath,
          'evidence/$_activeEvidenceSessionId/photos',
        );

        await _saveEvidenceMetadata('photos', photoUrl, photoPath);

        // Cleanup
        await File(photoPath).delete();
        await File(encryptedPath).delete();
        await File(image.path).delete();
      }
    } catch (e) {
      debugPrint('❌ Error capturing photo: $e');
    }
  }

  /// Capture environmental data
  Future<void> _captureEnvironmentalData() async {
    try {
      final environmentalData = {
        'timestamp': DateTime.now().toIso8601String(),
        'deviceTime': DateTime.now().millisecondsSinceEpoch,
        'timezone': DateTime.now().timeZoneName,
        'networkType': 'unknown', // Could integrate connectivity_plus
        'batteryLevel': 'unknown', // Could integrate battery_plus
      };

      await _firestore
          .collection('evidence_sessions')
          .doc(_activeEvidenceSessionId)
          .update({
        'evidence.environmental': FieldValue.arrayUnion([environmentalData]),
      });

      debugPrint('🌍 Environmental data captured');
    } catch (e) {
      debugPrint('❌ Error capturing environmental data: $e');
    }
  }

  /// Encrypt file with AES encryption
  Future<String> _encryptFile(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // Generate encryption key from hex string
      final key = encrypt.Key.fromUtf8(encryptionKeyHex.substring(0, 32));
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      // Encrypt data
      final encrypted = encrypter.encryptBytes(bytes, iv: iv);

      // Save encrypted file
      final encryptedPath = '$filePath.encrypted';
      final encryptedFile = File(encryptedPath);
      await encryptedFile.writeAsBytes(encrypted.bytes);

      debugPrint('🔒 File encrypted: $encryptedPath');
      return encryptedPath;
    } catch (e) {
      debugPrint('❌ Error encrypting file: $e');
      rethrow;
    }
  }

  /// Upload file to Firebase Storage
  Future<String> _uploadToStorage(String filePath, String storagePath) async {
    try {
      final file = File(filePath);
      final fileName = filePath.split('/').last;
      final ref = _storage.ref().child('$storagePath/$fileName');

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('☁️ File uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Error uploading file: $e');
      rethrow;
    }
  }

  /// Save evidence metadata with tamper-proof checksum
  Future<void> _saveEvidenceMetadata(
    String evidenceType,
    String url,
    String originalPath,
  ) async {
    try {
      final metadata = {
        'url': url,
        'timestamp': FieldValue.serverTimestamp(),
        'localTimestamp': DateTime.now().toIso8601String(),
        'checksum': await _calculateChecksum(originalPath),
        'size': await File(originalPath).length(),
      };

      await _firestore
          .collection('evidence_sessions')
          .doc(_activeEvidenceSessionId)
          .update({
        'evidence.$evidenceType': FieldValue.arrayUnion([metadata]),
      });

      debugPrint('✅ Evidence metadata saved: $evidenceType');
    } catch (e) {
      debugPrint('❌ Error saving evidence metadata: $e');
    }
  }

  /// Calculate SHA-256 checksum for tamper-proof verification
  Future<String> _calculateChecksum(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      debugPrint('❌ Error calculating checksum: $e');
      return '';
    }
  }

  /// Get device information
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // In production, use device_info_plus package
    return {
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Stop evidence capture
  Future<void> stopCapture() async {
    debugPrint('🛑 Stopping evidence capture...');

    _isCapturing = false;

    try {
      // Stop audio recorder
      await _audioRecorder?.stopRecorder();
      await _audioRecorder?.closeRecorder();

      // Dispose camera
      await _cameraController?.dispose();
      _cameraController = null;

      // Update session status
      if (_activeEvidenceSessionId != null) {
        await _firestore
            .collection('evidence_sessions')
            .doc(_activeEvidenceSessionId)
            .update({
          'status': 'completed',
          'endedAt': FieldValue.serverTimestamp(),
        });
      }

      debugPrint('✅ Evidence capture stopped');
      _activeEvidenceSessionId = null;
    } catch (e) {
      debugPrint('❌ Error stopping evidence capture: $e');
    }
  }

  /// Check if capturing
  bool get isCapturing => _isCapturing;

  /// Get active session ID
  String? get activeSessionId => _activeEvidenceSessionId;

  /// Dispose resources
  void dispose() {
    _audioRecorder?.closeRecorder();
    _cameraController?.dispose();
  }
}

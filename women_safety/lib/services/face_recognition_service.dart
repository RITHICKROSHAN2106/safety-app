import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 👤 Face Recognition Service - Verify trusted contacts during SOS
class FaceRecognitionService {
  // ignore: deprecated_member_use
  static final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(
      enableLandmarks: true,
      enableContours: true,
      enableClassification: true,
    ),
  );
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Register guardian's face
  static Future<bool> registerGuardianFace({
    required String guardianId,
    required String imagePath,
  }) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        debugPrint('❌ No face detected in image');
        return false;
      }

      // Store face data (in production, use proper face embeddings)
      final face = faces.first;
      await _firestore.collection('guardian_faces').doc(guardianId).set({
        'guardianId': guardianId,
        'boundingBox': {
          'left': face.boundingBox.left,
          'top': face.boundingBox.top,
          'width': face.boundingBox.width,
          'height': face.boundingBox.height,
        },
        'registeredAt': FieldValue.serverTimestamp(),
        'imagePath': imagePath,
      });

      debugPrint('✅ Guardian face registered');
      return true;
    } catch (e) {
      debugPrint('❌ Register face error: $e');
      return false;
    }
  }

  /// Capture and verify face during SOS
  static Future<Map<String, dynamic>> verifyFace() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);

      if (image == null) {
        return {'verified': false, 'error': 'No image captured'};
      }

      final inputImage = InputImage.fromFilePath(image.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        return {'verified': false, 'error': 'No face detected'};
      }

      // Compare with registered faces
      final guardianFaces = await _firestore.collection('guardian_faces').get();
      
      double bestScore = 0.0;
      String? matchedGuardian;
      for (final doc in guardianFaces.docs) {
        final registered = doc.data();
        final box = registered['boundingBox'];
        final faceBox = faces.first.boundingBox;
        // Simple overlap ratio test (placeholder for embedding similarity)
        final overlapWidth = _overlap(faceBox.left, faceBox.right, box['left'].toDouble(), box['left'].toDouble() + box['width'].toDouble());
        final overlapHeight = _overlap(faceBox.top, faceBox.bottom, box['top'].toDouble(), box['top'].toDouble() + box['height'].toDouble());
        final overlapArea = (overlapWidth * overlapHeight).clamp(0.0, double.infinity);
        final faceArea = faceBox.width * faceBox.height;
        final score = (overlapArea / faceArea).clamp(0.0, 1.0);
        if (score > bestScore) {
          bestScore = score;
          matchedGuardian = registered['guardianId'];
        }
      }

      if (matchedGuardian != null && bestScore > 0.3) {
        return {
          'verified': true,
          'guardianId': matchedGuardian,
          'confidence': bestScore,
        };
      }

      return {'verified': false, 'error': 'No matching face found'};
    } catch (e) {
      debugPrint('❌ Verify face error: $e');
      return {'verified': false, 'error': e.toString()};
    }
  }

  static double _overlap(double aStart, double aEnd, double bStart, double bEnd) {
    final start = aStart > bStart ? aStart : bStart;
    final end = aEnd < bEnd ? aEnd : bEnd;
    return (end - start).clamp(0.0, double.infinity);
  }

  /// Detect faces in current view (for auto-recording)
  static Future<List<Face>> detectFaces(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final faces = await _faceDetector.processImage(inputImage);
      debugPrint('✅ Detected ${faces.length} faces');
      return faces;
    } catch (e) {
      debugPrint('❌ Detect faces error: $e');
      return [];
    }
  }

  /// Dispose detector
  static Future<void> dispose() async {
    await _faceDetector.close();
  }
}

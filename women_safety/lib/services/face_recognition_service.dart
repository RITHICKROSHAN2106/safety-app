import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;

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
      final descriptor = _buildFaceDescriptor(face);

      await _firestore.collection('guardian_faces').doc(guardianId).set({
        'guardianId': guardianId,
        'boundingBox': {
          'left': face.boundingBox.left,
          'top': face.boundingBox.top,
          'width': face.boundingBox.width,
          'height': face.boundingBox.height,
        },
        'descriptor': descriptor,
        'qualityScore': _estimateQualityScore(face),
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
        final storedDescriptor = List<double>.from(
          (registered['descriptor'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) => (e as num).toDouble()),
        );
        final liveDescriptor = _buildFaceDescriptor(faces.first);

        if (storedDescriptor.isEmpty || liveDescriptor.isEmpty) {
          continue;
        }

        final score = _cosineSimilarity(storedDescriptor, liveDescriptor);
        if (score > bestScore) {
          bestScore = score;
          matchedGuardian = registered['guardianId'];
        }
      }

      if (matchedGuardian != null && bestScore > 0.82) {
        return {
          'verified': true,
          'guardianId': matchedGuardian,
          'confidence': (bestScore * 100).round(),
        };
      }

      return {'verified': false, 'error': 'No matching face found'};
    } catch (e) {
      debugPrint('❌ Verify face error: $e');
      return {'verified': false, 'error': e.toString()};
    }
  }

  static List<double> _buildFaceDescriptor(Face face) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye]?.position;
    final rightEye = face.landmarks[FaceLandmarkType.rightEye]?.position;
    final noseBase = face.landmarks[FaceLandmarkType.noseBase]?.position;
    final mouthBottom = face.landmarks[FaceLandmarkType.bottomMouth]?.position;

    final width = face.boundingBox.width == 0 ? 1.0 : face.boundingBox.width;
    final height = face.boundingBox.height == 0 ? 1.0 : face.boundingBox.height;

    double normDx(dynamic a, dynamic b) {
      if (a == null || b == null) return 0.0;
      return ((a.x - b.x).abs() as num).toDouble() / width;
    }

    double normDy(dynamic a, dynamic b) {
      if (a == null || b == null) return 0.0;
      return ((a.y - b.y).abs() as num).toDouble() / height;
    }

    return <double>[
      width / height,
      face.smilingProbability ?? 0.0,
      face.leftEyeOpenProbability ?? 0.0,
      face.rightEyeOpenProbability ?? 0.0,
      (face.headEulerAngleX ?? 0.0) / 45.0,
      (face.headEulerAngleY ?? 0.0) / 45.0,
      (face.headEulerAngleZ ?? 0.0) / 45.0,
      normDx(leftEye, rightEye),
      normDy(leftEye, rightEye),
      normDx(noseBase, mouthBottom),
      normDy(noseBase, mouthBottom),
    ];
  }

  static double _estimateQualityScore(Face face) {
    var score = 0.5;
    if (face.smilingProbability != null) score += 0.1;
    if (face.leftEyeOpenProbability != null) score += 0.1;
    if (face.rightEyeOpenProbability != null) score += 0.1;
    if (face.landmarks.isNotEmpty) score += 0.2;
    return score.clamp(0.0, 1.0);
  }

  static double _cosineSimilarity(List<double> a, List<double> b) {
    final length = math.min(a.length, b.length);
    if (length == 0) return 0.0;

    var dot = 0.0;
    var normA = 0.0;
    var normB = 0.0;
    for (var i = 0; i < length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) return 0.0;
    return dot / (math.sqrt(normA) * math.sqrt(normB));
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

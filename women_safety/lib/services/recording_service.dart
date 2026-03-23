import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RecordingService {
  static CameraController? _cameraController;
  static bool _isRecording = false;

  /// Start video recording (front camera for safety)
  static Future<String?> startVideoRecording() async {
    try {
      // Check camera and microphone permissions
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();

      if (!cameraStatus.isGranted || !micStatus.isGranted) {
        debugPrint('❌ Camera/Microphone permission denied');
        return null;
      }

      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('❌ No cameras available');
        return null;
      }

      // Initialize camera (front camera preferred for safety)
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await _cameraController!.initialize();
      
      // Start recording
      await _cameraController!.startVideoRecording();
      _isRecording = true;

      debugPrint('✅ Video recording started');
      return 'recording';
    } catch (e) {
      debugPrint('❌ Start recording error: $e');
      await dispose();
      return null;
    }
  }

  /// Stop video recording and return file path
  static Future<String?> stopVideoRecording() async {
    try {
      if (_cameraController == null || !_isRecording) {
        debugPrint('❌ No active recording');
        return null;
      }

      final XFile videoFile = await _cameraController!.stopVideoRecording();
      _isRecording = false;

      // Get app directory for permanent storage
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String videoPath = '${appDir.path}/sos_videos';
      final Directory videoDir = Directory(videoPath);
      
      // Create directory if it doesn't exist
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      // Move video to permanent location with timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String finalPath = '$videoPath/sos_video_$timestamp.mp4';
      final File finalFile = await File(videoFile.path).copy(finalPath);

      // Dispose camera controller
      await dispose();

      debugPrint('✅ Video saved: $finalPath');
      return finalFile.path;
    } catch (e) {
      debugPrint('❌ Stop recording error: $e');
      await dispose();
      return null;
    }
  }

  /// Record for specified duration (e.g., 30 seconds)
  static Future<String?> recordForDuration(Duration duration) async {
    try {
      final started = await startVideoRecording();
      if (started == null) {
        return null;
      }
      
      // Wait for specified duration
      await Future.delayed(duration);
      
      return await stopVideoRecording();
    } catch (e) {
      debugPrint('❌ Timed recording error: $e');
      await dispose();
      return null;
    }
  }

  /// Record video in background (starts and returns immediately)
  /// Call stopVideoRecording() when you want to stop
  static Future<bool> startBackgroundRecording() async {
    final result = await startVideoRecording();
    return result != null;
  }

  /// Get recording status
  static bool get isRecording => _isRecording;

  /// Get camera controller (for preview widget if needed)
  static CameraController? get cameraController => _cameraController;

  /// Clean up camera resources
  static Future<void> dispose() async {
    try {
      if (_cameraController != null) {
        if (_isRecording) {
          try {
            await _cameraController!.stopVideoRecording();
          } catch (e) {
            debugPrint('⚠️ Error stopping recording during dispose: $e');
          }
        }
        await _cameraController!.dispose();
        _cameraController = null;
      }
      _isRecording = false;
    } catch (e) {
      debugPrint('⚠️ Error disposing camera: $e');
    }
  }

  /// Delete old recordings (older than specified days)
  static Future<void> cleanOldRecordings({int olderThanDays = 7}) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String videoPath = '${appDir.path}/sos_videos';
      final Directory videoDir = Directory(videoPath);

      if (!await videoDir.exists()) {
        return;
      }

      final List<FileSystemEntity> files = videoDir.listSync();
      final DateTime cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));

      for (var file in files) {
        if (file is File) {
          final FileStat stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            debugPrint('🗑️ Deleted old recording: ${file.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error cleaning old recordings: $e');
    }
  }

  /// Get all recorded videos
  static Future<List<String>> getAllRecordings() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String videoPath = '${appDir.path}/sos_videos';
      final Directory videoDir = Directory(videoPath);

      if (!await videoDir.exists()) {
        return [];
      }

      final List<FileSystemEntity> files = videoDir.listSync();
      return files
          .whereType<File>()
          .map((file) => file.path)
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting recordings: $e');
      return [];
    }
  }
}

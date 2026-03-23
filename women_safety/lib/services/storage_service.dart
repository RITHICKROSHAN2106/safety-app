import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload SOS video to Firebase Storage
  static Future<String?> uploadSOSVideo({
    required String filePath,
    required String userId,
    Function(double)? onProgress,
  }) async {
    try {
      final File file = File(filePath);
      if (!await file.exists()) {
        debugPrint('❌ File does not exist: $filePath');
        return null;
      }

      // Create unique filename with timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'sos_video_${userId}_$timestamp.mp4';
      final String storagePath = 'sos_media/$userId/$fileName';

      // Create storage reference
      final Reference ref = _storage.ref().child(storagePath);

      // Upload file with metadata
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'video/mp4',
          customMetadata: {
            'userId': userId,
            'timestamp': timestamp,
            'type': 'sos_video',
          },
        ),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
        debugPrint('📤 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ Video uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      return null;
    }
  }

  /// Upload any file (image, audio, video)
  static Future<String?> uploadFile({
    required String filePath,
    required String userId,
    required String fileType, // 'image', 'audio', 'video'
    Function(double)? onProgress,
  }) async {
    try {
      final File file = File(filePath);
      if (!await file.exists()) {
        debugPrint('❌ File does not exist: $filePath');
        return null;
      }

      // Determine content type
      String contentType = 'application/octet-stream';
      String extension = filePath.split('.').last.toLowerCase();
      
      switch (fileType) {
        case 'image':
          contentType = 'image/$extension';
          break;
        case 'audio':
          contentType = 'audio/$extension';
          break;
        case 'video':
          contentType = 'video/$extension';
          break;
      }

      // Create unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'sos_${fileType}_${userId}_$timestamp.$extension';
      final String storagePath = 'sos_media/$userId/$fileName';

      // Upload file
      final Reference ref = _storage.ref().child(storagePath);
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'userId': userId,
            'timestamp': timestamp,
            'type': 'sos_$fileType',
          },
        ),
      );

      // Monitor progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
      });

      // Wait for completion
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ File uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      return null;
    }
  }

  /// Delete file from Firebase Storage
  static Future<bool> deleteFile(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      debugPrint('✅ File deleted: $downloadUrl');
      return true;
    } catch (e) {
      debugPrint('❌ Delete error: $e');
      return false;
    }
  }

  /// Get all SOS media files for a user
  static Future<List<String>> getUserSOSMedia(String userId) async {
    try {
      final Reference ref = _storage.ref().child('sos_media/$userId');
      final ListResult result = await ref.listAll();

      final List<String> downloadUrls = [];
      for (var item in result.items) {
        final String url = await item.getDownloadURL();
        downloadUrls.add(url);
      }

      return downloadUrls;
    } catch (e) {
      debugPrint('❌ Error fetching user media: $e');
      return [];
    }
  }

  /// Clean up old files (older than specified days)
  static Future<void> cleanOldFiles({
    required String userId,
    int olderThanDays = 30,
  }) async {
    try {
      final Reference ref = _storage.ref().child('sos_media/$userId');
      final ListResult result = await ref.listAll();

      final DateTime cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));

      for (var item in result.items) {
        final FullMetadata metadata = await item.getMetadata();
        if (metadata.timeCreated != null &&
            metadata.timeCreated!.isBefore(cutoffDate)) {
          await item.delete();
          debugPrint('🗑️ Deleted old file: ${item.name}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error cleaning old files: $e');
    }
  }

  /// Cancel ongoing upload
  static void cancelUpload(UploadTask uploadTask) {
    try {
      uploadTask.cancel();
      debugPrint('⏹️ Upload cancelled');
    } catch (e) {
      debugPrint('❌ Cancel error: $e');
    }
  }
}

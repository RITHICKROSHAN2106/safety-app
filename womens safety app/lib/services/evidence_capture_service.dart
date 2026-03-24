import 'dart:io';

import 'package:image_picker/image_picker.dart';

class EvidenceCaptureService {
  final ImagePicker _picker = ImagePicker();

  Future<EvidenceCaptureResult?> capturePhotoEvidence({
    required EvidenceSource source,
    String? note,
  }) async {
    final image = await _picker.pickImage(
      source: source == EvidenceSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );

    if (image == null) {
      return null;
    }

    final file = File(image.path);
    final sizeBytes = await file.length();

    return EvidenceCaptureResult(
      filePath: image.path,
      capturedAt: DateTime.now(),
      sizeBytes: sizeBytes,
      note: note,
      type: EvidenceType.photo,
    );
  }
}

enum EvidenceSource { camera, gallery }

enum EvidenceType { photo }

class EvidenceCaptureResult {
  final String filePath;
  final DateTime capturedAt;
  final int sizeBytes;
  final String? note;
  final EvidenceType type;

  EvidenceCaptureResult({
    required this.filePath,
    required this.capturedAt,
    required this.sizeBytes,
    required this.type,
    this.note,
  });
}

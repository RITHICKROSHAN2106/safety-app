/// Distress Voice Analysis Service
/// Detects distress keywords and patterns in voice input
/// Stub implementation with basic keyword detection
import 'dart:async';

class DistressVoiceAnalysisService {
  // Distress keywords to detect
  static const List<String> _distressKeywords = [
    'help',
    'emergency',
    'danger',
    'scared',
    'attack',
    'stop',
    'police',
    'fire',
    'ambulance',
    'save me',
    'leave me',
    'let go',
  ];

  StreamController<VoiceAnalysisResult>? _analysisController;
  bool _isListening = false;

  // Check if currently listening
  bool get isListening => _isListening;

  // Start voice analysis
  Future<void> startListening({
    required Function(VoiceAnalysisResult) onDistressDetected,
  }) async {
    if (_isListening) return;

    _isListening = true;
    _analysisController = StreamController<VoiceAnalysisResult>.broadcast();

    // TODO: Implement actual speech recognition
    // Use speech_to_text package or google_ml_kit
    // For now, this is a stub

    print('Voice analysis started - listening for distress keywords');

    // Simulate listening
    _analysisController!.stream.listen((result) {
      if (result.isDistress) {
        onDistressDetected(result);
      }
    });
  }

  // Stop voice analysis
  Future<void> stopListening() async {
    if (!_isListening) return;

    _isListening = false;
    await _analysisController?.close();
    _analysisController = null;

    print('Voice analysis stopped');
  }

  // Analyze text for distress keywords (manual testing)
  VoiceAnalysisResult analyzeText(String text) {
    String lowerText = text.toLowerCase();
    List<String> detectedKeywords = [];

    for (String keyword in _distressKeywords) {
      if (lowerText.contains(keyword)) {
        detectedKeywords.add(keyword);
      }
    }

    bool isDistress = detectedKeywords.isNotEmpty;
    double confidenceScore = isDistress ? 0.85 : 0.0;

    return VoiceAnalysisResult(
      isDistress: isDistress,
      confidence: confidenceScore,
      detectedKeywords: detectedKeywords,
      transcription: text,
      timestamp: DateTime.now(),
    );
  }

  // Simulate voice input (for testing)
  void simulateVoiceInput(String text) {
    if (!_isListening) return;

    final result = analyzeText(text);
    _analysisController?.add(result);
  }

  // Get distress keyword list
  List<String> getDistressKeywords() {
    return List.unmodifiable(_distressKeywords);
  }

  // Check if text contains distress signal
  bool containsDistressSignal(String text) {
    String lowerText = text.toLowerCase();
    return _distressKeywords.any((keyword) => lowerText.contains(keyword));
  }

  // Dispose resources
  void dispose() {
    _analysisController?.close();
    _isListening = false;
  }
}

// Voice analysis result model
class VoiceAnalysisResult {
  final bool isDistress;
  final double confidence;
  final List<String> detectedKeywords;
  final String transcription;
  final DateTime timestamp;

  VoiceAnalysisResult({
    required this.isDistress,
    required this.confidence,
    required this.detectedKeywords,
    required this.transcription,
    required this.timestamp,
  });

  String get severityLevel {
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.5) return 'Medium';
    return 'Low';
  }

  String get alertMessage {
    if (isDistress) {
      return 'DISTRESS DETECTED: ${detectedKeywords.join(", ")}';
    }
    return 'No distress detected';
  }
}

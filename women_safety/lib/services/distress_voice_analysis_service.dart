import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// 🗣️ Distress Voice Analysis - Detect distress in voice tone
class DistressVoiceAnalysisService {
  static final SpeechToText _speech = SpeechToText();
  static bool _isAnalyzing = false;
  static StreamController<Map<String, dynamic>>? _distressStream;
  static int _distressScore = 0;
  static final List<String> _distressKeywords = [
    'help', 'stop', 'no', 'dont', 'please', 'scared', 'afraid',
    'emergency', 'danger', 'save', 'attack', 'hurt', 'pain'
  ];

  /// Initialize voice analysis
  static Future<bool> initialize() async {
    try {
      final available = await _speech.initialize();
      if (!available) {
        debugPrint('❌ Speech recognition not available');
        return false;
      }

      debugPrint('✅ Distress voice analysis initialized');
      return true;
    } catch (e) {
      debugPrint('❌ Initialize voice analysis error: $e');
      return false;
    }
  }

  /// Start analyzing voice for distress
  static Future<Stream<Map<String, dynamic>>> startAnalysis() async {
    if (_isAnalyzing) {
      return _distressStream!.stream;
    }

    _distressStream = StreamController<Map<String, dynamic>>.broadcast();
    _isAnalyzing = true;
    _distressScore = 0;

    try {
      await _speech.listen(
        onResult: (result) {
          _analyzeVoicePattern(result);
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          onDevice: false,
          listenMode: ListenMode.dictation,
          cancelOnError: false,
        ),
      );

      debugPrint('🎤 Started distress voice analysis');
    } catch (e) {
      debugPrint('❌ Start analysis error: $e');
      _isAnalyzing = false;
    }

    return _distressStream!.stream;
  }

  /// Analyze voice pattern for distress signals
  static void _analyzeVoicePattern(SpeechRecognitionResult result) {
    final transcript = result.recognizedWords.trim();
    if (transcript.isEmpty) {
      return;
    }

    final words = transcript.toLowerCase().split(RegExp(r'\s+'));
    
    // Check for distress keywords
    int keywordMatches = 0;
    final detectedKeywords = <String>[];
    for (final word in words) {
      for (final keyword in _distressKeywords) {
        if (word.contains(keyword)) {
          keywordMatches++;
          if (!detectedKeywords.contains(keyword)) {
            detectedKeywords.add(keyword);
          }
        }
      }
    }

    // Calculate distress score (0-100)
    _distressScore = (keywordMatches * 20).clamp(0, 100);

    // Check volume/tone (using confidence as proxy)
    final confidenceScore = (result.confidence * 100).toInt();
    
    // High volume (screaming) or very low confidence (trembling voice) indicates distress
    if (confidenceScore < 30 || confidenceScore > 90) {
      _distressScore += 20;
    }

    _distressScore = _distressScore.clamp(0, 100);

    // Emit distress level
    _distressStream?.add({
      'distressScore': _distressScore,
      'keywords': detectedKeywords,
      'keywordCount': keywordMatches,
      'confidence': result.confidence,
      'text': transcript,
      'isDistressed': _distressScore >= 60,
    });

    // Auto-trigger SOS if high distress
    if (_distressScore >= 80) {
      debugPrint('🚨 HIGH DISTRESS DETECTED! Score: $_distressScore');
      if (onHighDistress != null) {
        onHighDistress!(_distressScore, transcript);
      }
      _triggerAutoSOS(transcript);
    } else if (_distressScore >= 60) {
      debugPrint('⚠️ MODERATE DISTRESS DETECTED! Score: $_distressScore');
      if (onModerateDistress != null) {
        onModerateDistress!(_distressScore, transcript);
      }
    }
  }

  /// Auto-trigger SOS when distress detected
  static void _triggerAutoSOS(String transcript) {
    debugPrint('🚨 Auto-triggering SOS due to voice distress!');
    final callback = onAutoSOSRequested;
    if (callback != null) {
      callback(_distressScore, transcript);
    }
  }

  /// External callbacks for integration
  static void Function(int score, String transcript)? onHighDistress;
  static void Function(int score, String transcript)? onModerateDistress;
  static Future<void> Function(int score, String transcript)? onAutoSOSRequested;

  /// Stop voice analysis
  static Future<void> stopAnalysis() async {
    if (!_isAnalyzing) return;

    try {
      await _speech.stop();
      _isAnalyzing = false;
      await _distressStream?.close();
      _distressStream = null;
      _distressScore = 0;
      onAutoSOSRequested = null;

      debugPrint('✅ Distress voice analysis stopped');
    } catch (e) {
      debugPrint('❌ Stop analysis error: $e');
    }
  }

  /// Get current distress level (0-100)
  static int getCurrentDistressLevel() => _distressScore;

  /// Check if currently analyzing
  static bool get isAnalyzing => _isAnalyzing;

  /// Calibrate for user's normal voice
  static Future<void> calibrateVoice() async {
    // Record baseline voice patterns for the user
    debugPrint('🎤 Calibrating voice baseline...');
    // In production, this would record and store user's normal speech patterns
  }
}

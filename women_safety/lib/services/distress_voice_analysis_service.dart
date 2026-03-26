import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// 🗣️ Distress Voice Analysis - Detect distress in voice tone
class DistressVoiceAnalysisService {
  static final SpeechToText _speech = SpeechToText();
  static bool _isAnalyzing = false;
  static StreamController<Map<String, dynamic>>? _distressStream;
  static int _distressScore = 0;
  static DateTime? _lastAutoSOSAt;
  static const Duration _autoSOSCooldown = Duration(seconds: 20);

  static final List<String> _distressKeywords = [
    'help', 'stop', 'no', 'dont', 'please', 'scared', 'afraid',
    'emergency', 'danger', 'save', 'attack', 'hurt', 'pain', 'police', 'sos'
  ];

  static final List<String> _criticalDistressPhrases = [
    'help me',
    'call police',
    'someone is following me',
    'someone following me',
    'i am in danger',
    'im in danger',
    'save me',
    'dont touch me',
    'don\'t touch me',
    'stop following me',
    'he is attacking me',
    'she is attacking me',
    'call my guardian',
  ];

  /// Initialize voice analysis
  static Future<bool> initialize() async {
    try {
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        debugPrint('❌ Microphone permission denied for distress analysis');
        return false;
      }

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

    final normalizedTranscript = _normalize(transcript);
    final confidenceScore = result.confidence.clamp(0.0, 1.0);
    final criticalPhrasesDetected = _criticalDistressPhrases
        .where((phrase) => normalizedTranscript.contains(_normalize(phrase)))
        .toList(growable: false);

    final hasCriticalPhrase = criticalPhrasesDetected.isNotEmpty;

    // Check for distress keywords
    int keywordMatches = 0;
    final detectedKeywords = <String>[];
    for (final keyword in _distressKeywords) {
      final normalizedKeyword = _normalize(keyword);
      if (_containsKeyword(normalizedTranscript, normalizedKeyword)) {
        keywordMatches++;
        detectedKeywords.add(keyword);
      }
    }

    // Calculate distress score (0-100)
    if (hasCriticalPhrase) {
      _distressScore = 100;
    } else {
      _distressScore = (keywordMatches * 25).clamp(0, 100);

      if (keywordMatches >= 2) {
        _distressScore += 15;
      }

      if (confidenceScore >= 0.5 && confidenceScore <= 0.9) {
        _distressScore += 10;
      }
    }

    _distressScore = _distressScore.clamp(0, 100);

    final highConfidenceDistress = hasCriticalPhrase ||
      keywordMatches >= 1 ||
        (keywordMatches >= 2 && confidenceScore >= 0.5) ||
        _distressScore >= 85;

    // Emit distress level
    _distressStream?.add({
      'distressScore': _distressScore,
      'keywords': detectedKeywords,
      'criticalPhrases': criticalPhrasesDetected,
      'keywordCount': keywordMatches,
      'confidence': result.confidence,
      'text': transcript,
      'isDistressed': _distressScore >= 60 || hasCriticalPhrase,
      'isHighConfidenceDistress': highConfidenceDistress,
    });

    // Auto-trigger SOS if high distress
    final now = DateTime.now();
    final isCooldownElapsed = _lastAutoSOSAt == null ||
        now.difference(_lastAutoSOSAt!) >= _autoSOSCooldown;

    if ((_distressScore >= 80 || hasCriticalPhrase || keywordMatches >= 1) &&
        highConfidenceDistress &&
        isCooldownElapsed) {
      debugPrint('🚨 HIGH DISTRESS DETECTED! Score: $_distressScore');
      if (onHighDistress != null) {
        onHighDistress!(_distressScore, transcript);
      }
      _lastAutoSOSAt = now;
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
      _lastAutoSOSAt = null;
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

  /// Expose the active distress keywords for UI and testing.
  static List<String> get distressKeywords => List.unmodifiable(_distressKeywords);

  /// Calibrate for user's normal voice
  static Future<void> calibrateVoice() async {
    // Record baseline voice patterns for the user
    debugPrint('🎤 Calibrating voice baseline...');
    // In production, this would record and store user's normal speech patterns
  }

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9\s]"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _containsKeyword(String transcript, String normalizedKeyword) {
    if (normalizedKeyword.isEmpty || transcript.isEmpty) {
      return false;
    }

    if (normalizedKeyword.contains(' ')) {
      return transcript.contains(normalizedKeyword);
    }

    final pattern = RegExp('(^|\\s)${RegExp.escape(normalizedKeyword)}(\\s|\$)');
    return pattern.hasMatch(transcript);
  }
}

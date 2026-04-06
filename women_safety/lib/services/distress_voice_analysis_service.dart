import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// 🗣️ Distress Voice Analysis - Detect distress in voice tone
class DistressVoiceAnalysisService {
  static final SpeechToText _speech = SpeechToText();
  static bool _isAnalyzing = false;
  static bool _emergencyMode = false;
  static StreamController<Map<String, dynamic>>? _distressStream;
  static int _distressScore = 0;
  static DateTime? _lastAutoSOSAt;
  static const Duration _autoSOSCooldown = Duration(seconds: 20);
  static final List<int> _recentScores = <int>[];
  static const int _recentWindowSize = 5;

  static const List<String> _defaultDistressKeywords = [
    'help me',
    'emergency',
    'danger',
    'rescue',
    'need help',
  ];
  static List<String> _distressKeywords = List<String>.from(_defaultDistressKeywords);

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

  static final List<String> _fearWords = [
    'scared', 'afraid', 'terrified', 'panic', 'panicking', 'unsafe',
    'threat', 'threatening', 'trapped', 'followed', 'following',
  ];

  static final List<String> _coercionWords = [
    'dont', 'do not', 'leave me', 'stay away', 'stop', 'attacking',
    'touch', 'kidnap', 'harass', 'harassing',
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
  static Future<Stream<Map<String, dynamic>>> startAnalysis({
    bool emergencyMode = false,
  }) async {
    if (_isAnalyzing) {
      _emergencyMode = emergencyMode;
      return _distressStream!.stream;
    }

    _distressStream = StreamController<Map<String, dynamic>>.broadcast();
    _isAnalyzing = true;
    _emergencyMode = emergencyMode;
    _distressScore = 0;
    _recentScores.clear();

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

      debugPrint('🎤 Started distress voice analysis (emergencyMode=$_emergencyMode)');
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

    // Base keyword-driven score
    var keywordScore = 0;
    if (hasCriticalPhrase) {
      keywordScore = 100;
    } else {
      keywordScore = (keywordMatches * 25).clamp(0, 100);

      if (keywordMatches >= 2) {
        keywordScore += 15;
      }

      if (confidenceScore >= 0.5 && confidenceScore <= 0.9) {
        keywordScore += 10;
      }
    }

    final aiFeatures = _extractAIFeatures(
      transcript: transcript,
      normalizedTranscript: normalizedTranscript,
      confidence: confidenceScore,
      keywordMatches: keywordMatches,
      hasCriticalPhrase: hasCriticalPhrase,
    );
    final aiScore = _calculateAIScore(aiFeatures);

    // Blend keyword certainty + AI pattern score.
    _distressScore = ((keywordScore * 0.55) + (aiScore * 0.45)).round().clamp(0, 100);

    _recentScores.add(_distressScore);
    if (_recentScores.length > _recentWindowSize) {
      _recentScores.removeAt(0);
    }
    final rollingDistress = _recentScores.isEmpty
        ? _distressScore.toDouble()
        : _recentScores.reduce((a, b) => a + b) / _recentScores.length;

    final dynamicEscalation = _emergencyMode
        ? rollingDistress >= 62 || _distressScore >= 72
        : rollingDistress >= 70 || _distressScore >= 80;

    final highConfidenceDistress = hasCriticalPhrase ||
      keywordMatches >= (_emergencyMode ? 1 : 2) ||
        (keywordMatches >= 2 && confidenceScore >= 0.5) ||
        _distressScore >= (_emergencyMode ? 75 : 85) ||
        dynamicEscalation;

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
      'aiScore': aiScore,
      'aiFeatures': aiFeatures,
      'rollingDistress': rollingDistress,
      'emergencyMode': _emergencyMode,
    });

    // Auto-trigger SOS if high distress
    final now = DateTime.now();
    final isCooldownElapsed = _lastAutoSOSAt == null ||
        now.difference(_lastAutoSOSAt!) >= _autoSOSCooldown;

    final triggerThreshold = _emergencyMode ? 70 : 80;

    if ((_distressScore >= triggerThreshold || hasCriticalPhrase || keywordMatches >= 1) &&
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
      _emergencyMode = false;
      _recentScores.clear();
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
  static bool get isEmergencyMode => _emergencyMode;

  /// Expose the active distress keywords for UI and testing.
  static List<String> get distressKeywords => List.unmodifiable(_distressKeywords);

  /// Update distress keywords used by AI scoring.
  ///
  /// This keeps keyword-only detection and AI blended scoring in sync.
  static void updateDistressKeywords(
    List<String> keywords, {
    bool includeDefaults = true,
  }) {
    final normalizedKeywords = keywords
        .map((keyword) => _normalize(keyword))
        .where((keyword) => keyword.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final mergedKeywords = <String>{
      if (includeDefaults) ..._defaultDistressKeywords,
      ...normalizedKeywords,
    };

    _distressKeywords = mergedKeywords.toList(growable: false);
    debugPrint('🎯 Distress keywords updated: ${_distressKeywords.join(', ')}');
  }

  static void resetDistressKeywords() {
    _distressKeywords = List<String>.from(_defaultDistressKeywords);
  }

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

  static Map<String, dynamic> _extractAIFeatures({
    required String transcript,
    required String normalizedTranscript,
    required double confidence,
    required int keywordMatches,
    required bool hasCriticalPhrase,
  }) {
    final words = normalizedTranscript.split(' ').where((w) => w.isNotEmpty).toList();
    final uniqueWords = words.toSet();

    var fearCount = 0;
    for (final word in _fearWords) {
      if (_containsKeyword(normalizedTranscript, _normalize(word))) {
        fearCount++;
      }
    }

    var coercionCount = 0;
    for (final word in _coercionWords) {
      if (_containsKeyword(normalizedTranscript, _normalize(word))) {
        coercionCount++;
      }
    }

    final repeatedWordRatio = words.isEmpty ? 0.0 : 1 - (uniqueWords.length / words.length);
    final punctuationUrgency = transcript.contains('!') ? 1 : 0;
    final longUtterance = words.length >= 8 ? 1 : 0;

    return {
      'fearCount': fearCount,
      'coercionCount': coercionCount,
      'keywordMatches': keywordMatches,
      'criticalPhrase': hasCriticalPhrase ? 1 : 0,
      'confidence': confidence,
      'punctuationUrgency': punctuationUrgency,
      'longUtterance': longUtterance,
      'repeatedWordRatio': repeatedWordRatio,
    };
  }

  static int _calculateAIScore(Map<String, dynamic> features) {
    final fearCount = (features['fearCount'] as int?) ?? 0;
    final coercionCount = (features['coercionCount'] as int?) ?? 0;
    final keywordMatches = (features['keywordMatches'] as int?) ?? 0;
    final criticalPhrase = (features['criticalPhrase'] as int?) ?? 0;
    final confidence = (features['confidence'] as double?) ?? 0.0;
    final punctuationUrgency = (features['punctuationUrgency'] as int?) ?? 0;
    final longUtterance = (features['longUtterance'] as int?) ?? 0;
    final repeatedWordRatio = (features['repeatedWordRatio'] as double?) ?? 0.0;

    var score = 0.0;
    score += fearCount * 12.0;
    score += coercionCount * 10.0;
    score += keywordMatches * 8.0;
    score += criticalPhrase * 35.0;
    score += punctuationUrgency * 6.0;
    score += longUtterance * 5.0;
    score += repeatedWordRatio * 18.0;

    // Speech confidence influences certainty but shouldn't dominate severity.
    if (confidence >= 0.35) {
      score += 8.0;
    } else if (confidence < 0.2) {
      score -= 6.0;
    }

    return score.round().clamp(0, 100);
  }
}

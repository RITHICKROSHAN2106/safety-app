import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class VoiceActivationService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _isListening = false;
  static bool _isInitialized = false;
  static Function()? _onKeywordDetected;
  static Timer? _restartTimer;
  
  // Retry management
  static int _retryCount = 0;
  static const int _maxRetries = 5;
  static final int _backoffSeconds = 3;

  // Keywords that trigger SOS
  static final List<String> _keywords = [
    'help me',
    'help',
    'emergency',
    'sos',
    'danger',
    'save me',
  ];
  static List<String> _activeKeywords = List<String>.from(_keywords);

  /// Initialize speech recognition
  static Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      // Check microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        debugPrint('❌ Microphone permission denied');
        return false;
      }

      // Initialize speech recognition
      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('❌ Speech recognition error: $error');
          // Check retry limit before auto-restart
          if (_isListening && _retryCount < _maxRetries) {
            _restartListening();
          } else if (_retryCount >= _maxRetries) {
            debugPrint('⚠️ Max retry attempts reached ($_maxRetries). Voice recognition paused.');
            debugPrint('💡 Restart manually or wait for automatic cooldown.');
            _isListening = false;
          }
        },
        onStatus: (status) {
          debugPrint('🎤 Speech status: $status');
          if (status == 'done' && _isListening && _retryCount < _maxRetries) {
            // Auto-restart when done, but respect retry limits
            _restartListening();
          }
        },
      );

      if (_isInitialized) {
        debugPrint('✅ Voice activation initialized');
      } else {
        debugPrint('❌ Failed to initialize speech recognition');
      }

      return _isInitialized;
    } catch (e) {
      debugPrint('❌ Initialization error: $e');
      return false;
    }
  }

  /// Start listening for emergency keywords
  static Future<void> startListening({
    required Function() onKeywordDetected,
    List<String>? customKeywords,
  }) async {
    if (_isListening) {
      debugPrint('⚠️ Already listening for voice commands');
      return;
    }

    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        return;
      }
    }

    _onKeywordDetected = onKeywordDetected;
    _isListening = true;
    _retryCount = 0; // Reset retry count when starting fresh

    // Use custom keywords if provided
    final effectiveKeywords = (customKeywords ?? _keywords)
      .map((keyword) => keyword.trim())
      .where((keyword) => keyword.isNotEmpty)
      .toSet()
      .toList(growable: false);
    _activeKeywords = effectiveKeywords;

    debugPrint('🎤 Started listening for keywords: ${effectiveKeywords.join(", ")}');

    _startSpeechRecognition(effectiveKeywords);
  }

  /// Start speech recognition with keyword detection
  static void _startSpeechRecognition(List<String> keywords) {
    if (!_speech.isAvailable || !_isListening) {
      return;
    }

    _speech.listen(
      onResult: (result) {
        final String spokenWords = result.recognizedWords.toLowerCase();
        debugPrint('🗣️ Heard: "$spokenWords"');

        // Check if any keyword is detected
        for (final keyword in keywords) {
          if (_containsKeyword(spokenWords, keyword)) {
            debugPrint('🚨 EMERGENCY KEYWORD DETECTED: "$keyword"');
            _triggerKeywordDetected();
            break;
          }
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.confirmation,
      ),
    );
  }

  /// Restart listening (called automatically)
  static void _restartListening() {
    if (!_isListening) {
      return;
    }

    // Check retry limit
    if (_retryCount >= _maxRetries) {
      debugPrint('⚠️ Voice recognition retry limit reached. Stopping auto-restart.');
      _isListening = false;
      return;
    }

    // Cancel any existing restart timer
    _restartTimer?.cancel();

    // Increment retry count
    _retryCount++;
    
    // Calculate delay with exponential backoff (3s, 6s, 12s, 24s, 48s)
    final delaySeconds = _backoffSeconds * (1 << (_retryCount - 1)); // 2^(n-1)
    final cappedDelay = delaySeconds > 60 ? 60 : delaySeconds; // Max 60 seconds
    
    debugPrint('🔄 Restart attempt $_retryCount/$_maxRetries in ${cappedDelay}s...');

    // Wait before restarting
    _restartTimer = Timer(Duration(seconds: cappedDelay), () {
      if (_isListening && _speech.isAvailable) {
        debugPrint('🔄 Restarting voice recognition...');
        _startSpeechRecognition(_activeKeywords);
      }
    });
  }

  /// Trigger keyword detected callback
  static void _triggerKeywordDetected() {
    if (_onKeywordDetected != null) {
      _onKeywordDetected!();
    }
  }

  /// Stop listening for voice commands
  static Future<void> stopListening() async {
    if (!_isListening) {
      return;
    }

    _isListening = false;
    _onKeywordDetected = null;
    _restartTimer?.cancel();
    _restartTimer = null;

    await _speech.stop();
    debugPrint('🔇 Stopped listening for voice commands');
  }

  /// Pause listening (temporarily)
  static Future<void> pauseListening() async {
    if (!_isListening) {
      return;
    }

    await _speech.stop();
    debugPrint('⏸️ Paused voice recognition');
  }

  /// Resume listening
  static void resumeListening() {
    if (!_isListening) {
      return;
    }

    _startSpeechRecognition(_activeKeywords);
    debugPrint('▶️ Resumed voice recognition');
  }

  /// Reset retry count and restart listening (for manual restart)
  static void resetAndRestart() {
    _retryCount = 0;
    _isListening = true;
    debugPrint('🔄 Manual restart: retry count reset');
    _startSpeechRecognition(_activeKeywords);
  }

  /// Check if currently listening
  static bool get isListening => _isListening;

  /// Check if initialized
  static bool get isInitialized => _isInitialized;

  /// Get available locales
  static Future<List<stt.LocaleName>> getAvailableLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speech.locales();
  }

  /// Set language for recognition
  static Future<void> setLanguage(String localeId) async {
    // This will be used in the next listen() call
    debugPrint('🌐 Voice recognition language set to: $localeId');
  }

  /// Dispose resources
  static Future<void> dispose() async {
    await stopListening();
    _isInitialized = false;
    _restartTimer?.cancel();
  }

  /// Test voice activation (for debugging)
  static void testKeywordDetection(String testWord) {
    debugPrint('🧪 Testing keyword detection with: "$testWord"');
    for (final keyword in _activeKeywords) {
      if (_containsKeyword(testWord, keyword)) {
        debugPrint('✅ Keyword "$keyword" would be detected!');
        _triggerKeywordDetected();
        return;
      }
    }
    debugPrint('❌ No keyword detected in: "$testWord"');
  }

  static bool _containsKeyword(String spokenWords, String keyword) {
    final normalizedWords = spokenWords.toLowerCase().trim();
    final normalizedKeyword = keyword.toLowerCase().trim();

    if (normalizedKeyword.isEmpty || normalizedWords.isEmpty) {
      return false;
    }

    if (normalizedKeyword.contains(' ')) {
      return normalizedWords.contains(normalizedKeyword);
    }

    final pattern = RegExp('(^|\\s)${RegExp.escape(normalizedKeyword)}(\\s|\$)');
    return pattern.hasMatch(normalizedWords);
  }
}

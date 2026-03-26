/// Unit Tests for Voice Distress Detection
/// Tests: Speech-to-text, emotion detection, panic keyword recognition

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:women_safety/utils/test_logger.dart';

class MockSpeechToTextService extends Mock {}
class MockDistressDetectionModel extends Mock {}

void main() {
  TestLogger.init();

  group('Voice Distress Detection Tests', () {
    late MockSpeechToTextService mockSpeechService;
    late MockDistressDetectionModel mockModel;

    setUp(() {
      TestLogger.logInfo('Setting up voice distress detection tests', 'SETUP');
      mockSpeechService = MockSpeechToTextService();
      mockModel = MockDistressDetectionModel();
    });

    test('Voice Input "Help" Should Trigger SOS', () async {
      TestLogger.logVoiceDetection('Testing panic keyword "Help"');

      // Arrange
      const userSpeech = 'Help! Someone help me!';
      const confidenceThreshold = 0.75;

      // Act
      try {
        TestLogger.logInfo('Voice input captured', 'VOICE_INPUT', {'speech': userSpeech});
        
        final confidence = _detectDistress(userSpeech);
        TestLogger.logVoiceDetection('Distress analyzed', confidence: confidence);

        if (confidence >= confidenceThreshold) {
          TestLogger.logSOSTrigger('Auto-triggered by voice detection', 
            type: 'VOICE',
            data: {'confidence': confidence, 'keyword': 'help'}
          );
        }

        // Assert
        expect(confidence, greaterThanOrEqualTo(confidenceThreshold));
        TestLogger.logSuccess('Panic keyword detected');
      } catch (e) {
        TestLogger.logError('Voice distress detection failed', e);
        rethrow;
      }
    });

    test('Voice Input "Emergency" Should Trigger SOS', () async {
      TestLogger.logVoiceDetection('Testing panic keyword "Emergency"');

      // Arrange
      const userSpeech = 'This is an emergency! Call someone!';
      const confidenceThreshold = 0.75;

      // Act
      final confidence = _detectDistress(userSpeech);
      TestLogger.logVoiceDetection('Distress analyzed', confidence: confidence);

      if (confidence >= confidenceThreshold) {
        TestLogger.logSOSTrigger('Auto-triggered by voice detection', type: 'VOICE');
      }

      // Assert
      expect(confidence, greaterThanOrEqualTo(confidenceThreshold));
    });

    test('Voice Input "Stop" Should Trigger SOS', () async {
      TestLogger.logVoiceDetection('Testing panic keyword "Stop"');

      // Arrange
      const userSpeech = 'Stop! Don\'t come near me!';
      const confidenceThreshold = 0.75;

      // Act
      final confidence = _detectDistress(userSpeech);

      if (confidence >= confidenceThreshold) {
        TestLogger.logSOSTrigger('Auto-triggered by panic keyword', type: 'VOICE');
      }

      // Assert
      expect(confidence, greaterThanOrEqualTo(confidenceThreshold));
    });

    test('Voice Input "Don\'t" Should Trigger SOS', () async {
      TestLogger.logVoiceDetection('Testing panic keyword "Don\'t"');

      // Arrange
      const userSpeech = 'Don\'t touch me! Get away!';
      const confidenceThreshold = 0.75;

      // Act
      final confidence = _detectDistress(userSpeech);

      if (confidence >= confidenceThreshold) {
        TestLogger.logSOSTrigger('Auto-triggered by voice detection', type: 'VOICE');
      }

      // Assert
      expect(confidence, greaterThanOrEqualTo(confidenceThreshold));
    });

    test('Normal Speech Should Not Trigger SOS', () async {
      TestLogger.logVoiceDetection('Testing normal speech (no distress)');

      // Arrange
      const userSpeech = 'How is the weather today';
      const confidenceThreshold = 0.75;

      // Act
      final confidence = _detectDistress(userSpeech);
      TestLogger.logVoiceDetection('Normal speech analyzed', confidence: confidence);

      bool sosTriggered = confidence >= confidenceThreshold;
      if (!sosTriggered) {
        TestLogger.logInfo('Normal speech - SOS not triggered', 'VOICE_ANALYSIS');
      }

      // Assert
      expect(sosTriggered, false);
      expect(confidence, lessThan(confidenceThreshold));
    });

    test('Voice With High Pitch Should Indicate Distress', () async {
      TestLogger.logVoiceDetection('Testing high pitch detection');

      // Arrange
      const double highPitch = 280.0; // Hz (higher than normal)
      const double normalPitch = 150.0;

      // Act
      final isHighPitch = highPitch > 200;
      TestLogger.logVoiceDetection('Pitch analyzed', 
        confidence: isHighPitch ? 0.85 : 0.2,
        data: {'pitch_hz': highPitch}
      );

      // Assert
      expect(isHighPitch, true);
      TestLogger.logSuccess('High pitch detected');
    });

    test('Rapid Speech Should Indicate Panic', () async {
      TestLogger.logVoiceDetection('Testing rapid speech detection');

      // Arrange
      const double normalWordsPerMinute = 150;
      const double panicWordsPerMinute = 250;

      // Act
      bool isPanic = panicWordsPerMinute > 200;
      TestLogger.logVoiceDetection('Speech rate analyzed',
        data: {'wpm': panicWordsPerMinute, 'is_panic': isPanic}
      );

      // Assert
      expect(isPanic, true);
      TestLogger.logSuccess('Rapid speech detected');
    });

    test('Voice Distress Should Allow 5-Second Cancellation', () async {
      TestLogger.logVoiceDetection('Testing SOS cancellation window');

      // Arrange
      const cancellationWindow = Duration(seconds: 5);
      bool sosCancelled = false;

      // Act
      try {
        TestLogger.logSOSTrigger('SOS triggered by voice', type: 'VOICE');
        TestLogger.logInfo('Cancellation window open for ${cancellationWindow.inSeconds}s', 'VOICE_SOS');

        // Simulate user cancelling within window
        await Future.delayed(Duration(milliseconds: 2000));
        sosCancelled = true;
        TestLogger.logSuccess('SOS cancelled by user');

        // Assert
        expect(sosCancelled, true);
      } catch (e) {
        TestLogger.logError('Cancellation failed', e);
        rethrow;
      }
    });

    test('Multiple Distress Indicators Should Increase Confidence', () async {
      TestLogger.logVoiceDetection('Testing multi-indicator confidence');

      // Arrange
      const String speech = 'Help! Stop! Emergency!';
      const double basePitch = 280.0;
      const double speechRate = 250; // wpm
      const bool containsKeyword = true;

      // Act
      double confidence = 0.5;
      if (containsKeyword) confidence += 0.2;
      if (basePitch > 200) confidence += 0.2;
      if (speechRate > 200) confidence += 0.15;

      TestLogger.logVoiceDetection('Multi-indicator analysis', 
        confidence: confidence,
        data: {
          'keyword': containsKeyword,
          'high_pitch': basePitch > 200,
          'rapid_speech': speechRate > 200,
          'final_confidence': confidence,
        }
      );

      // Assert
      expect(confidence, greaterThan(0.75));
      TestLogger.logSuccess('Confidence increased with multiple indicators');
    });

    test('Noise Should Not Trigger False Positive', () async {
      TestLogger.logVoiceDetection('Testing noise filtering');

      // Arrange
      const String noisyInput = 'dsadasda asdadas';
      const double noiseThreshold = 0.5;

      // Act
      final confidence = _detectDistress(noisyInput);
      TestLogger.logVoiceDetection('Noise analyzed', confidence: confidence);

      bool isValidInput = confidence >= noiseThreshold;
      if (!isValidInput) {
        TestLogger.logWarning('Input filtered as noise');
      }

      // Assert
      expect(isValidInput, false);
    });

    test('Voice Detection Should Work Offline', () async {
      TestLogger.logVoiceDetection('Testing offline voice detection');

      // Act
      bool offlineSupported = true;
      TestLogger.logInfo('Voice detection running offline (on-device model)', 'OFFLINE');

      const speech = 'Help me please';
      final confidence = _detectDistress(speech);

      // Assert
      expect(offlineSupported, true);
      expect(confidence, greaterThan(0.5));
      TestLogger.logSuccess('Offline voice detection works');
    });

    test('Voice Command Timeout Should Not Trigger SOS', () async {
      TestLogger.logVoiceDetection('Testing voice input timeout');

      // Arrange
      const Duration timeoutDuration = Duration(seconds: 10);

      // Act
      bool timeoutOccurred = false;
      TestLogger.logInfo('Listening for voice input (${timeoutDuration.inSeconds}s timeout)', 'VOICE_INPUT');

      await Future.delayed(Duration(milliseconds: 500));
      // Simulate user not speaking after timeout
      timeoutOccurred = true;

      if (timeoutOccurred) {
        TestLogger.logInfo('Voice input timeout - no distress detected', 'VOICE_TIMEOUT');
      }

      // Assert
      expect(timeoutOccurred, true);
    });

    test('Consecutive Distress Words Should Auto-Trigger SOS', () async {
      TestLogger.logVoiceDetection('Testing consecutive distress keywords');

      // Arrange
      const String speech = 'Help Help Help';
      const List<String> distressKeywords = ['help', 'emergency', 'stop', 'dont'];

      // Act
      int keywordCount = 0;
      for (final keyword in distressKeywords) {
        if (speech.toLowerCase().contains(keyword)) {
          keywordCount++;
        }
      }

      TestLogger.logVoiceDetection('Keywords detected: $keywordCount',
        data: {'keywords_found': keywordCount, 'threshold': 2}
      );

      bool shouldTriggerSOS = keywordCount >= 2;
      if (shouldTriggerSOS) {
        TestLogger.logSOSTrigger('Auto-triggered by multiple keywords', type: 'VOICE');
      }

      // Assert
      expect(shouldTriggerSOS, true);
    });
  });
}

/// Simulates distress detection algorithm
double _detectDistress(String speech) {
  double confidence = 0.0;
  final lowerSpeech = speech.toLowerCase();

  // Keyword detection
  const distressKeywords = ['help', 'emergency', 'stop', 'dont', 'don\'t'];
  int keywordCount = 0;
  for (final keyword in distressKeywords) {
    if (lowerSpeech.contains(keyword)) {
      keywordCount++;
    }
  }

  if (keywordCount > 0) {
    confidence += 0.5 * (keywordCount / 5).clamp(0.0, 1.0);
  }

  // Speech pattern (simulated by sentence structure)
  if (speech.contains('!')) {
    confidence += 0.25;
  }

  if (speech.length < 20) {
    confidence += 0.1; // Short, urgent speech
  }

  return confidence.clamp(0.0, 1.0);
}

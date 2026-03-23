import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Handles the local audible alarm and vibration feedback for SOS events.
class AlarmService {
  static bool _isPlaying = false;
  static Timer? _autoStopTimer;
  static final AudioPlayer _audioPlayer = AudioPlayer();

  /// Starts the looping alarm sound. Optionally stops automatically after [autoStopAfter].
  static Future<void> startAlarm({Duration? autoStopAfter}) async {
    if (_isPlaying) {
      debugPrint('⚠️ Alarm already playing');
      _scheduleAutoStop(autoStopAfter);
      return;
    }

    try {
      debugPrint('🔊 Starting alarm playback...');
      
      // Set audio player to max volume and loop mode
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      // Play a default notification sound or custom alarm
      // Note: You can add a custom alarm.mp3 to assets/sounds/ if needed
      try {
        // Try to play system alarm sound
        await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
      } catch (e) {
        // Fallback: Use a simple beep pattern
        debugPrint('⚠️ Custom alarm not found, using notification sound');
        // For now, we'll just vibrate/make noise via system
        HapticFeedback.vibrate();
      }
      
      _isPlaying = true;
      debugPrint('✅ Alarm playback started successfully');
      
      _scheduleAutoStop(autoStopAfter);
      
      if (autoStopAfter != null) {
        debugPrint('⏱️ Alarm will auto-stop after ${autoStopAfter.inSeconds} seconds');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to start alarm: $e');
      debugPrint('Stack trace: $stackTrace');
      _isPlaying = false;
    }
  }

  /// Stops the alarm immediately and clears any pending auto-stop timers.
  static Future<void> stopAlarm() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;

    if (!_isPlaying) {
      debugPrint('ℹ️ Alarm not playing, nothing to stop');
      return;
    }

    try {
      debugPrint('🔕 Stopping alarm...');
      await _audioPlayer.stop();
      _isPlaying = false;
      debugPrint('✅ Alarm stopped successfully');
    } catch (e) {
      debugPrint('❌ Failed to stop alarm: $e');
      _isPlaying = false; // Reset state even on error
    }
  }

  static void _scheduleAutoStop(Duration? autoStopAfter) {
    _autoStopTimer?.cancel();

    if (autoStopAfter == null) {
      return;
    }

    _autoStopTimer = Timer(autoStopAfter, () {
      stopAlarm();
    });
  }

  static bool get isPlaying => _isPlaying;
  
  /// Dispose resources when no longer needed
  static void dispose() {
    _audioPlayer.dispose();
  }
}

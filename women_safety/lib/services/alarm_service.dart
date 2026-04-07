import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Handles the local audible alarm and vibration feedback for SOS events.
class AlarmService {
  static bool _isPlaying = false;
  static Timer? _autoStopTimer;
  static Timer? _fallbackPulseTimer;
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
      
      // Play custom alarm if available.
      try {
        await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
        _stopFallbackPattern();
      } catch (e) {
        debugPrint('⚠️ Custom alarm missing/unavailable, switching to fallback siren pattern');
        _startFallbackPattern();
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
    _stopFallbackPattern();

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

  static void _startFallbackPattern() {
    _fallbackPulseTimer?.cancel();
    _fallbackPulseTimer = Timer.periodic(const Duration(milliseconds: 1100), (
      timer,
    ) async {
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {
        // Best-effort fallback on platforms where SystemSound alert is unsupported.
      }
      HapticFeedback.heavyImpact();
    });
    HapticFeedback.heavyImpact();
  }

  static void _stopFallbackPattern() {
    _fallbackPulseTimer?.cancel();
    _fallbackPulseTimer = null;
  }
  
  /// Dispose resources when no longer needed
  static void dispose() {
    _stopFallbackPattern();
    _audioPlayer.dispose();
  }
}

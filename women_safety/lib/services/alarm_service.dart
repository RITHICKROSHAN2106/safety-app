import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Handles the local audible alarm and vibration feedback for SOS events.
class AlarmService {
  static bool _isPlaying = false;
  static Timer? _autoStopTimer;
  static Timer? _fallbackPulseTimer;
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static Uint8List? _generatedSirenWav;

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
        debugPrint('⚠️ Custom alarm missing/unavailable, using generated siren tone');
        _generatedSirenWav ??= _buildSirenWaveBytes();
        await _audioPlayer.play(BytesSource(_generatedSirenWav!));
        // Keep haptic pulse alongside generated tone so users feel the alert too.
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

  static Uint8List _buildSirenWaveBytes() {
    const sampleRate = 44100;
    const seconds = 2;
    const amplitude = 0.9;
    final totalSamples = sampleRate * seconds;
    final dataSize = totalSamples * 2;
    final byteData = ByteData(44 + dataSize);

    void writeAscii(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        byteData.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    // WAV header (PCM, mono, 16-bit)
    writeAscii(0, 'RIFF');
    byteData.setUint32(4, 36 + dataSize, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);
    byteData.setUint16(22, 1, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);
    writeAscii(36, 'data');
    byteData.setUint32(40, dataSize, Endian.little);

    for (var i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final sweep = 520 + (560 * ((math.sin(2 * math.pi * 0.7 * t) + 1) / 2));
      final sample = (math.sin(2 * math.pi * sweep * t) * 32767 * amplitude)
          .clamp(-32768, 32767)
          .toInt();
      byteData.setInt16(44 + (i * 2), sample, Endian.little);
    }

    return byteData.buffer.asUint8List();
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

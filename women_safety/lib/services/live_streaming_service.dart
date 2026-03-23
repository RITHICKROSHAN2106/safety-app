import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

import 'config.dart';

/// 📹 Live Streaming Service - Stream video to guardians in real-time
class LiveStreamingService {
  static RtcEngine? _engine;
  static bool _isStreaming = false;
  static String? _currentChannelId;
  static final List<int> _remoteUids = [];
  
  // Agora credentials (set via --dart-define)
  static String get _appId => Config.agoraAppId;
  
  /// Check if streaming is active
  static bool get isStreaming => _isStreaming;
  
  /// Get current channel ID
  static String? get currentChannelId => _currentChannelId;
  
  /// Get connected viewers
  static List<int> get connectedViewers => List.from(_remoteUids);

  /// Initialize Agora engine
  static Future<bool> initialize() async {
    try {
      if (!Config.isLiveStreamingEnabled) {
        debugPrint('⚠️ Live streaming disabled or not configured');
        return false;
      }

      // Check permissions
      final cameraStatus = await Permission.camera.request();
      final micStatus = await Permission.microphone.request();
      
      if (!cameraStatus.isGranted || !micStatus.isGranted) {
        debugPrint('❌ Camera/Microphone permission denied');
        return false;
      }

      // Create Agora engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: _appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      // Setup event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('✅ Joined channel: ${connection.channelId}');
            _isStreaming = true;
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('👤 Guardian joined stream: $remoteUid');
            _remoteUids.add(remoteUid);
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            debugPrint('👋 Guardian left stream: $remoteUid');
            _remoteUids.remove(remoteUid);
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint('❌ Streaming error: $msg');
          },
        ),
      );

      // Enable video
      await _engine!.enableVideo();
      await _engine!.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 640, height: 480),
          frameRate: 15,
          bitrate: standardBitrate,
        ),
      );

      debugPrint('✅ Live streaming initialized');
      return true;
    } catch (e) {
      debugPrint('❌ Live streaming initialization error: $e');
      return false;
    }
  }

  /// Start live streaming during SOS
  static Future<String?> startStreaming({
    required String userId,
    String? customChannelId,
  }) async {
    if (_isStreaming) {
      debugPrint('⚠️ Already streaming');
      return _currentChannelId;
    }

    try {
      if (_engine == null) {
        await initialize();
      }

      // Generate unique channel ID
      _currentChannelId = customChannelId ?? 'sos_${userId}_${DateTime.now().millisecondsSinceEpoch}';

      // Keep screen on during streaming
      await WakelockPlus.enable();

      // Set broadcaster role
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // Start preview
      await _engine!.startPreview();

      // Join channel (token should be generated from your server in production)
      await _engine!.joinChannel(
        token: Config.agoraTempToken, // Use token in production
        channelId: _currentChannelId!,
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      debugPrint('🎥 Live streaming started: $_currentChannelId');
      debugPrint('🔗 Share this channel ID with guardians: $_currentChannelId');
      
      return _currentChannelId;
    } catch (e) {
      debugPrint('❌ Start streaming error: $e');
      return null;
    }
  }

  /// Stop live streaming
  static Future<void> stopStreaming() async {
    if (!_isStreaming) {
      debugPrint('⚠️ Not streaming');
      return;
    }

    try {
      await _engine?.leaveChannel();
      await _engine?.stopPreview();
      await WakelockPlus.disable();
      
      _isStreaming = false;
      _currentChannelId = null;
      _remoteUids.clear();
      
      debugPrint('✅ Live streaming stopped');
    } catch (e) {
      debugPrint('❌ Stop streaming error: $e');
    }
  }

  /// Join stream as viewer (for guardians)
  static Future<bool> joinStreamAsViewer({
    required String channelId,
  }) async {
    try {
      if (_engine == null) {
        await initialize();
      }

      // Set audience role
      await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);

      // Join channel
      await _engine!.joinChannel(
        token: Config.agoraTempToken, // Use token in production
        channelId: channelId,
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleAudience,
        ),
      );

      _currentChannelId = channelId;
      
      debugPrint('👁️ Joined stream as viewer: $channelId');
      return true;
    } catch (e) {
      debugPrint('❌ Join stream error: $e');
      return false;
    }
  }

  /// Toggle camera (front/back)
  static Future<void> switchCamera() async {
    try {
      await _engine?.switchCamera();
      debugPrint('🔄 Camera switched');
    } catch (e) {
      debugPrint('❌ Switch camera error: $e');
    }
  }

  /// Toggle microphone
  static Future<void> toggleMicrophone(bool enable) async {
    try {
      await _engine?.enableLocalAudio(enable);
      debugPrint('🎤 Microphone ${enable ? "enabled" : "muted"}');
    } catch (e) {
      debugPrint('❌ Toggle microphone error: $e');
    }
  }

  /// Toggle video
  static Future<void> toggleVideo(bool enable) async {
    try {
      await _engine?.enableLocalVideo(enable);
      debugPrint('📹 Video ${enable ? "enabled" : "disabled"}');
    } catch (e) {
      debugPrint('❌ Toggle video error: $e');
    }
  }

  /// Get stream statistics
  static Future<Map<String, dynamic>> getStreamStats() async {
    return {
      'isStreaming': _isStreaming,
      'channelId': _currentChannelId,
      'viewerCount': _remoteUids.length,
      'viewers': _remoteUids,
    };
  }

  /// Dispose engine
  static Future<void> dispose() async {
    try {
      await stopStreaming();
      await _engine?.release();
      _engine = null;
      debugPrint('✅ Live streaming disposed');
    } catch (e) {
      debugPrint('❌ Dispose error: $e');
    }
  }

  /// Generate stream URL for sharing
  static String generateStreamUrl(String channelId) {
    // In production, this should be a deep link to your app
    return 'womensafety://stream/$channelId';
  }

  /// Record stream to cloud storage
  static Future<bool> startRecording() async {
    try {
      // In production, use Agora Cloud Recording API
      // This is a placeholder
      debugPrint('🔴 Stream recording started');
      return true;
    } catch (e) {
      debugPrint('❌ Start recording error: $e');
      return false;
    }
  }

  /// Stop recording
  static Future<void> stopRecording() async {
    try {
      // In production, stop Agora Cloud Recording
      debugPrint('⏹️ Stream recording stopped');
    } catch (e) {
      debugPrint('❌ Stop recording error: $e');
    }
  }
}

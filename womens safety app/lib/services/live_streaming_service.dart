/// Live Streaming Service
/// Agora integration stub for emergency live video streaming
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

class LiveStreamingService {
  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _isStreaming = false;

  // Agora App ID (placeholder - add your own)
  static const String _appId = 'YOUR_AGORA_APP_ID';

  bool get isStreaming => _isStreaming;
  bool get isInitialized => _isInitialized;

  // Initialize Agora engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Create Agora engine
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: _appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      // Set up event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint('Joined channel: ${connection.channelId}');
            _isStreaming = true;
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint('Remote user joined: $remoteUid');
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            debugPrint('Remote user offline: $remoteUid');
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            debugPrint('Left channel');
            _isStreaming = false;
          },
        ),
      );

      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await _engine!.enableVideo();

      _isInitialized = true;
      debugPrint('Agora initialized successfully');
    } catch (e) {
      debugPrint('Agora initialization failed: $e');
      throw Exception('Failed to initialize streaming: $e');
    }
  }

  // Start live stream
  Future<StreamSession> startStream({
    required String userId,
    required String userName,
    String? customChannelId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Generate unique channel ID
      String channelId = customChannelId ??
          'sos_${userId}_${DateTime.now().millisecondsSinceEpoch}';

      // Join channel
      await _engine!.joinChannel(
        token: '', // Token should be generated from your server
        channelId: channelId,
        uid: 0, // 0 means auto-assign
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      return StreamSession(
        channelId: channelId,
        streamerId: userId,
        streamerName: userName,
        startTime: DateTime.now(),
        viewerCount: 0,
      );
    } catch (e) {
      throw Exception('Failed to start stream: $e');
    }
  }

  // Stop live stream
  Future<void> stopStream() async {
    if (!_isStreaming) return;

    try {
      await _engine?.leaveChannel();
      _isStreaming = false;
      debugPrint('Stream stopped');
    } catch (e) {
      debugPrint('Failed to stop stream: $e');
    }
  }

  // Switch camera
  Future<void> switchCamera() async {
    if (_engine != null) {
      await _engine!.switchCamera();
    }
  }

  // Mute/unmute audio
  Future<void> muteAudio(bool mute) async {
    if (_engine != null) {
      await _engine!.muteLocalAudioStream(mute);
    }
  }

  // Enable/disable video
  Future<void> enableVideo(bool enable) async {
    if (_engine != null) {
      if (enable) {
        await _engine!.enableVideo();
      } else {
        await _engine!.disableVideo();
      }
    }
  }

  // Get streaming statistics
  Future<StreamStats> getStreamStats() async {
    // TODO: Implement actual stats retrieval
    return StreamStats(
      duration: _isStreaming
          ? const Duration(minutes: 5)
          : const Duration(seconds: 0),
      bitrate: 1200,
      frameRate: 30,
      resolution: '1280x720',
    );
  }

  // Share stream link with guardians
  String generateStreamLink(String channelId) {
    // Generate a web link for guardians to view the stream
    // This would typically point to your web app
    return 'https://yourapp.com/watch/$channelId';
  }

  // Dispose resources
  Future<void> dispose() async {
    if (_isStreaming) {
      await stopStream();
    }
    await _engine?.release();
    _isInitialized = false;
  }
}

// Stream session model
class StreamSession {
  final String channelId;
  final String streamerId;
  final String streamerName;
  final DateTime startTime;
  final int viewerCount;

  StreamSession({
    required this.channelId,
    required this.streamerId,
    required this.streamerName,
    required this.startTime,
    required this.viewerCount,
  });

  String get shareableLink {
    return 'Emergency Live Stream\n'
        'Streamer: $streamerName\n'
        'Join: https://yourapp.com/watch/$channelId\n'
        'Started: ${startTime.toLocal()}';
  }
}

// Stream statistics model
class StreamStats {
  final Duration duration;
  final int bitrate;
  final int frameRate;
  final String resolution;

  StreamStats({
    required this.duration,
    required this.bitrate,
    required this.frameRate,
    required this.resolution,
  });
}

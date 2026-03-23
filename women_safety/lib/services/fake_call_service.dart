import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

/// 🔐 Fake Call Service - Pretend incoming call to escape dangerous situations
class FakeCallService {
  static bool _isCallActive = false;
  static Timer? _ringTimer;
  static final AudioPlayer _audioPlayer = AudioPlayer();

  /// Check if fake call is currently active
  static bool get isCallActive => _isCallActive;

  /// Trigger a fake incoming call with customizable caller
  static Future<void> triggerFakeCall({
    required BuildContext context,
    String callerName = 'Mom',
    String callerNumber = '+91 98765 43210',
    String? callerImage,
    Duration? autoAnswerAfter,
  }) async {
    if (_isCallActive) {
      debugPrint('⚠️ Fake call already active');
      return;
    }

    _isCallActive = true;

    try {
      // Start vibration pattern (ring pattern)
      await _startVibrationPattern();

      // Play ringtone
      await _playRingtone();

      // Show fake call screen
      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FakeCallScreen(
              callerName: callerName,
              callerNumber: callerNumber,
              callerImage: callerImage,
              autoAnswerAfter: autoAnswerAfter,
            ),
            fullscreenDialog: true,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Fake call error: $e');
    } finally {
      await stopFakeCall();
    }
  }

  /// Start vibration pattern (ring pattern)
  static Future<void> _startVibrationPattern() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (!hasVibrator) return;

    // Ring pattern: vibrate for 1s, pause 0.5s, repeat
    _ringTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
      await Vibration.vibrate(duration: 1000);
    });
  }

  /// Play ringtone sound
  static Future<void> _playRingtone() async {
    try {
      // Use system notification sound
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(0.8);
      // You can add custom ringtone here
      // await _audioPlayer.play(AssetSource('sounds/ringtone.mp3'));
    } catch (e) {
      debugPrint('❌ Ringtone play error: $e');
    }
  }

  /// Stop fake call (stop vibration and ringtone)
  static Future<void> stopFakeCall() async {
    _isCallActive = false;
    _ringTimer?.cancel();
    _ringTimer = null;
    await Vibration.cancel();
    await _audioPlayer.stop();
  }

  /// Schedule a fake call after a delay (discrete trigger)
  static Future<void> scheduleFakeCall({
    required Duration delay,
    required BuildContext context,
    String callerName = 'Mom',
  }) async {
    debugPrint('📅 Fake call scheduled in ${delay.inSeconds}s');
    await Future.delayed(delay);
    if (!context.mounted) {
      return;
    }
    await triggerFakeCall(context: context, callerName: callerName);
  }

  /// Quick trigger - Volume button long press (3+ seconds)
  static Future<void> triggerFromVolumeButton(BuildContext context) async {
    debugPrint('🔊 Fake call triggered from volume button!');
    await triggerFakeCall(
      context: context,
      callerName: 'Mom',
      callerNumber: 'Emergency Contact',
    );
  }

  /// Trigger from notification quick action
  static Future<void> triggerFromNotification(BuildContext context) async {
    debugPrint('🔔 Fake call triggered from notification!');
    await triggerFakeCall(
      context: context,
      callerName: 'Mom',
      callerNumber: 'Calling...',
      autoAnswerAfter: const Duration(seconds: 3),
    );
  }
}

/// 📱 Fake Call Screen UI
class FakeCallScreen extends StatefulWidget {
  final String callerName;
  final String callerNumber;
  final String? callerImage;
  final Duration? autoAnswerAfter;

  const FakeCallScreen({
    super.key,
    required this.callerName,
    required this.callerNumber,
    this.callerImage,
    this.autoAnswerAfter,
  });

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isAnswered = false;
  Timer? _autoAnswerTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Auto-answer if duration specified
    if (widget.autoAnswerAfter != null) {
      _autoAnswerTimer = Timer(widget.autoAnswerAfter!, () {
        if (mounted && !_isAnswered) {
          _answerCall();
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _autoAnswerTimer?.cancel();
    super.dispose();
  }

  void _answerCall() {
    setState(() {
      _isAnswered = true;
    });
    FakeCallService.stopFakeCall();

    // Show "in call" screen for a few seconds, then close
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _rejectCall() {
    FakeCallService.stopFakeCall();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isAnswered ? _buildInCallScreen() : _buildIncomingCallScreen(),
      ),
    );
  }

  Widget _buildIncomingCallScreen() {
    return Column(
      children: [
        const SizedBox(height: 60),
        
        // Incoming call text
        const Text(
          'Incoming Call',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w300,
          ),
        ),
        
        const SizedBox(height: 40),
        
        // Caller image
        FadeTransition(
          opacity: _animationController,
          child: CircleAvatar(
            radius: 70,
            backgroundColor: Colors.grey[800],
            backgroundImage: widget.callerImage != null
                ? NetworkImage(widget.callerImage!)
                : null,
            child: widget.callerImage == null
                ? const Icon(Icons.person, size: 70, color: Colors.white54)
                : null,
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Caller name
        Text(
          widget.callerName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Caller number
        Text(
          widget.callerNumber,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.w300,
          ),
        ),
        
        const Spacer(),
        
        // Answer/Reject buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Reject button
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'reject',
                    onPressed: _rejectCall,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.call_end, size: 30),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Decline',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              
              // Answer button
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'answer',
                    onPressed: _answerCall,
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.call, size: 30),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Accept',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInCallScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Caller image
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[800],
          backgroundImage: widget.callerImage != null
              ? NetworkImage(widget.callerImage!)
              : null,
          child: widget.callerImage == null
              ? const Icon(Icons.person, size: 60, color: Colors.white54)
              : null,
        ),
        
        const SizedBox(height: 30),
        
        // Caller name
        Text(
          widget.callerName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Call duration
        const Text(
          '00:05',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
          ),
        ),
        
        const SizedBox(height: 60),
        
        // End call button
        FloatingActionButton(
          onPressed: _rejectCall,
          backgroundColor: Colors.red,
          child: const Icon(Icons.call_end, size: 30),
        ),
      ],
    );
  }
}

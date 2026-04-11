import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/auth/auth_cubit.dart';
import '../models/guardian.dart';
import '../services/fake_call_service.dart';
import '../services/alarm_service.dart';
import '../services/panic_widget_service.dart';
import '../services/live_streaming_service.dart';
import '../services/ride_tracking_service.dart';
import '../services/safety_check_in_service.dart';
import '../services/guardian_network_service.dart';
import '../services/face_recognition_service.dart';
import '../services/distress_voice_analysis_service.dart';
import '../services/ai_danger_prediction_service.dart';
import '../services/config.dart';
import '../services/sos_service.dart';
import '../repositories/guardian_repository.dart';
import 'gemini_assistant_screen.dart';

/// Revolutionary Features Hub - Access all 8 advanced safety features
class RevolutionaryFeaturesScreen extends StatelessWidget {
  const RevolutionaryFeaturesScreen({super.key});
  static const routeName = '/revolutionary-features';

  @override
  Widget build(BuildContext context) {
    final liveStreamingEnabled = Config.isLiveStreamingEnabled;
    final guardianNetworkEnabled = Config.isGuardianNetworkEnabled;
    final faceRecognitionEnabled = Config.isFaceRecognitionEnabled;
    final voiceDistressEnabled = Config.isVoiceDistressEnabled;
    final aiDangerEnabled = Config.isAIDangerPredictionEnabled;
    final liveStreamingDisabledReason = Config.liveStreamingDisabledReason;
    final guardianNetworkDisabledReason = Config.guardianNetworkDisabledReason;
    final faceRecognitionDisabledReason = Config.faceRecognitionDisabledReason;
    final voiceDistressDisabledReason = Config.voiceDistressDisabledReason;
    final aiDangerDisabledReason = Config.aiDangerDisabledReason;
    final geminiAssistantEnabled = Config.isGeminiAssistantEnabled;
    final geminiAssistantDisabledReason = Config.geminiAssistantDisabledReason;

    final readinessItems = <_FeatureReadiness>[
      _FeatureReadiness(title: 'Fake Call', isEnabled: true),
      _FeatureReadiness(title: 'Safety Check-In Timer', isEnabled: true),
      _FeatureReadiness(title: 'Siren Workflow', isEnabled: true),
      _FeatureReadiness(title: 'Panic Widget', isEnabled: true),
      _FeatureReadiness(
        title: 'Live Streaming',
        isEnabled: liveStreamingEnabled,
        disabledReason: liveStreamingDisabledReason,
      ),
      _FeatureReadiness(title: 'Ride Tracking', isEnabled: true),
      _FeatureReadiness(
        title: 'Guardian Network',
        isEnabled: guardianNetworkEnabled,
        disabledReason: guardianNetworkDisabledReason,
      ),
      _FeatureReadiness(
        title: 'Face Recognition',
        isEnabled: faceRecognitionEnabled,
        disabledReason: faceRecognitionDisabledReason,
      ),
      _FeatureReadiness(
        title: 'Voice Distress Analysis',
        isEnabled: voiceDistressEnabled,
        disabledReason: voiceDistressDisabledReason,
      ),
      _FeatureReadiness(
        title: 'ML Danger Prediction',
        isEnabled: aiDangerEnabled,
        disabledReason: aiDangerDisabledReason,
      ),
      _FeatureReadiness(
        title: 'Gemini Safety Assistant',
        isEnabled: geminiAssistantEnabled,
        disabledReason: geminiAssistantDisabledReason,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Safety Features'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Text(
            'Advanced Safety Features',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${readinessItems.length} AI-powered safety workflows to keep you safer',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          _RevolutionaryReadinessBanner(items: readinessItems),
          const SizedBox(height: 24),

          // Feature 1: Fake Call
          _ClassicFeatureCard(
            icon: Icons.phone_callback,
            title: 'Fake Call',
            description:
                'Escape dangerous situations with fake call + siren fallback workflow',
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FakeCallScreen()),
            ),
          ),
          const SizedBox(height: 12),

          _ClassicFeatureCard(
            icon: Icons.timer,
            title: 'Safety Check-In Timer',
            description:
                'Periodic I\'m safe confirmation with auto SOS escalation',
            color: Colors.amber,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SafetyCheckInScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // Feature 2: Panic Widget
          _ClassicFeatureCard(
            icon: Icons.widgets,
            title: 'Panic Widget',
            description: 'One-tap SOS from home screen without unlocking',
            color: Colors.red,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PanicWidgetSetupScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // Feature 3: Live Streaming
          _ClassicFeatureCard(
            icon: Icons.videocam,
            title: 'Live Streaming',
            description: 'Stream live video to guardians during emergency',
            color: Colors.purple,
            isEnabled: liveStreamingEnabled,
            disabledReason: liveStreamingDisabledReason,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LiveStreamingScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // Feature 4: Ride Tracking
          _ClassicFeatureCard(
            icon: Icons.local_taxi,
            title: 'Ride Tracking',
            description: 'Track Uber/Ola rides with route deviation alerts',
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RideTrackingScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // Feature 5: Guardian Network
          _ClassicFeatureCard(
            icon: Icons.people,
            title: 'Guardian Network',
            description: 'Connect with nearby volunteer guardians',
            color: Colors.green,
            isEnabled: guardianNetworkEnabled,
            disabledReason: guardianNetworkDisabledReason,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GuardianNetworkScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // Feature 6: Face Recognition
          _ClassicFeatureCard(
            icon: Icons.face,
            title: 'Face Recognition',
            description:
                'Verify trusted contacts with ML-powered face detection',
            color: Colors.teal,
            isEnabled: faceRecognitionEnabled,
            disabledReason: faceRecognitionDisabledReason,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FaceRecognitionScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // Feature 7: Voice Distress Analysis
          _ClassicFeatureCard(
            icon: Icons.mic,
            title: 'Voice Distress Analysis',
            description: 'Auto-detect distress in voice and trigger SOS',
            color: Colors.pink,
            isEnabled: voiceDistressEnabled,
            disabledReason: voiceDistressDisabledReason,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VoiceDistressScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // Feature 8: ML Danger Prediction
          _ClassicFeatureCard(
            icon: Icons.psychology,
            title: 'ML Danger Prediction',
            description: 'ML-powered danger zone detection and safe routes',
            color: Colors.deepOrange,
            isEnabled: aiDangerEnabled,
            disabledReason: aiDangerDisabledReason,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AIDangerMapScreen()),
            ),
          ),
          const SizedBox(height: 24),

          // Feature 9: Gemini Safety Assistant
          _ClassicFeatureCard(
            icon: Icons.auto_awesome,
            title: 'Gemini Safety Assistant',
            description:
                'Chat with Gemini for safety guidance, SOS triage, and planning',
            color: Colors.indigo,
            isEnabled: geminiAssistantEnabled,
            disabledReason: geminiAssistantDisabledReason,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GeminiAssistantScreen()),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _FeatureReadiness {
  final String title;
  final bool isEnabled;
  final String? disabledReason;

  const _FeatureReadiness({
    required this.title,
    required this.isEnabled,
    this.disabledReason,
  });
}

class _RevolutionaryReadinessBanner extends StatelessWidget {
  final List<_FeatureReadiness> items;

  const _RevolutionaryReadinessBanner({required this.items});

  @override
  Widget build(BuildContext context) {
    final enabledCount = items.where((item) => item.isEnabled).length;
    final disabledItems = items.where((item) => !item.isEnabled).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deployment Readiness: $enabledCount/${items.length} enabled',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.indigo.shade900,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (disabledItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...disabledItems
                .take(3)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '- ${item.title}: ${item.disabledReason ?? 'Enable required configuration'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ),
                ),
            if (disabledItems.length > 3)
              Text(
                '+${disabledItems.length - 3} more feature checks',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.indigo.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'All revolutionary features are configured for this build.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.indigo.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Simple classic feature card widget
class _ClassicFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final bool isEnabled;
  final String? disabledReason;

  const _ClassicFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    this.isEnabled = true,
    this.disabledReason,
  });

  @override
  Widget build(BuildContext context) {
    final cardOpacity = isEnabled ? 1.0 : 0.5;
    final borderColor = isEnabled ? Colors.grey.shade300 : Colors.grey.shade200;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: InkWell(
        onTap: () {
          if (isEnabled) {
            onTap();
            return;
          }

          final message = disabledReason ?? 'Coming soon';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1 * cardOpacity),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: color.withValues(alpha: 0.3 * cardOpacity),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color.withValues(alpha: cardOpacity),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (!isEnabled) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Coming soon',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400.withValues(alpha: cardOpacity),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// FEATURE 1: Fake Call Screen
class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  final _callerNameController = TextEditingController(text: 'Mom');
  final _callerNumberController = TextEditingController(
    text: '+91 98765 43210',
  );
  int _delaySeconds = 0;
  bool _autoAnswer = false;
  bool _sirenFallbackEnabled = true;

  @override
  void dispose() {
    _callerNameController.dispose();
    _callerNumberController.dispose();
    super.dispose();
  }

  Future<void> _triggerFakeCall() async {
    if (_delaySeconds > 0) {
      await FakeCallService.scheduleFakeCall(
        delay: Duration(seconds: _delaySeconds),
        context: context,
        callerName: _callerNameController.text,
        callerNumber: _callerNumberController.text,
        autoAnswerAfter: _autoAnswer ? const Duration(seconds: 5) : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fake call scheduled in $_delaySeconds seconds'),
        ),
      );
    } else {
      await FakeCallService.triggerFakeCall(
        context: context,
        callerName: _callerNameController.text,
        callerNumber: _callerNumberController.text,
        autoAnswerAfter: _autoAnswer ? const Duration(seconds: 5) : null,
      );
    }
  }

  Future<void> _startSiren() async {
    await AlarmService.startAlarm(autoStopAfter: const Duration(seconds: 45));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Siren started for 45 seconds')),
    );
  }

  Future<void> _stopSiren() async {
    await AlarmService.stopAlarm();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Siren stopped')));
  }

  Future<void> _runEscapeWorkflow() async {
    unawaited(
      FakeCallService.scheduleFakeCall(
        delay: Duration(seconds: _delaySeconds),
        context: context,
        callerName: _callerNameController.text,
        callerNumber: _callerNumberController.text,
        autoAnswerAfter: _autoAnswer ? const Duration(seconds: 5) : null,
      ),
    );

    if (_sirenFallbackEnabled) {
      Future.delayed(Duration(seconds: _delaySeconds + 8), () async {
        if (!mounted) return;
        await AlarmService.startAlarm(
          autoStopAfter: const Duration(seconds: 30),
        );
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _sirenFallbackEnabled
              ? 'Escape workflow armed: fake call + siren fallback'
              : 'Escape workflow armed: fake call only',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fake Call'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _InfoCard(
            icon: Icons.info_outline,
            text:
                'Simulate a realistic incoming call to escape dangerous situations safely.',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _callerNameController,
            decoration: const InputDecoration(
              labelText: 'Caller Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _callerNumberController,
            decoration: const InputDecoration(
              labelText: 'Caller Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          Text(
            'Delay: $_delaySeconds seconds',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: _delaySeconds.toDouble(),
            min: 0,
            max: 60,
            divisions: 12,
            label: '$_delaySeconds sec',
            onChanged: (value) => setState(() => _delaySeconds = value.toInt()),
          ),
          SwitchListTile(
            title: const Text('Auto-answer after 5 seconds'),
            value: _autoAnswer,
            onChanged: (value) => setState(() => _autoAnswer = value),
          ),
          SwitchListTile(
            title: const Text('Enable siren fallback'),
            subtitle: const Text(
              'Play 30s siren shortly after fake call starts',
            ),
            value: _sirenFallbackEnabled,
            onChanged: (value) => setState(() => _sirenFallbackEnabled = value),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _triggerFakeCall,
            icon: const Icon(Icons.phone_callback),
            label: Text(
              _delaySeconds > 0 ? 'Schedule Fake Call' : 'Trigger Now',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _runEscapeWorkflow,
            icon: const Icon(Icons.security),
            label: const Text('Run Escape Workflow'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.indigo,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _startSiren,
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Start Siren'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _stopSiren,
                  icon: const Icon(Icons.volume_off),
                  label: const Text('Stop Siren'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// FEATURE: Safety Check-In Timer Screen
class SafetyCheckInScreen extends StatefulWidget {
  const SafetyCheckInScreen({super.key});

  @override
  State<SafetyCheckInScreen> createState() => _SafetyCheckInScreenState();
}

class _SafetyCheckInScreenState extends State<SafetyCheckInScreen> {
  int _intervalMinutes = 10;
  int _graceSeconds = 45;
  CheckInState _state = SafetyCheckInService.currentState;
  StreamSubscription<CheckInState>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = SafetyCheckInService.updates.listen((state) {
      if (!mounted) return;
      setState(() => _state = state);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _startTimer() async {
    await SafetyCheckInService.start(
      interval: Duration(minutes: _intervalMinutes),
      gracePeriod: Duration(seconds: _graceSeconds),
      onMissedCheckIn: _handleMissedCheckIn,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Check-in timer started ($_intervalMinutes min interval)',
        ),
      ),
    );
  }

  Future<void> _handleMissedCheckIn() async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missed check-in detected, but no signed-in user was found.'),
        ),
      );
      return;
    }

    final guardians = await GuardianRepository().fetchGuardiansForUser(
      user.uid,
    );
    if (guardians.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Missed check-in detected, but no guardians are configured.',
          ),
        ),
      );
      return;
    }

    try {
      final alert = await SOSService.triggerSOS(
        user: user,
        emergencyContacts: guardians,
        triggerType: 'CHECKIN_MISSED',
        playAlarm: true,
        makeCall: true,
      );

      if (!mounted) return;
      if (alert != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Missed check-in: SOS escalation triggered successfully.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Missed check-in detected, but SOS trigger failed. Check permissions and contacts.'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missed check-in detected, but SOS escalation encountered an error.'),
        ),
      );
    }
  }

  String _formatSeconds(int value) {
    final minutes = value ~/ 60;
    final seconds = value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final title = _state.awaitingConfirmation
        ? 'Waiting for confirmation'
        : (_state.isActive ? 'Monitoring active' : 'Timer stopped');
    final body = _state.awaitingConfirmation
        ? 'Tap I\'m Safe within ${_formatSeconds(_state.graceRemainingSeconds)}'
        : (_state.isActive
              ? 'Next check-in in ${_formatSeconds(_state.remainingSeconds)}'
              : 'Start timer to enforce periodic safety confirmation');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Check-In Timer'),
        backgroundColor: Colors.amber.shade700,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _InfoCard(
            icon: Icons.timer,
            text:
                'Automatically asks for an I\'m safe confirmation. If missed, SOS escalation can trigger.',
          ),
          const SizedBox(height: 16),
          Card(
            color: _state.awaitingConfirmation
                ? Colors.red.shade50
                : Colors.amber.shade50,
            child: ListTile(
              leading: Icon(
                _state.awaitingConfirmation
                    ? Icons.warning_amber
                    : Icons.shield,
                color: _state.awaitingConfirmation
                    ? Colors.red
                    : Colors.amber.shade800,
              ),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(body),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Check-in Interval: $_intervalMinutes minutes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: _intervalMinutes.toDouble(),
            min: 2,
            max: 30,
            divisions: 14,
            onChanged: _state.isActive
                ? null
                : (v) => setState(() => _intervalMinutes = v.toInt()),
          ),
          const SizedBox(height: 8),
          Text(
            'Grace Period: $_graceSeconds seconds',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: _graceSeconds.toDouble(),
            min: 20,
            max: 120,
            divisions: 10,
            onChanged: _state.isActive
                ? null
                : (v) => setState(() => _graceSeconds = v.toInt()),
          ),
          const SizedBox(height: 20),
          if (!_state.isActive)
            FilledButton.icon(
              onPressed: _startTimer,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Check-In Timer'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
              ),
            )
          else ...[
            FilledButton.icon(
              onPressed: SafetyCheckInService.confirmSafe,
              icon: const Icon(Icons.check_circle),
              label: const Text('I\'m Safe'),
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: SafetyCheckInService.stop,
              icon: const Icon(Icons.stop),
              label: const Text('Stop Timer'),
            ),
          ],
        ],
      ),
    );
  }
}

/// FEATURE 2: Panic Widget Setup Screen
class PanicWidgetSetupScreen extends StatefulWidget {
  const PanicWidgetSetupScreen({super.key});

  @override
  State<PanicWidgetSetupScreen> createState() => _PanicWidgetSetupScreenState();
}

class _PanicWidgetSetupScreenState extends State<PanicWidgetSetupScreen> {
  bool _isEnabled = false;
  bool _isInitialized = false;
  int _guardianCount = 0;
  String _statusText = 'Ready';

  @override
  void initState() {
    super.initState();
    _checkWidgetStatus();
  }

  Future<void> _checkWidgetStatus() async {
    final authCubit = context.read<AuthCubit>();
    await PanicWidgetService.initialize();
    _isEnabled = await PanicWidgetService.getWidgetEnabledStatus();
    final user = authCubit.state.user;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final ids =
          (userDoc.data()?['emergencyContactIds'] as List?)
              ?.map((e) => '$e')
              .toList() ??
          <String>[];
      _guardianCount = ids.length;
      _statusText = ids.isEmpty ? 'Configure guardians in profile' : 'Ready';
    }
    if (!mounted) return;
    setState(() => _isInitialized = true);
  }

  Future<void> _updateWidget() async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please sign in first')));
      return;
    }

    await PanicWidgetService.updateWidget(
      userName: user.displayName ?? 'User',
      contactCount: _guardianCount,
      isEnabled: _isEnabled,
    );

    await PanicWidgetService.setWidgetEnabled(_isEnabled);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEnabled ? 'Panic widget enabled' : 'Panic widget disabled',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panic Widget'),
        backgroundColor: Colors.red,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _InfoCard(
            icon: Icons.widgets,
            text:
                'Add a one-tap SOS button to your home screen. Works even when phone is locked!',
          ),
          const SizedBox(height: 24),
          if (!_isInitialized)
            const Center(child: CircularProgressIndicator())
          else ...[
            SwitchListTile(
              title: const Text('Enable Panic Widget'),
              subtitle: const Text('Show SOS button on home screen'),
              value: _isEnabled,
              onChanged: (value) => setState(() => _isEnabled = value),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: const Text('Profile and Widget Status'),
                subtitle: Text(
                  'Guardians: $_guardianCount • Status: $_statusText',
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _updateWidget,
              icon: const Icon(Icons.update),
              label: const Text('Update Widget'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Setup Instructions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _InstructionStep(
                      number: '1',
                      text: 'Long press on your home screen',
                    ),
                    const _InstructionStep(
                      number: '2',
                      text: 'Tap "Widgets" and find "Women Safety"',
                    ),
                    const _InstructionStep(
                      number: '3',
                      text: 'Drag the Panic Button widget to your home screen',
                    ),
                    const _InstructionStep(
                      number: '4',
                      text: 'Enable the widget above and tap Update',
                    ),
                    const _InstructionStep(
                      number: '5',
                      text:
                          'Ensure at least one guardian is configured in Profile',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// FEATURE 3: Live Streaming Screen
class LiveStreamingScreen extends StatefulWidget {
  const LiveStreamingScreen({super.key});

  @override
  State<LiveStreamingScreen> createState() => _LiveStreamingScreenState();
}

class _LiveStreamingScreenState extends State<LiveStreamingScreen> {
  bool _isStreaming = false;
  bool _isInitialized = false;
  String? _channelId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await LiveStreamingService.initialize();
    setState(() => _isInitialized = true);
  }

  Future<void> _startStreaming() async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;

    final channelId = await LiveStreamingService.startStreaming(
      userId: user.uid,
    );

    setState(() {
      _isStreaming = true;
      _channelId = channelId;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Streaming started: $channelId')));
  }

  Future<void> _stopStreaming() async {
    await LiveStreamingService.stopStreaming();
    setState(() {
      _isStreaming = false;
      _channelId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Streaming'),
        backgroundColor: Colors.purple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _InfoCard(
            icon: Icons.videocam,
            text:
                'Stream live video to guardians during emergency using Agora WebRTC.',
          ),
          const SizedBox(height: 24),
          if (!_isInitialized)
            const Center(child: CircularProgressIndicator())
          else if (_isStreaming) ...[
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.fiber_manual_record,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Live Streaming Active',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Channel: $_channelId',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filled(
                          onPressed: () => LiveStreamingService.switchCamera(),
                          icon: const Icon(Icons.flip_camera_ios),
                          tooltip: 'Switch Camera',
                        ),
                        const SizedBox(width: 16),
                        IconButton.filled(
                          onPressed: () =>
                              LiveStreamingService.toggleVideo(false),
                          icon: const Icon(Icons.videocam_off),
                          tooltip: 'Toggle Video',
                        ),
                        const SizedBox(width: 16),
                        IconButton.filled(
                          onPressed: () =>
                              LiveStreamingService.toggleMicrophone(false),
                          icon: const Icon(Icons.mic_off),
                          tooltip: 'Toggle Mic',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _stopStreaming,
              icon: const Icon(Icons.stop),
              label: const Text('Stop Streaming'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: _startStreaming,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Streaming'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuration Required',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('To use live streaming:'),
                    const SizedBox(height: 8),
                    const Text('1. Sign up at agora.io'),
                    const Text('2. Get your App ID'),
                    const Text(
                      '3. Update lib/services/live_streaming_service.dart line 15',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// FEATURE 4: Ride Tracking Screen
class RideTrackingScreen extends StatefulWidget {
  const RideTrackingScreen({super.key});

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _destinationLatController = TextEditingController();
  final _destinationLngController = TextEditingController();
  String _rideType = 'ola';
  bool _isTracking = false;
  StreamSubscription<RideTrackingSnapshot>? _trackingSubscription;
  RideTrackingSnapshot? _lastSnapshot;
  List<Guardian> _activeGuardians = [];

  @override
  void initState() {
    super.initState();
    _isTracking = RideTrackingService.isTracking;
    _lastSnapshot = RideTrackingService.lastSnapshot;
    _trackingSubscription = RideTrackingService.trackingUpdates.listen((
      snapshot,
    ) {
      if (!mounted) return;
      setState(() => _lastSnapshot = snapshot);
    });
  }

  @override
  void dispose() {
    _trackingSubscription?.cancel();
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _vehicleNumberController.dispose();
    _vehicleModelController.dispose();
    _destinationLatController.dispose();
    _destinationLngController.dispose();
    super.dispose();
  }

  Future<void> _startTracking() async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in before starting ride tracking'),
        ),
      );
      return;
    }

    final guardians = await GuardianRepository().fetchGuardiansForUser(
      user.uid,
    );

    guardians.removeWhere((g) => g.phone.trim().isEmpty);

    if (guardians.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add guardians with valid phone numbers first'),
        ),
      );
      return;
    }

    Position? destination;
    final destinationLatRaw = _destinationLatController.text.trim();
    final destinationLngRaw = _destinationLngController.text.trim();
    final hasDestinationInput =
        destinationLatRaw.isNotEmpty || destinationLngRaw.isNotEmpty;
    final parsedLat = double.tryParse(destinationLatRaw);
    final parsedLng = double.tryParse(destinationLngRaw);
    if (hasDestinationInput && (parsedLat == null || parsedLng == null)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Destination coordinates are invalid. Clear both fields or enter valid latitude/longitude.',
          ),
        ),
      );
      return;
    }
    if (parsedLat != null && parsedLng != null) {
      destination = Position(
        longitude: parsedLng,
        latitude: parsedLat,
        timestamp: DateTime.now(),
        accuracy: 5,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }

    final rideId = await RideTrackingService.startRideTracking(
      userId: user.uid,
      guardians: guardians,
      rideDetails: {
        'driverName': _driverNameController.text,
        'driverPhone': _driverPhoneController.text,
        'vehicleNumber': _vehicleNumberController.text,
        'vehicleModel': _vehicleModelController.text,
        'rideType': _rideType,
      },
      destination: destination,
    );

    if (rideId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to start ride tracking. Check location permission and try again.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isTracking = true;
      _activeGuardians = guardians;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('🚗 Ride tracking started')));
  }

  Future<void> _stopTracking() async {
    await RideTrackingService.stopRideTracking(reachedSafely: true);
    setState(() {
      _isTracking = false;
      _activeGuardians = [];
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ride ended safely')));
  }

  Future<void> _triggerRideEmergency() async {
    if (_activeGuardians.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active guardians to alert')),
      );
      return;
    }

    await RideTrackingService.triggerRidePanic(_activeGuardians);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency alert sent to guardians')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Tracking'),
        backgroundColor: Colors.orange,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _InfoCard(
            icon: Icons.local_taxi,
            text:
                'Track Uber/Ola/Auto rides with real-time monitoring and route deviation alerts.',
          ),
          const SizedBox(height: 24),
          if (_isTracking) ...[
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.navigation, color: Colors.orange, size: 48),
                    SizedBox(height: 8),
                    Text(
                      '🟢 TRACKING ACTIVE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Guardians are receiving your live location'),
                    if (_lastSnapshot != null) ...[
                      SizedBox(height: 12),
                      Text('Status: ${_lastSnapshot!.statusMessage}'),
                      Text(
                        'Speed: ${(_lastSnapshot!.speedKmh ?? 0).toStringAsFixed(1)} km/h',
                      ),
                      Text(
                        'Distance: ${((_lastSnapshot!.totalDistanceMeters ?? 0) / 1000).toStringAsFixed(2)} km',
                      ),
                      if (_lastSnapshot!.remainingDistanceMeters != null)
                        Text(
                          'Remaining: ${(_lastSnapshot!.remainingDistanceMeters! / 1000).toStringAsFixed(2)} km',
                        ),
                      if (_lastSnapshot!.routeDeviationMeters != null)
                        Text(
                          'Deviation: ${_lastSnapshot!.routeDeviationMeters!.toStringAsFixed(0)} m',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _triggerRideEmergency,
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('Emergency During Ride'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _stopTracking,
              icon: const Icon(Icons.stop),
              label: const Text('End Ride Safely'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ] else ...[
            DropdownButtonFormField<String>(
              initialValue: _rideType,
              decoration: const InputDecoration(
                labelText: 'Ride Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_taxi),
              ),
              items: const [
                DropdownMenuItem(value: 'uber', child: Text('Uber')),
                DropdownMenuItem(value: 'ola', child: Text('Ola')),
                DropdownMenuItem(value: 'auto', child: Text('Auto Rickshaw')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _rideType = value!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _driverNameController,
              decoration: const InputDecoration(
                labelText: 'Driver Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _driverPhoneController,
              decoration: const InputDecoration(
                labelText: 'Driver Phone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _vehicleNumberController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_car),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _vehicleModelController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Model',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.car_rental),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _destinationLatController,
                    decoration: const InputDecoration(
                      labelText: 'Destination Lat',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _destinationLngController,
                    decoration: const InputDecoration(
                      labelText: 'Destination Lng',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Optional: Enter destination coordinates to enable route-deviation checks.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _startTracking,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Ride Tracking'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// FEATURE 5: Guardian Network Screen
class GuardianNetworkScreen extends StatefulWidget {
  const GuardianNetworkScreen({super.key});

  @override
  State<GuardianNetworkScreen> createState() => _GuardianNetworkScreenState();
}

class _GuardianNetworkScreenState extends State<GuardianNetworkScreen> {
  bool _isVolunteer = false;
  double _radiusKm = 2.0;
  List<Map<String, dynamic>> _nearbyVolunteers = [];

  Future<void> _registerAsVolunteer() async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;

    await GuardianNetworkService.registerAsVolunteer(
      userId: user.uid,
      name: user.displayName ?? 'User',
      phone: user.phoneNumber ?? '',
      radiusKm: _radiusKm,
    );

    setState(() => _isVolunteer = true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registered as volunteer guardian')),
    );
  }

  Future<void> _findNearbyVolunteers() async {
    final position = await Geolocator.getCurrentPosition();
    final volunteers = await GuardianNetworkService.findNearbyVolunteers(
      userPosition: position,
      radiusKm: _radiusKm,
    );

    setState(() => _nearbyVolunteers = volunteers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Network'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _InfoCard(
            icon: Icons.people,
            text:
                'Connect with nearby verified volunteers who can help during emergencies.',
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Register as Volunteer Guardian'),
            subtitle: const Text('Help others in your area during emergencies'),
            value: _isVolunteer,
            onChanged: (value) {
              if (value) {
                _registerAsVolunteer();
              }
            },
          ),
          if (_isVolunteer) ...[
            const SizedBox(height: 16),
            Text('Help Radius: ${_radiusKm.toStringAsFixed(1)} km'),
            Slider(
              value: _radiusKm,
              min: 1,
              max: 10,
              divisions: 18,
              label: '${_radiusKm.toStringAsFixed(1)} km',
              onChanged: (value) => setState(() => _radiusKm = value),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _findNearbyVolunteers,
            icon: const Icon(Icons.search),
            label: const Text('Find Nearby Volunteers'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),
          if (_nearbyVolunteers.isNotEmpty) ...[
            Text(
              'Found ${_nearbyVolunteers.length} nearby volunteers',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ..._nearbyVolunteers.map(
              (volunteer) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade100,
                    child: const Icon(Icons.person, color: Colors.green),
                  ),
                  title: Text(volunteer['name'] ?? 'Volunteer'),
                  subtitle: Text(
                    '${(volunteer['distance'] as double).toStringAsFixed(2)} km away',
                  ),
                  trailing: Text(
                    '⭐ ${volunteer['rating']?.toStringAsFixed(1) ?? 'N/A'}',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// FEATURE 6: Face Recognition Screen
class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _registeredGuardianId;

  Future<void> _registerFace() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    final guardianId = 'guardian_${DateTime.now().millisecondsSinceEpoch}';

    final isRegistered = await FaceRecognitionService.registerGuardianFace(
      guardianId: guardianId,
      imagePath: image.path,
    );

    if (!mounted) return;
    if (!isRegistered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Face registration failed. Make sure one clear face is visible.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _registeredGuardianId = guardianId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Guardian face registered')),
    );
  }

  Future<void> _verifyFace() async {
    final result = await FaceRecognitionService.verifyFace();

    if (!mounted) return;
    if (result['verified']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verified: ${result['guardianId']} (${result['confidence']}% confidence)',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((result['error'] as String?) ?? 'Unknown person detected'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Recognition'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _InfoCard(
            icon: Icons.face,
            text:
                'Verify trusted contacts during SOS using Google ML Kit face detection.',
          ),
          const SizedBox(height: 24),
          if (_registeredGuardianId != null) ...[
            Card(
              color: Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.teal,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Guardian Face Registered',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: $_registeredGuardianId',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          FilledButton.icon(
            onPressed: _registerFace,
            icon: const Icon(Icons.add_a_photo),
            label: const Text('Register Guardian Face'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _verifyFace,
            icon: const Icon(Icons.face_unlock_outlined),
            label: const Text('Verify Face Now'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
        ],
      ),
    );
  }
}

/// FEATURE 7: Voice Distress Analysis Screen
class VoiceDistressScreen extends StatefulWidget {
  const VoiceDistressScreen({super.key});

  @override
  State<VoiceDistressScreen> createState() => _VoiceDistressScreenState();
}

class _VoiceDistressScreenState extends State<VoiceDistressScreen> {
  bool _isAnalyzing = false;
  bool _isHandlingAutoSOS = false;
  double _distressScore = 0;
  List<String> _detectedKeywords = [];
  String _lastText = '';
  late final TextEditingController _keywordController;
  StreamSubscription<Map<String, dynamic>>? _analysisSubscription;

  @override
  void initState() {
    super.initState();
    _keywordController = TextEditingController(
      text: DistressVoiceAnalysisService.distressKeywords.join(', '),
    );
  }

  @override
  void dispose() {
    _analysisSubscription?.cancel();
    DistressVoiceAnalysisService.stopAnalysis();
    _keywordController.dispose();
    super.dispose();
  }

  void _applyCustomKeywords() {
    final values = _keywordController.text
        .split(RegExp(r'[\n,]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    DistressVoiceAnalysisService.updateDistressKeywords(
      values,
      includeDefaults: true,
    );
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice distress keywords updated')),
    );
  }

  void _resetKeywords() {
    DistressVoiceAnalysisService.resetDistressKeywords();
    _keywordController.text = DistressVoiceAnalysisService.distressKeywords
        .join(', ');
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice distress keywords reset to defaults'),
      ),
    );
  }

  Future<List<Guardian>> _loadGuardians(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    final guardianIds =
        (userDoc.data()?['emergencyContactIds'] as List?)
            ?.map((e) => '$e')
            .toList() ??
        [];

    final guardians = <Guardian>[];
    for (final id in guardianIds) {
      final doc = await FirebaseFirestore.instance
          .collection('guardians')
          .doc(id)
          .get();
      if (doc.exists) {
        guardians.add(Guardian.fromJson({'id': doc.id, ...doc.data()!}));
      }
    }
    return guardians
        .where((guardian) => guardian.phone.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _handleAutoSOS(int score, String transcript) async {
    if (_isHandlingAutoSOS) {
      return;
    }

    _isHandlingAutoSOS = true;

    final user = context.read<AuthCubit>().state.user;
    if (user == null) {
      _isHandlingAutoSOS = false;
      return;
    }

    try {
      List<Guardian> guardians = <Guardian>[];
      try {
        guardians = await _loadGuardians(user.uid);
      } catch (e) {
        debugPrint('❌ Failed to load guardians for voice SOS: $e');
      }

      if (guardians.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Distress detected but no guardians configured'),
          ),
        );
        return;
      }

      // Trigger full SOS flow using the same call-first pipeline as manual SOS.
      try {
        await SOSService.triggerSOS(
          user: user,
          emergencyContacts: guardians,
          triggerType: 'VOICE',
          makeCall: true,
          playAlarm: true,
        );
      } catch (e) {
        debugPrint('❌ Voice SOS trigger failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not trigger SOS. Check network and guardians setup.',
              ),
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Voice distress triggered immediate guardian call\n"$transcript"',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isHandlingAutoSOS = false;
    }
  }

  Future<void> _startAnalysis() async {
    final initialized = await DistressVoiceAnalysisService.initialize();
    if (!initialized) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition is not available on this device'),
        ),
      );
      return;
    }

    DistressVoiceAnalysisService.onAutoSOSRequested = _handleAutoSOS;
    final stream = await DistressVoiceAnalysisService.startAnalysis(
      emergencyMode: false,
    );

    setState(() => _isAnalyzing = true);

    _analysisSubscription?.cancel();
    _analysisSubscription = stream.listen((data) {
      final score = ((data['distressScore'] ?? 0) as num).toDouble();
      final transcript = (data['text'] ?? '').toString();
      final isDistressed = data['isDistressed'] == true;
      final isHighConfidenceDistress = data['isHighConfidenceDistress'] == true;

      if (mounted) {
        setState(() {
          _distressScore = score;
          _detectedKeywords = List<String>.from(data['keywords'] ?? []);
          _lastText = transcript;
        });

        if (isDistressed) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('High distress detected'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      if (isHighConfidenceDistress && !_isHandlingAutoSOS) {
        unawaited(_handleAutoSOS(score.toInt(), transcript));
      }
    });
  }

  Future<void> _stopAnalysis() async {
    await _analysisSubscription?.cancel();
    _analysisSubscription = null;
    await DistressVoiceAnalysisService.stopAnalysis();
    setState(() {
      _isAnalyzing = false;
      _distressScore = 0;
      _detectedKeywords = [];
      _lastText = '';
    });
  }

  Color _getDistressColor() {
    if (_distressScore >= 80) return Colors.red;
    if (_distressScore >= 60) return Colors.orange;
    if (_distressScore >= 40) return Colors.yellow.shade700;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Distress Analysis'),
        backgroundColor: Colors.pink,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _InfoCard(
            icon: Icons.mic,
            text:
                'Auto-detect distress in voice tone and trigger SOS at 80% distress level.',
          ),
          const SizedBox(height: 24),
          if (_isAnalyzing) ...[
            Card(
              color: _getDistressColor().withAlpha((255 * 0.1).round()),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.graphic_eq,
                      color: _getDistressColor(),
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Analyzing Voice',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Distress Score: ${_distressScore.toStringAsFixed(0)}/100',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getDistressColor(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _distressScore / 100,
                      backgroundColor: Colors.grey.shade200,
                      color: _getDistressColor(),
                      minHeight: 8,
                    ),
                    if (_detectedKeywords.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: _detectedKeywords
                            .map(
                              (keyword) => Chip(
                                label: Text(keyword),
                                backgroundColor: Colors.red.shade100,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (_lastText.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        '"$_lastText"',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _stopAnalysis,
              icon: const Icon(Icons.stop),
              label: const Text('Stop Analysis'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: _startAnalysis,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Voice Analysis'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.pink,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distress Keywords Detected:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: DistressVoiceAnalysisService.distressKeywords
                          .map(
                            (keyword) => Chip(
                              label: Text(keyword),
                              backgroundColor: Colors.grey.shade200,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _keywordController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Add custom keywords or phrases',
                        hintText: 'example: follow me, leave me, help',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _applyCustomKeywords,
                            icon: const Icon(Icons.tune),
                            label: const Text('Apply Keywords'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _resetKeywords,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// FEATURE 8: ML Danger Prediction Map Screen
class AIDangerMapScreen extends StatefulWidget {
  const AIDangerMapScreen({super.key});

  @override
  State<AIDangerMapScreen> createState() => _AIDangerMapScreenState();
}

class _AIDangerMapScreenState extends State<AIDangerMapScreen> {
  bool _isInitialized = false;
  bool _isLoadingPrediction = false;
  Map<String, dynamic>? _prediction;
  Map<String, dynamic>? _cityInsights;
  String? _errorMessage;

  Future<String?> _selectRouteUrl(List<dynamic> routeOptions) async {
    if (!mounted) return null;

    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text('Choose Safe Route'),
                subtitle: Text('Select the route you want to open in maps.'),
              ),
              ...routeOptions.map((rawOption) {
                final option = rawOption as Map<String, dynamic>;
                final mapsUrl = (option['mapsUrl'] ?? '').toString();
                return ListTile(
                  leading: const Icon(Icons.route, color: Colors.green),
                  title: Text('${option['name'] ?? 'Route'}'),
                  subtitle: Text(
                    'Safety: ${option['safetyScore'] ?? '-'} / Danger: ${option['routeDangerScore'] ?? '-'} • '
                    'Distance: ${((option['routeDistanceKm'] as num?) ?? 0).toStringAsFixed(2)} km',
                  ),
                  onTap: mapsUrl.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(mapsUrl),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openSafeRoutes() async {
    final routeOptions = _cityInsights?['saferOptions'] as List<dynamic>?;
    var mapsUrl = 'https://www.google.com/maps/dir/?api=1&travelmode=walking';

    if (routeOptions != null && routeOptions.isNotEmpty) {
      final selected = await _selectRouteUrl(routeOptions);
      if (selected == null || selected.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route selection cancelled')),
        );
        return;
      }
      mapsUrl = selected;
    }

    final webUri = Uri.parse(mapsUrl);
    bool launched = false;

    try {
      launched = await launchUrl(
        webUri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
    } catch (_) {}

    if (!launched) {
      try {
        launched = await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {}
    }

    if (!launched) {
      final destination = webUri.queryParameters['destination'];
      if (destination != null && destination.isNotEmpty) {
        final geoUri = Uri.parse('geo:0,0?q=$destination');
        try {
          launched = await launchUrl(
            geoUri,
            mode: LaunchMode.externalApplication,
          );
        } catch (_) {}
      }
    }

    if (!mounted) return;

    if (launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗺️ Opening safe route navigation')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open maps app. Please check default map app settings.',
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await AIDangerPredictionService.initialize();
      if (!mounted) return;
      setState(() => _isInitialized = true);
      await _predictCurrentLocation();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _errorMessage = 'Failed to initialize ML danger prediction: $e';
      });
    }
  }

  Future<bool> _ensureLocationReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMessage = 'Location services are disabled. Please enable GPS.';
      });
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _errorMessage =
            'Location permission denied. Allow location to see ML danger prediction.';
      });
      return false;
    }

    return true;
  }

  Future<void> _predictCurrentLocation() async {
    setState(() {
      _isLoadingPrediction = true;
      _errorMessage = null;
    });

    try {
      final ready = await _ensureLocationReady();
      if (!ready) {
        setState(() => _isLoadingPrediction = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      final prediction = await AIDangerPredictionService.predictDanger(
        position: position,
        time: DateTime.now(),
      );

      final cityInsights =
          await AIDangerPredictionService.getCitySafetyInsights(
            start: position,
          );

      if (!mounted) return;
      setState(() {
        _prediction = prediction;
        _cityInsights = cityInsights;
        _isLoadingPrediction = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPrediction = false;
        _errorMessage = 'Unable to compute danger prediction: $e';
      });
    }
  }

  Color _getDangerColor() {
    if (_prediction == null) return Colors.grey;
    final score = (_prediction!['dangerScore'] as num?)?.toDouble() ?? 5.0;
    if (score >= 8) return Colors.red.shade900;
    if (score >= 6) return Colors.red;
    if (score >= 4) return Colors.orange;
    if (score >= 2) return Colors.yellow.shade700;
    return Colors.green;
  }

  IconData _getDangerIcon() {
    if (_prediction == null) return Icons.help_outline;
    final level = (_prediction!['level'] as String?) ?? 'MEDIUM';
    if (level == 'CRITICAL' || level == 'HIGH') return Icons.warning;
    if (level == 'MEDIUM') return Icons.error_outline;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 ML Danger Prediction'),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _predictCurrentLocation,
            tooltip: 'Refresh Prediction',
          ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : _isLoadingPrediction
          ? const Center(child: CircularProgressIndicator())
          : (_errorMessage != null)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _predictCurrentLocation,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _InfoCard(
                  icon: Icons.psychology,
                  text:
                      'ML-powered danger zone detection with safe route recommendations.',
                ),
                const SizedBox(height: 24),
                if (_cityInsights != null)
                  Card(
                    color: Colors.blue.shade50,
                    child: ListTile(
                      leading: const Icon(
                        Icons.my_location,
                        color: Colors.blueAccent,
                      ),
                      title: Text(
                        'GPS-detected city dataset: ${_cityInsights!['city']}',
                      ),
                      subtitle: const Text(
                        'City is selected automatically from your current location.',
                      ),
                    ),
                  ),
                if (_cityInsights?['preRouteSafetyBrief'] != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pre-Route Safety Brief',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Nearest support: ${_cityInsights!['preRouteSafetyBrief']['nearestPoliceSupport']['name']} '
                            '(${_cityInsights!['preRouteSafetyBrief']['nearestPoliceSupport']['type']})',
                          ),
                          Text(
                            'Nearest risk pocket: ${_cityInsights!['preRouteSafetyBrief']['nearestRiskPocket']['name']} '
                            '(${_cityInsights!['preRouteSafetyBrief']['nearestRiskPocket']['risk']})',
                          ),
                          Text(
                            'Emergency contact: ${_cityInsights!['preRouteSafetyBrief']['recommendedContact']['name']} '
                            '• ${_cityInsights!['preRouteSafetyBrief']['recommendedContact']['contact']}',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Card(
                  color: Colors.blueGrey.withAlpha((255 * 0.12).round()),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Diagnostics',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text('Initialized: $_isInitialized'),
                        Text('Loading: $_isLoadingPrediction'),
                        Text('Has Prediction: ${_prediction != null}'),
                        if (_prediction != null)
                          Text(
                            'Prediction Engine: ${_prediction!['predictionEngine'] ?? 'unknown'}',
                          ),
                        if (_prediction != null)
                          Text(
                            'Model Loaded: ${_prediction!['modelLoaded'] ?? false}',
                          ),
                        if (_prediction != null &&
                            _prediction!['districtProfile'] != null)
                          Text(
                            'District: ${_prediction!['districtProfile']['district']}',
                          ),
                        if (_prediction != null &&
                            _prediction!['districtProfile'] != null)
                          Text(
                            'District Review: ${_prediction!['districtProfile']['lastReviewedOn']}',
                          ),
                        Text('Has City Insights: ${_cityInsights != null}'),
                        if (_cityInsights != null)
                          Text('Detected City: ${_cityInsights!['city']}'),
                        if (_errorMessage != null)
                          Text(
                            'Error: $_errorMessage',
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_prediction != null) ...[
                  Builder(
                    builder: (_) {
                      final level =
                          (_prediction!['level'] as String?) ?? 'MEDIUM';
                      final score =
                          (_prediction!['dangerScore'] as num?)?.toDouble() ??
                          5.0;
                      final recommendations =
                          ((_prediction!['recommendations'] as List?)
                                      ?.map((e) => e.toString())
                                      .toList() ??
                                  const <String>[
                                    'Prediction available, but recommendations are missing.',
                                  ])
                              .toList();

                      return Column(
                        children: [
                          Card(
                            color: _getDangerColor().withAlpha(
                              (255 * 0.1).round(),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(
                                    _getDangerIcon(),
                                    color: _getDangerColor(),
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    level,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: _getDangerColor(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Danger Score: ${score.toStringAsFixed(1)}/10',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  const SizedBox(height: 16),
                                  LinearProgressIndicator(
                                    value: score / 10,
                                    backgroundColor: Colors.grey.shade200,
                                    color: _getDangerColor(),
                                    minHeight: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Safety Recommendations',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          ...recommendations.map(
                            (rec) => Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.amber,
                                ),
                                title: Text(rec),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                  if (_cityInsights != null) ...[
                    Text(
                      '${_cityInsights!['city']} Safer Route Options',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_cityInsights!['routeRecommendation'] != null)
                      Card(
                        color: Colors.green.shade50,
                        child: ListTile(
                          leading: const Icon(Icons.route, color: Colors.green),
                          title: Text(
                            'Recommended: ${_cityInsights!['routeRecommendation']['name']}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${_cityInsights!['routeRecommendation']['description']}\n'
                            'Danger score: ${(_cityInsights!['routeRecommendation']['dangerScore'] as num).toStringAsFixed(1)}/10 • '
                            'Distance: ${(_cityInsights!['routeRecommendation']['distanceKm'] as num).toStringAsFixed(2)} km',
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    ...(_cityInsights!['saferOptions'] as List<dynamic>).map(
                      (option) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.route, color: Colors.green),
                          title: Text(
                            '${option['name']} (Score ${option['safetyScore']}/10)',
                          ),
                          subtitle: Text(
                            '${option['description']}\n'
                            'Danger score: ${option['routeDangerScore'] as num? ?? 0}/10 • '
                            'Distance: ${((option['routeDistanceKm'] as num?) ?? 0).toStringAsFixed(2)} km',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Riskier Areas Nearby',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...(_cityInsights!['riskyAreas'] as List<dynamic>)
                        .take(5)
                        .map(
                          (area) => Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.warning_amber,
                                color: Colors.red,
                              ),
                              title: Text('${area['name']} (${area['risk']})'),
                              subtitle: Text(
                                '${(area['distanceKm'] as double).toStringAsFixed(2)} km away\n${area['reason']}',
                              ),
                              isThreeLine: true,
                            ),
                          ),
                        ),
                    const SizedBox(height: 16),
                    Text(
                      'Nearby Police Stations / Booths',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...(_cityInsights!['nearbyPolice'] as List<dynamic>).map(
                      (station) => Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.local_police,
                            color: Colors.blue,
                          ),
                          title: Text(
                            '${station['name']} (${station['type']})',
                          ),
                          subtitle: Text(
                            '${(station['distanceKm'] as double).toStringAsFixed(2)} km away\n${station['contact']}',
                          ),
                          isThreeLine: true,
                        ),
                      ),
                    ),
                    if ((_cityInsights!['emergencyContacts']
                                as List<dynamic>? ??
                            const [])
                        .isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'District Emergency Contacts',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(_cityInsights!['emergencyContacts'] as List<dynamic>)
                          .map(
                            (contact) => Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.support_agent,
                                  color: Colors.deepOrange,
                                ),
                                title: Text(
                                  '${contact['name']} (${contact['type']})',
                                ),
                                subtitle: Text('${contact['contact']}'),
                              ),
                            ),
                          ),
                    ],
                  ],
                ] else ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.analytics_outlined,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No AI prediction available yet.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap refresh to calculate the current danger score.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _predictCurrentLocation,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Run Prediction'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSafeRoutes,
        icon: const Icon(Icons.navigation),
        label: const Text('Safe Routes'),
        backgroundColor: Colors.deepOrange,
      ),
    );
  }
}

/// Helper Widgets
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 32),
            const SizedBox(width: 16),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.red,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

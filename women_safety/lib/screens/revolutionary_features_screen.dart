import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bloc/auth/auth_cubit.dart';
import '../models/guardian.dart';
import '../services/fake_call_service.dart';
import '../services/panic_widget_service.dart';
import '../services/live_streaming_service.dart';
import '../services/ride_tracking_service.dart';
import '../services/guardian_network_service.dart';
import '../services/face_recognition_service.dart';
import '../services/distress_voice_analysis_service.dart';
import '../services/ai_danger_prediction_service.dart';
import '../services/config.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revolutionary Features'),
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
            '8 AI-powered features to keep you safer',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 24),

          // Feature 1: Fake Call
          _ClassicFeatureCard(
            icon: Icons.phone_callback,
            title: 'Fake Call',
            description: 'Escape dangerous situations with realistic incoming call',
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FakeCallScreen()),
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
            disabledReason: 'Configure Agora App ID to enable live streaming',
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
            disabledReason: 'Volunteer network is disabled in this build',
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
            description: 'Verify trusted contacts with ML-powered face detection',
            color: Colors.teal,
            isEnabled: faceRecognitionEnabled,
            disabledReason: 'Face recognition requires production ML models',
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
            disabledReason: 'Voice distress model is not configured',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VoiceDistressScreen()),
            ),
          ),
          const SizedBox(height: 12),

          // Feature 8: AI Danger Prediction
          _ClassicFeatureCard(
            icon: Icons.psychology,
            title: 'AI Danger Prediction',
            description: 'ML-powered danger zone detection and safe routes',
            color: Colors.deepOrange,
            isEnabled: aiDangerEnabled,
            disabledReason: 'AI danger model is not configured',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AIDangerMapScreen()),
            ),
          ),
          const SizedBox(height: 24),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
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
  final _callerNumberController = TextEditingController(text: '+91 98765 43210');
  int _delaySeconds = 0;
  bool _autoAnswer = false;

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
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fake call scheduled in $_delaySeconds seconds')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔐 Fake Call'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _InfoCard(
            icon: Icons.info_outline,
            text: 'Simulate a realistic incoming call to escape dangerous situations safely.',
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
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _triggerFakeCall,
            icon: const Icon(Icons.phone_callback),
            label: Text(_delaySeconds > 0 ? 'Schedule Fake Call' : 'Trigger Now'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.all(16),
            ),
          ),
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

  @override
  void initState() {
    super.initState();
    _checkWidgetStatus();
  }

  Future<void> _checkWidgetStatus() async {
    await PanicWidgetService.initialize();
    setState(() => _isInitialized = true);
  }

  Future<void> _updateWidget() async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first')),
      );
      return;
    }

    await PanicWidgetService.updateWidget(
      userName: user.displayName ?? 'User',
      contactCount: 3,
      isEnabled: _isEnabled,
    );

    await PanicWidgetService.setWidgetEnabled(_isEnabled);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEnabled ? 'Panic Widget enabled ✅' : 'Panic Widget disabled'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚨 Panic Widget'),
        backgroundColor: Colors.red,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _InfoCard(
            icon: Icons.widgets,
            text: 'Add a one-tap SOS button to your home screen. Works even when phone is locked!',
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Streaming started: $channelId')),
    );
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
        title: const Text('📹 Live Streaming'),
        backgroundColor: Colors.purple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _InfoCard(
            icon: Icons.videocam,
            text: 'Stream live video to guardians during emergency using Agora WebRTC.',
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
                    const Icon(Icons.fiber_manual_record, color: Colors.red, size: 48),
                    const SizedBox(height: 8),
                    const Text('🔴 LIVE STREAMING', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Channel: $_channelId', style: const TextStyle(fontSize: 12)),
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
                          onPressed: () => LiveStreamingService.toggleVideo(false),
                          icon: const Icon(Icons.videocam_off),
                          tooltip: 'Toggle Video',
                        ),
                        const SizedBox(width: 16),
                        IconButton.filled(
                          onPressed: () => LiveStreamingService.toggleMicrophone(false),
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
                      '⚠️ Configuration Required',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    const Text('To use live streaming:'),
                    const SizedBox(height: 8),
                    const Text('1. Sign up at agora.io'),
                    const Text('2. Get your App ID'),
                    const Text('3. Update lib/services/live_streaming_service.dart line 15'),
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
  String _rideType = 'ola';
  bool _isTracking = false;

  @override
  void dispose() {
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _vehicleNumberController.dispose();
    _vehicleModelController.dispose();
    super.dispose();
  }

  Future<void> _startTracking() async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;

    // Get guardians
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final guardianIds = (userDoc.data()?['emergencyContactIds'] as List?)?.map((e) => '$e').toList() ?? [];

    final guardians = <Guardian>[];
    for (final id in guardianIds) {
      final doc = await FirebaseFirestore.instance.collection('guardians').doc(id).get();
      if (doc.exists) {
        guardians.add(Guardian.fromJson(doc.data()!));
      }
    }

    if (guardians.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add guardians first')),
      );
      return;
    }

    await RideTrackingService.startRideTracking(
      userId: user.uid,
      guardians: guardians,
      rideDetails: {
        'driverName': _driverNameController.text,
        'driverPhone': _driverPhoneController.text,
        'vehicleNumber': _vehicleNumberController.text,
        'vehicleModel': _vehicleModelController.text,
        'rideType': _rideType,
      },
    );

    setState(() => _isTracking = true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🚗 Ride tracking started')),
    );
  }

  Future<void> _stopTracking() async {
    await RideTrackingService.stopRideTracking(reachedSafely: true);
    setState(() => _isTracking = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Ride ended safely')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚗 Ride Tracking'),
        backgroundColor: Colors.orange,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _InfoCard(
            icon: Icons.local_taxi,
            text: 'Track Uber/Ola/Auto rides with real-time monitoring and route deviation alerts.',
          ),
          const SizedBox(height: 24),
          if (_isTracking) ...[
            Card(
              color: Colors.orange.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.navigation, color: Colors.orange, size: 48),
                    SizedBox(height: 8),
                    Text('🟢 TRACKING ACTIVE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Guardians are receiving your live location'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
      const SnackBar(content: Text('✅ Registered as volunteer guardian')),
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
        title: const Text('🤝 Guardian Network'),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _InfoCard(
            icon: Icons.people,
            text: 'Connect with nearby verified volunteers who can help during emergencies.',
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
            ..._nearbyVolunteers.map((volunteer) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: const Icon(Icons.person, color: Colors.green),
                    ),
                    title: Text(volunteer['name'] ?? 'Volunteer'),
                    subtitle: Text('${(volunteer['distance'] as double).toStringAsFixed(2)} km away'),
                    trailing: Text('⭐ ${volunteer['rating']?.toStringAsFixed(1) ?? 'N/A'}'),
                  ),
                )),
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

    await FaceRecognitionService.registerGuardianFace(
      guardianId: 'guardian_${DateTime.now().millisecondsSinceEpoch}',
      imagePath: image.path,
    );

    setState(() => _registeredGuardianId = 'guardian_${DateTime.now().millisecondsSinceEpoch}');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Guardian face registered')),
    );
  }

  Future<void> _verifyFace() async {
    final result = await FaceRecognitionService.verifyFace();

    if (!mounted) return;
    if (result['verified']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Verified: ${result['guardianId']} (${result['confidence']}% confidence)'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Unknown person detected'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👤 Face Recognition'),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _InfoCard(
            icon: Icons.face,
            text: 'Verify trusted contacts during SOS using Google ML Kit face detection.',
          ),
          const SizedBox(height: 24),
          if (_registeredGuardianId != null) ...[
            Card(
              color: Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.teal, size: 48),
                    const SizedBox(height: 8),
                    const Text('Guardian Face Registered', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('ID: $_registeredGuardianId', style: const TextStyle(fontSize: 12)),
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
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
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
  double _distressScore = 0;
  List<String> _detectedKeywords = [];
  String _lastText = '';

  Future<void> _startAnalysis() async {
    await DistressVoiceAnalysisService.initialize();
    final stream = await DistressVoiceAnalysisService.startAnalysis();

    setState(() => _isAnalyzing = true);

    stream.listen((data) {
      if (mounted) {
        setState(() {
          _distressScore = data['distressScore'] ?? 0;
          _detectedKeywords = List<String>.from(data['keywords'] ?? []);
          _lastText = data['text'] ?? '';
        });

        if (data['isDistressed'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ HIGH DISTRESS DETECTED!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  Future<void> _stopAnalysis() async {
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
        title: const Text('🗣️ Voice Distress Analysis'),
        backgroundColor: Colors.pink,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _InfoCard(
            icon: Icons.mic,
            text: 'Auto-detect distress in voice tone and trigger SOS at 80% distress level.',
          ),
          const SizedBox(height: 24),
          if (_isAnalyzing) ...[
            Card(
              color: _getDistressColor().withAlpha((255 * 0.1).round()),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.graphic_eq, color: _getDistressColor(), size: 48),
                    const SizedBox(height: 8),
                    const Text('🎤 ANALYZING VOICE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Text(
                      'Distress Score: ${_distressScore.toStringAsFixed(0)}/100',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _getDistressColor()),
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
                        children: _detectedKeywords.map((keyword) => Chip(
                              label: Text(keyword),
                              backgroundColor: Colors.red.shade100,
                            )).toList(),
                      ),
                    ],
                    if (_lastText.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('"$_lastText"', style: const TextStyle(fontStyle: FontStyle.italic)),
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
                    const Text('Distress Keywords Detected:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['help', 'stop', 'no', 'scared', 'emergency', 'police', 'danger']
                          .map((keyword) => Chip(label: Text(keyword), backgroundColor: Colors.grey.shade200))
                          .toList(),
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

/// FEATURE 8: AI Danger Prediction Map Screen
class AIDangerMapScreen extends StatefulWidget {
  const AIDangerMapScreen({super.key});

  @override
  State<AIDangerMapScreen> createState() => _AIDangerMapScreenState();
}

class _AIDangerMapScreenState extends State<AIDangerMapScreen> {
  bool _isInitialized = false;
  Map<String, dynamic>? _prediction;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await AIDangerPredictionService.initialize();
    setState(() => _isInitialized = true);
    await _predictCurrentLocation();
  }

  Future<void> _predictCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition();
    final prediction = await AIDangerPredictionService.predictDanger(
      position: position,
      time: DateTime.now(),
    );

    setState(() => _prediction = prediction);
  }

  Color _getDangerColor() {
    if (_prediction == null) return Colors.grey;
    final score = _prediction!['dangerScore'] as double;
    if (score >= 8) return Colors.red.shade900;
    if (score >= 6) return Colors.red;
    if (score >= 4) return Colors.orange;
    if (score >= 2) return Colors.yellow.shade700;
    return Colors.green;
  }

  IconData _getDangerIcon() {
    if (_prediction == null) return Icons.help_outline;
    final level = _prediction!['level'] as String;
    if (level == 'CRITICAL' || level == 'HIGH') return Icons.warning;
    if (level == 'MEDIUM') return Icons.error_outline;
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 AI Danger Prediction'),
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
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _InfoCard(
                  icon: Icons.psychology,
                  text: 'ML-powered danger zone detection with safe route recommendations.',
                ),
                const SizedBox(height: 24),
                if (_prediction != null) ...[
                  Card(
                    color: _getDangerColor().withAlpha((255 * 0.1).round()),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(_getDangerIcon(), color: _getDangerColor(), size: 64),
                          const SizedBox(height: 16),
                          Text(
                            '${_prediction!['level']}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: _getDangerColor(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Danger Score: ${(_prediction!['dangerScore'] as double).toStringAsFixed(1)}/10',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: (_prediction!['dangerScore'] as double) / 10,
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ...(_prediction!['recommendations'] as List<String>).map(
                    (rec) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.lightbulb_outline, color: Colors.amber),
                        title: Text(rec),
                      ),
                    ),
                  ),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final position = await Geolocator.getCurrentPosition();
          final lat = position.latitude;
          final lon = position.longitude;
          
          // Open Google Maps with safe route preferences (avoid highways, tolls, ferries)
          final mapsUrl = 'https://www.google.com/maps/dir/?api=1&origin=$lat,$lon&travelmode=walking';
          final uri = Uri.parse(mapsUrl);
          
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🗺️ Opening safe route navigation')),
            );
          } else {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('❌ Unable to open maps')),
            );
          }
        },
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
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 14),
              ),
            ),
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
            child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

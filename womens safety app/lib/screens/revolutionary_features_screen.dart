import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../services/ai_danger_prediction_service.dart';
import '../services/distress_voice_analysis_service.dart';
import '../services/evidence_capture_service.dart';
import '../services/face_recognition_service.dart';
import '../services/fake_call_service.dart';
import '../services/live_streaming_service.dart';
import '../services/location_share_service.dart';
import '../services/volunteer_network_service.dart';

class RevolutionaryFeaturesScreen extends StatefulWidget {
  const RevolutionaryFeaturesScreen({super.key});

  @override
  State<RevolutionaryFeaturesScreen> createState() =>
      _RevolutionaryFeaturesScreenState();
}

class _RevolutionaryFeaturesScreenState
    extends State<RevolutionaryFeaturesScreen> {
  final AiDangerPredictionService _aiService = AiDangerPredictionService();
  final DistressVoiceAnalysisService _voiceService =
      DistressVoiceAnalysisService();
  final FaceRecognitionService _faceService = FaceRecognitionService();
  final FakeCallService _fakeCallService = FakeCallService();
  final EvidenceCaptureService _evidenceService = EvidenceCaptureService();
  final VolunteerNetworkService _volunteerService = VolunteerNetworkService();
  final LocationShareService _locationService = LocationShareService();
  final LiveStreamingService _liveStreamingService = LiveStreamingService();

  @override
  void dispose() {
    _voiceService.dispose();
    _fakeCallService.dispose();
    _faceService.dispose();
    _liveStreamingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI-Powered Features')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFeatureCard(
            icon: Icons.psychology,
            title: 'AI Danger Prediction',
            subtitle: 'Analyze nearby area safety score',
            color: Colors.purple,
            onTap: _showDangerPrediction,
          ),
          _buildFeatureCard(
            icon: Icons.mic,
            title: 'Voice Distress Detection',
            subtitle: 'Detect distress keywords from text input test',
            color: Colors.orange,
            onTap: _showVoiceAnalysis,
          ),
          _buildFeatureCard(
            icon: Icons.face,
            title: 'Face Recognition',
            subtitle: 'Detect and analyze faces from camera/gallery',
            color: Colors.blue,
            onTap: _showFaceRecognition,
          ),
          _buildFeatureCard(
            icon: Icons.phone_callback,
            title: 'Fake Call Generator',
            subtitle: 'Schedule a realistic incoming call trigger',
            color: Colors.green,
            onTap: _showFakeCall,
          ),
          _buildFeatureCard(
            icon: Icons.route,
            title: 'Safe Routes',
            subtitle: 'Generate safer route alternatives',
            color: Colors.teal,
            onTap: _showSafeRoutes,
          ),
          _buildFeatureCard(
            icon: Icons.camera_alt,
            title: 'Evidence Capture',
            subtitle: 'Capture emergency photo evidence',
            color: Colors.red,
            onTap: _showEvidenceCapture,
          ),
          _buildFeatureCard(
            icon: Icons.video_call,
            title: 'Live Video Streaming',
            subtitle: 'Start emergency stream session',
            color: Colors.indigo,
            onTap: _showLiveStreaming,
          ),
          _buildFeatureCard(
            icon: Icons.group,
            title: 'Volunteer Network',
            subtitle: 'Find nearby verified volunteers',
            color: Colors.pink,
            onTap: _showVolunteerNetwork,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Future<void> Function() onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => onTap(),
      ),
    );
  }

  Future<void> _showDangerPrediction() async {
    _showLoadingDialog('Analyzing safety score...');

    final location = await _locationService.getCurrentLocation();
    if (!mounted) return;

    if (location == null) {
      Navigator.pop(context);
      _showSnack('Unable to get current location');
      return;
    }

    final prediction = await _aiService.predictDanger(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    if (!mounted) return;
    Navigator.pop(context);

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('AI Danger Prediction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Risk Level: ${prediction.riskLevel}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Score: ${prediction.dangerScore}/100'),
            const SizedBox(height: 8),
            Text(prediction.recommendation),
            const SizedBox(height: 8),
            const Text('Factors', style: TextStyle(fontWeight: FontWeight.bold)),
            ...prediction.factors.map((factor) => Text('• $factor')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showVoiceAnalysis() async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Voice Distress Detection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter a phrase to analyze distress keywords:'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Type voice transcript here...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final result = _voiceService.analyzeText(controller.text.trim());
              Navigator.pop(context);
              _showSnack(result.alertMessage);
            },
            child: const Text('Analyze'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFaceRecognition() async {
    final source = await showDialog<EvidenceSource>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Face Recognition'),
        content: const Text('Choose image source for face analysis.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, EvidenceSource.gallery),
            child: const Text('Gallery'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, EvidenceSource.camera),
            child: const Text('Camera'),
          ),
        ],
      ),
    );

    if (source == null) return;

    _showLoadingDialog('Detecting faces...');
    final evidence = await _evidenceService.capturePhotoEvidence(source: source);

    if (!mounted) return;
    if (evidence == null) {
      Navigator.pop(context);
      _showSnack('No image selected');
      return;
    }

    final input = InputImage.fromFilePath(evidence.filePath);
    final faces = await _faceService.detectFaces(input);

    if (!mounted) return;
    Navigator.pop(context);

    if (faces.isEmpty) {
      _showSnack('No face detected in selected image');
      return;
    }

    final analysis = await _faceService.analyzeFaceForDistress(faces.first);
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Face Analysis Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Faces detected: ${faces.length}'),
            Text(
              'Distress: ${analysis.isDistress ? 'Possible' : 'Not detected'}',
            ),
            Text('Confidence: ${(analysis.confidence * 100).toStringAsFixed(1)}%'),
            if (analysis.indicators.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Indicators',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...analysis.indicators.map((item) => Text('• $item')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showFakeCall() async {
    final nameController = TextEditingController(text: 'Emergency Contact');
    final numberController = TextEditingController(text: '+91 90000 00000');

    final payload = await showDialog<(String, String, int)?>(
      context: context,
      builder: (_) {
        int delaySeconds = 10;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Schedule Fake Call'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Caller Name'),
                ),
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(labelText: 'Caller Number'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Delay (sec): '),
                    Expanded(
                      child: Slider(
                        min: 5,
                        max: 60,
                        divisions: 11,
                        value: delaySeconds.toDouble(),
                        label: '$delaySeconds',
                        onChanged: (value) {
                          setDialogState(() => delaySeconds = value.toInt());
                        },
                      ),
                    ),
                    Text('$delaySeconds'),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    (nameController.text, numberController.text, delaySeconds),
                  );
                },
                child: const Text('Schedule'),
              ),
            ],
          ),
        );
      },
    );

    if (payload == null || !mounted) return;

    _fakeCallService.scheduleFakeCall(
      delay: Duration(seconds: payload.$3),
      callerName: payload.$1,
      callerNumber: payload.$2,
      onTriggered: (event) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Incoming Call'),
            content: Text('${event.callerName} (${event.callerNumber})'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Decline'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Accept'),
              ),
            ],
          ),
        );
      },
    );

    _showSnack('Fake call scheduled in ${payload.$3} seconds');
  }

  Future<void> _showSafeRoutes() async {
    _showLoadingDialog('Calculating safe routes...');

    final location = await _locationService.getCurrentLocation();
    if (!mounted) return;

    if (location == null) {
      Navigator.pop(context);
      _showSnack('Unable to get location for route planning');
      return;
    }

    final routes = await _aiService.getSafeRoutes(
      startLat: location.latitude,
      startLng: location.longitude,
      endLat: location.latitude + 0.02,
      endLng: location.longitude + 0.02,
    );

    if (!mounted) return;
    Navigator.pop(context);

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Recommended Safe Routes'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: routes.length,
            itemBuilder: (_, index) {
              final route = routes[index];
              return ListTile(
                title: Text(route.routeName),
                subtitle: Text(
                  'Safety: ${route.safetyScore} • ${route.distanceKm} km • ${route.estimatedMinutes} min',
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEvidenceCapture() async {
    final source = await showDialog<EvidenceSource>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Evidence Capture'),
        content: const Text('Choose evidence source.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, EvidenceSource.gallery),
            child: const Text('Gallery'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, EvidenceSource.camera),
            child: const Text('Camera'),
          ),
        ],
      ),
    );

    if (source == null) return;

    final result = await _evidenceService.capturePhotoEvidence(
      source: source,
      note: 'Emergency evidence',
    );

    if (!mounted) return;

    if (result == null) {
      _showSnack('Evidence capture cancelled');
      return;
    }

    _showSnack(
      'Evidence captured (${(result.sizeBytes / 1024).toStringAsFixed(0)} KB)',
    );
  }

  Future<void> _showLiveStreaming() async {
    if (!_liveStreamingService.isConfigured) {
      _showSnack('Set --dart-define=AGORA_APP_ID=your_key to enable streaming');
      return;
    }

    _showLoadingDialog('Starting secure emergency stream...');

    try {
      final session = await _liveStreamingService.startStream(
        userId: 'user-demo',
        userName: 'Emergency User',
      );

      if (!mounted) return;
      Navigator.pop(context);

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Live Stream Started'),
          content: Text(
            'Channel: ${session.channelId}\n\nShare Link:\n${session.shareableLink}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _liveStreamingService.stopStream();
                if (!mounted) return;
                Navigator.pop(context);
                _showSnack('Live stream ended');
              },
              child: const Text('Stop Stream'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Streaming failed: $e');
    }
  }

  Future<void> _showVolunteerNetwork() async {
    _showLoadingDialog('Finding nearby volunteers...');

    final location = await _locationService.getCurrentLocation();
    if (!mounted) return;

    if (location == null) {
      Navigator.pop(context);
      _showSnack('Unable to get location for volunteer search');
      return;
    }

    final volunteers = await _volunteerService.findNearbyVolunteers(
      latitude: location.latitude,
      longitude: location.longitude,
    );

    if (!mounted) return;
    Navigator.pop(context);

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nearby Verified Volunteers'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: volunteers.length,
            itemBuilder: (_, index) {
              final volunteer = volunteers[index];
              return ListTile(
                title: Text(volunteer.name),
                subtitle: Text(
                  '${volunteer.distanceKm} km • Rating ${volunteer.rating}\n${volunteer.skills.join(', ')}',
                ),
                isThreeLine: true,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

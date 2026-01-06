/// Revolutionary Features Screen
/// Hub for AI-powered and advanced safety features
import 'package:flutter/material.dart';
import '../services/ai_danger_prediction_service.dart';
import '../services/distress_voice_analysis_service.dart';

class RevolutionaryFeaturesScreen extends StatelessWidget {
  const RevolutionaryFeaturesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI-Powered Features'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildFeatureCard(
            context,
            icon: Icons.psychology,
            title: 'AI Danger Prediction',
            subtitle: 'Analyze area safety using ML',
            color: Colors.purple,
            onTap: () => _showDangerPrediction(context),
          ),
          _buildFeatureCard(
            context,
            icon: Icons.mic,
            title: 'Voice Distress Detection',
            subtitle: 'Detect distress keywords in voice',
            color: Colors.orange,
            onTap: () => _showVoiceAnalysis(context),
          ),
          _buildFeatureCard(
            context,
            icon: Icons.face,
            title: 'Face Recognition',
            subtitle: 'ML-based face detection',
            color: Colors.blue,
            onTap: () => _showFaceRecognition(context),
          ),
          _buildFeatureCard(
            context,
            icon: Icons.phone_callback,
            title: 'Fake Call Generator',
            subtitle: 'Simulate incoming emergency call',
            color: Colors.green,
            onTap: () => _showFakeCall(context),
          ),
          _buildFeatureCard(
            context,
            icon: Icons.route,
            title: 'Safe Routes',
            subtitle: 'Find safest path to destination',
            color: Colors.teal,
            onTap: () => _showSafeRoutes(context),
          ),
          _buildFeatureCard(
            context,
            icon: Icons.camera_alt,
            title: 'Evidence Capture',
            subtitle: 'Auto-capture audio/photo evidence',
            color: Colors.red,
            onTap: () => _showEvidenceCapture(context),
          ),
          _buildFeatureCard(
            context,
            icon: Icons.video_call,
            title: 'Live Video Streaming',
            subtitle: 'Stream to guardians (Agora)',
            color: Colors.indigo,
            onTap: () => _showLiveStreaming(context),
          ),
          _buildFeatureCard(
            context,
            icon: Icons.group,
            title: 'Volunteer Network',
            subtitle: 'Connect with safety volunteers',
            color: Colors.pink,
            onTap: () => _showVolunteerNetwork(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showDangerPrediction(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final service = AiDangerPredictionService();
    final prediction = await service.predictDanger(
      latitude: 28.7041,
      longitude: 77.1025,
    );

    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI Danger Prediction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Risk Level: ${prediction.riskLevel}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Score: ${prediction.dangerScore}/100'),
            const SizedBox(height: 8),
            Text(prediction.recommendation),
            const SizedBox(height: 8),
            const Text('Factors:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...prediction.factors.map((f) => Text('• $f')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showVoiceAnalysis(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Distress Detection'),
        content: const Text(
          'This feature uses ML Kit to detect distress keywords like "help", "emergency", "danger" in real-time voice input.\n\nKeywords: help, emergency, danger, scared, attack, stop, police, fire',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Start Listening')),
        ],
      ),
    );
  }

  void _showFaceRecognition(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Face Recognition'),
        content: const Text(
          'ML Kit face detection to:\n• Detect multiple faces (crowding)\n• Analyze facial expressions\n• Detect distress indicators\n\nCan be extended with custom TFLite models.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showFakeCall(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fake Call Generator'),
        content: const Text('Simulate an incoming call to help you exit uncomfortable situations safely.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fake call initiated...')),
              );
            },
            child: const Text('Start Fake Call'),
          ),
        ],
      ),
    );
  }

  void _showSafeRoutes(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Safe Routes'),
        content: const Text(
          'Get AI-recommended safe routes based on:\n• Lighting conditions\n• Crowd density\n• Historical safety data\n• CCTV coverage\n• Police stations nearby',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showEvidenceCapture(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Evidence Capture'),
        content: const Text(
          'Automatically capture:\n• Audio recordings\n• Photos\n• Video clips\n\nStored securely and sent to guardians.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showLiveStreaming(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Live Video Streaming'),
        content: const Text(
          'Stream live video to guardians using Agora RTC Engine.\n\nRequires Agora App ID configuration.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showVolunteerNetwork(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Volunteer Network'),
        content: const Text(
          'Connect with verified safety volunteers in your area who can provide immediate assistance.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}

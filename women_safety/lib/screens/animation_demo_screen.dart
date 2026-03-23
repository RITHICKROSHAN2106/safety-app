import 'package:flutter/material.dart';
import '../widgets/sos_alert_animation.dart';
import '../widgets/custom_loading.dart';
import '../widgets/success_dialog.dart';
import '../widgets/error_widget.dart';
import '../widgets/empty_state.dart';

/// Demo screen showing all Lottie animation widgets
/// Use this to test animations after downloading Lottie JSON files
class AnimationDemoScreen extends StatefulWidget {
  const AnimationDemoScreen({super.key});

  @override
  State<AnimationDemoScreen> createState() => _AnimationDemoScreenState();
}

class _AnimationDemoScreenState extends State<AnimationDemoScreen> {
  bool _isLoading = false;
  bool _showError = false;
  bool _showEmpty = false;
  bool _showSOSAlert = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Demo'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              'Lottie Animation Widgets',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Test all animation widgets here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Demo Buttons
            _buildDemoButton(
              context,
              icon: Icons.warning_amber_rounded,
              label: 'Show SOS Alert Animation',
              color: Colors.red,
              onPressed: () {
                setState(() {
                  _showSOSAlert = !_showSOSAlert;
                });
              },
            ),
            const SizedBox(height: 12),

            _buildDemoButton(
              context,
              icon: Icons.hourglass_empty,
              label: 'Show Loading Animation',
              color: Colors.blue,
              onPressed: () {
                setState(() {
                  _isLoading = !_isLoading;
                });
              },
            ),
            const SizedBox(height: 12),

            _buildDemoButton(
              context,
              icon: Icons.check_circle,
              label: 'Show Success Dialog',
              color: Colors.green,
              onPressed: () {
                SuccessDialog.show(
                  context,
                  title: 'Success!',
                  message: 'Operation completed successfully',
                );
              },
            ),
            const SizedBox(height: 12),

            _buildDemoButton(
              context,
              icon: Icons.error_outline,
              label: 'Show Error Widget',
              color: Colors.orange,
              onPressed: () {
                setState(() {
                  _showError = !_showError;
                });
              },
            ),
            const SizedBox(height: 12),

            _buildDemoButton(
              context,
              icon: Icons.inbox_outlined,
              label: 'Show Empty State',
              color: Colors.purple,
              onPressed: () {
                setState(() {
                  _showEmpty = !_showEmpty;
                });
              },
            ),

            const SizedBox(height: 32),

            // Animation Display Area
            Container(
              height: 400,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: _buildAnimationDisplay(),
            ),

            const SizedBox(height: 16),

            // Info Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Instructions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Download Lottie JSON files from LottieFiles.com\n'
                      '2. Place them in assets/lottie/ directory\n'
                      '3. Run: flutter pub get\n'
                      '4. Tap buttons above to test animations\n\n'
                      'If animations don\'t show, fallback icons will display.',
                      style: TextStyle(
                        color: Colors.blue[800],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildAnimationDisplay() {
    if (_showSOSAlert) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SOSAlertAnimation(size: 200),
            SizedBox(height: 16),
            Text(
              'SOS Alert Animation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CustomLoading(
          message: 'Loading data...',
          size: 150,
        ),
      );
    }

    if (_showError) {
      return CustomErrorWidget(
        title: 'Error Occurred',
        message: 'Something went wrong. Please try again.',
        actionLabel: 'Retry',
        onRetry: () {
          setState(() {
            _showError = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Retrying...')),
          );
        },
      );
    }

    if (_showEmpty) {
      return EmptyState(
        title: 'No Items Found',
        subtitle: 'Your list is empty. Add some items to get started.',
        actionLabel: 'Add Item',
        onAction: () {
          setState(() {
            _showEmpty = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adding item...')),
          );
        },
      );
    }

    // Default state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Tap a button above',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'to see animations',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

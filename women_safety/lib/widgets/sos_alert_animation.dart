import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Animated SOS alert indicator with pulsing effect
/// Shows during active emergency alerts
class SOSAlertAnimation extends StatelessWidget {
  final double size;
  final bool animate;

  const SOSAlertAnimation({
    super.key,
    this.size = 200,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottie/sos_alert.json',
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: true,
      animate: animate,
      // Fallback to circular progress indicator if file not found
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withAlpha((255 * 0.2).round()),
          ),
          child: Center(
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: size * 0.5,
            ),
          ),
        );
      },
    );
  }
}

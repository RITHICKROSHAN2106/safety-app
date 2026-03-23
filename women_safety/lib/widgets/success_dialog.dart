import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Success dialog with animated checkmark
/// Auto-dismisses after animation completes
class SuccessDialog extends StatelessWidget {
  final String title;
  final String? message;
  final VoidCallback? onDismiss;
  final Duration duration;

  const SuccessDialog({
    super.key,
    required this.title,
    this.message,
    this.onDismiss,
    this.duration = const Duration(seconds: 2),
  });

  /// Show success dialog with auto-dismiss
  static Future<void> show(
    BuildContext context, {
    required String title,
    String? message,
    VoidCallback? onDismiss,
    Duration duration = const Duration(seconds: 2),
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessDialog(
        title: title,
        message: message,
        onDismiss: onDismiss,
        duration: duration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Auto-dismiss after duration
    Future.delayed(duration, () {
      if (context.mounted) {
        Navigator.of(context).pop();
        onDismiss?.call();
      }
    });

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/lottie/success.json',
              width: 150,
              height: 150,
              repeat: false,
              // Fallback to icon
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withAlpha((255 * 0.2).round()),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 80,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

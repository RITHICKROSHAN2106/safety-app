import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Custom loading widget with Lottie animation
/// Used for API calls, data fetching, and processing states
class CustomLoading extends StatelessWidget {
  final String? message;
  final double size;

  const CustomLoading({
    super.key,
    this.message,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            'assets/lottie/loading.json',
            width: size,
            height: size,
            fit: BoxFit.contain,
            // Fallback to CircularProgressIndicator
            errorBuilder: (context, error, stackTrace) {
              return SizedBox(
                width: size * 0.5,
                height: size * 0.5,
                child: const CircularProgressIndicator(),
              );
            },
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Full screen loading overlay
class LoadingOverlay extends StatelessWidget {
  final String? message;

  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: CustomLoading(message: message),
    );
  }
}

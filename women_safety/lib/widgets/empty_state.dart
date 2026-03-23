import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Empty state widget with Lottie animation
/// Used when lists or data sets are empty
class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? fallbackIcon;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/lottie/empty_state.json',
              width: 200,
              height: 200,
              // Fallback to icon
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  fallbackIcon ?? Icons.inbox_outlined,
                  size: 120,
                  color: Colors.grey[400],
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Specialized empty state for contact lists
class EmptyContactsState extends StatelessWidget {
  final VoidCallback? onAddContact;

  const EmptyContactsState({super.key, this.onAddContact});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: 'No Emergency Contacts',
      subtitle:
          'Add trusted contacts who will be notified during emergencies',
      actionLabel: 'Add Contact',
      onAction: onAddContact,
      fallbackIcon: Icons.contacts_outlined,
    );
  }
}

/// Specialized empty state for alert history
class EmptyAlertsState extends StatelessWidget {
  const EmptyAlertsState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      title: 'No SOS Alerts',
      subtitle: 'Your emergency alert history will appear here',
      fallbackIcon: Icons.notification_important_outlined,
    );
  }
}

/// Specialized empty state for location history
class EmptyLocationHistoryState extends StatelessWidget {
  const EmptyLocationHistoryState({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      title: 'No Location History',
      subtitle: 'Your location tracking history will appear here',
      fallbackIcon: Icons.location_on_outlined,
    );
  }
}

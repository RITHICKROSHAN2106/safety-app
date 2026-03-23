import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../bloc/auth/auth_cubit.dart';
import '../bloc/theme/theme_cubit.dart';
import '../models/guardian.dart';
import '../services/sms_service.dart';
import 'sos_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  static const routeName = '/settings';

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _requestPermission(
    BuildContext context,
    Permission permission,
    String label,
  ) async {
    final status = await permission.request();
    if (!context.mounted) return;

    switch (status) {
      case PermissionStatus.granted:
        _showMessage(context, '$label enabled.');
        break;
      case PermissionStatus.denied:
        _showMessage(context, '$label denied. You can allow it from system settings.');
        break;
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.restricted:
      case PermissionStatus.limited:
      case PermissionStatus.provisional:
        _showMessage(context, '$label restricted. Open system settings to manage permissions.');
        break;
    }
  }

  Future<void> _openSystemSettings(BuildContext context) async {
    final opened = await openAppSettings();
    if (!context.mounted) return;
    if (!opened) {
      _showMessage(context, 'Unable to open system settings. Please open them manually.');
    }
  }

  void _showSafetyChecklist(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Personal safety checklist',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                const Text('Run through these essentials regularly:'),
                const SizedBox(height: 16),
                const _ChecklistItem('Keep at least two guardians up to date with your phone number.'),
                const _ChecklistItem('Ensure GPS and mobile data stay enabled when travelling alone.'),
                const _ChecklistItem('Carry a charged power bank and share battery saver tips with guardians.'),
                const _ChecklistItem('Agree on a safety keyword with your guardians for discreet communication.'),
                const _ChecklistItem('Review local emergency numbers and routes to the nearest safe locations.'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Got it'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _testSmsAlert(BuildContext context) async {
    final authState = context.read<AuthCubit>().state;
    final user = authState.user;
    if (user == null) {
      _showMessage(context, 'Sign in to send test alerts.');
      return;
    }

    final guardians = await _loadGuardians(user.uid);
    if (!context.mounted) return;

    final messageController = TextEditingController(
      text: 'This is a test alert from the Women Safety app. You can ignore this message.',
    );
    final otherNumberController = TextEditingController(text: user.phoneNumber ?? '');
    final selections = <String>{};

    final result = await showDialog<(List<String>, String)?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Send test SMS alert'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (guardians.isEmpty)
                        const Text('Add guardians to send them a test alert. You can still send to a custom number below.'),
                      if (guardians.isNotEmpty) ...[
                        const Text('Choose guardians'),
                        ...guardians.map(
                          (guardian) => CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: selections.contains(guardian.phone),
                            title: Text(guardian.name),
                            subtitle: Text(guardian.phone),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  selections.add(guardian.phone);
                                } else {
                                  selections.remove(guardian.phone);
                                }
                              });
                            },
                          ),
                        ),
                        const Divider(height: 24),
                      ],
                      const Text('Send to another number'),
                      TextFormField(
                        controller: otherNumberController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Enter phone number',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Message'),
                      TextFormField(
                        controller: messageController,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final recipients = [...selections];
                final manual = otherNumberController.text.trim();
                if (manual.isNotEmpty) {
                  recipients.add(manual);
                }
                if (recipients.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Select or enter at least one number.')),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop((recipients, messageController.text.trim()));
              },
              child: const Text('Send test alert'),
            ),
          ],
        );
      },
    );

    if (result == null) {
      return;
    }

    final (recipients, message) = result;
    final smsPermission = await Permission.sms.request();
    if (!smsPermission.isGranted) {
      if (!context.mounted) return;
      _showMessage(context, 'SMS permission is required to send alerts.');
      return;
    }
    final success = await SmsService.sendCustomSms(
      phoneNumbers: recipients,
      message: message,
    );

    if (!context.mounted) return;
    _showMessage(context, success ? 'Test alert sent successfully.' : 'Unable to send SMS. Check permissions.');
  }

  Future<List<Guardian>> _loadGuardians(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final ids = (userDoc.data()?['emergencyContactIds'] as List?)?.map((e) => '$e').toList() ?? <String>[];
      if (ids.isEmpty) return <Guardian>[];

      final futures = ids.map((id) async {
        final doc = await FirebaseFirestore.instance.collection('guardians').doc(id).get();
        if (!doc.exists) return null;
        return Guardian.fromJson({'id': doc.id, ...doc.data()!});
      });
      final results = await Future.wait(futures);
      return results.whereType<Guardian>().toList();
    } catch (_) {
      return <Guardian>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeCubit>().state;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          title: 'Appearance',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Theme mode'),
              const SizedBox(height: 12),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.brightness_auto_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode_outlined),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode_outlined),
                  ),
                ],
                selected: {mode},
                onSelectionChanged: (selection) {
                  context.read<ThemeCubit>().setMode(selection.first);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          title: 'Emergency tools',
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.sos_outlined, color: Colors.redAccent),
                title: const Text('Review SOS setup'),
                subtitle: const Text('Check your guardians and test alert workflow'),
                onTap: () => Navigator.of(context).pushNamed(SosScreen.routeName),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.sms_outlined),
                title: const Text('Test SMS alert'),
                subtitle: const Text('Send yourself a sample alert message'),
                onTap: () => _testSmsAlert(context),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.auto_awesome, color: Colors.deepPurple),
                title: const Text('🚀 Revolutionary Features'),
                subtitle: const Text('8 AI-powered advanced safety features'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                onTap: () => Navigator.of(context).pushNamed('/revolutionary-features'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          title: 'Permissions & privacy',
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.location_on_outlined),
                title: const Text('Location access'),
                subtitle: const Text('Required to share your live coordinates during SOS'),
                onTap: () => _requestPermission(context, Permission.locationWhenInUse, 'Location access'),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_active_outlined),
                title: const Text('Notifications'),
                subtitle: const Text('Allow alerts and reminders'),
                onTap: () => _requestPermission(context, Permission.notification, 'Notifications'),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.sms_failed_outlined),
                title: const Text('SMS permission'),
                subtitle: const Text('Allow sending text messages to guardians'),
                onTap: () => _requestPermission(context, Permission.sms, 'SMS permission'),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.settings_applications_outlined),
                title: const Text('Open system settings'),
                subtitle: const Text('Manage permissions manually'),
                onTap: () => _openSystemSettings(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SettingsCard(
          title: 'Support',
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.help_outline),
                title: const Text('Safety checklist'),
                subtitle: const Text('Tips to stay prepared for emergencies'),
                onTap: () => _showSafetyChecklist(context),
              ),
              const Divider(height: 1),
              const AboutListTile(
                dense: true,
                icon: Icon(Icons.info_outline),
                applicationName: 'Women Safety',
                applicationVersion: 'v1.0.0',
                applicationLegalese: 'Stay safe. Built with ❤️ using Flutter.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

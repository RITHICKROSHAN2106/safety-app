import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../bloc/sos/sos_cubit.dart';
import '../bloc/auth/auth_cubit.dart';
import '../models/guardian.dart';
import '../widgets/custom_loading.dart';
import '../widgets/empty_state.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});
  static const routeName = '/sos';

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  List<Guardian> _emergencyContacts = [];
  bool _isLoadingContacts = true;

  @override
  void initState() {
    super.initState();
    _loadEmergencyContacts();
  }

  /// Load emergency contacts from Firestore
  Future<void> _loadEmergencyContacts() async {
    try {
      final authState = context.read<AuthCubit>().state;
      final userId = authState.user?.uid;

      if (userId == null) {
        debugPrint('❌ No user logged in');
        setState(() => _isLoadingContacts = false);
        return;
      }

      debugPrint('📥 Loading emergency contacts for user: $userId');

      // Get user's emergency contact IDs from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        debugPrint('⚠️  User document not found in Firestore');
        if (!mounted) return;
        setState(() => _isLoadingContacts = false);
        return;
      }

      final userData = userDoc.data();
      final contactIds = (userData?['emergencyContactIds'] as List<dynamic>?)
              ?.cast<String>() ??
          [];

      if (contactIds.isEmpty) {
        debugPrint('⚠️  No emergency contacts configured');
        if (!mounted) return;
        setState(() => _isLoadingContacts = false);
        return;
      }

      // Fetch each contact from Firestore
      final List<Guardian> contacts = [];
      for (final contactId in contactIds) {
        final contactDoc = await FirebaseFirestore.instance
            .collection('guardians')
            .doc(contactId)
            .get();

        if (contactDoc.exists) {
          contacts.add(Guardian.fromJson({
            'id': contactDoc.id,
            ...contactDoc.data()!,
          }));
        }
      }

      debugPrint('✅ Loaded ${contacts.length} emergency contacts');

      if (!mounted) return;
      setState(() {
        _emergencyContacts = contacts;
        _isLoadingContacts = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading emergency contacts: $e');
      if (!mounted) return;
      setState(() => _isLoadingContacts = false);
    }
  }

  Future<void> _triggerSOS(String triggerType) async {
    final authState = context.read<AuthCubit>().state;
    final user = authState.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login first to use SOS'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 🔄 RELOAD contacts from Firestore BEFORE triggering SOS
    debugPrint('🔄 Reloading emergency contacts from Firestore...');
    await _loadEmergencyContacts();

    if (!mounted) return;

    if (_emergencyContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add emergency contacts first'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    debugPrint('🚨 Triggering SOS - Type: $triggerType');
    debugPrint('👤 User: ${user.displayName ?? user.email}');
    debugPrint('📞 Emergency Contacts: ${_emergencyContacts.length}');
    
    // Print each contact for verification
    for (int i = 0; i < _emergencyContacts.length; i++) {
      final contact = _emergencyContacts[i];
      debugPrint('   ${i + 1}. ${contact.name} - ${contact.phone} ${contact.isPrimary ? "(PRIMARY)" : ""}');
    }

    context.read<SosCubit>().triggerSOS(
          user: user,
          emergencyContacts: _emergencyContacts,
          triggerType: triggerType,
          recordVideo: true,
          makeCall: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState.user;

    // Show login prompt if user not authenticated
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Emergency SOS'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'Please Login',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'You need to be logged in to use SOS features',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                icon: const Icon(Icons.login),
                label: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    // Main SOS screen with real data
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEmergencyContacts,
            tooltip: 'Refresh Contacts',
          ),
        ],
      ),
      body: _isLoadingContacts
          ? const CustomLoading(message: 'Loading emergency contacts...')
          : BlocConsumer<SosCubit, SOSState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state.isTriggered && !state.isLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🚨 SOS Alert Sent! Emergency contacts notified.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Card
                Card(
                  color: state.isTriggered ? Colors.red.shade50 : Colors.grey.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          state.isTriggered ? Icons.warning_amber : Icons.shield,
                          size: 48,
                          color: state.isTriggered ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.isTriggered ? 'SOS ACTIVE' : 'Ready',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: state.isTriggered ? Colors.red : Colors.grey,
                          ),
                        ),
                        if (state.activeAlert != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Triggered: ${state.activeAlert!.timestamp}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Main SOS Button
                SizedBox(
                  height: 200,
                  child: ElevatedButton(
                    onPressed: state.isLoading
                        ? null
                        : () => _triggerSOS('BUTTON'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(40),
                    ),
                    child: state.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emergency, size: 64),
                              SizedBox(height: 8),
                              Text(
                                'SOS',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Press and hold to trigger emergency SOS',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // Emergency Contacts Card
                _emergencyContacts.isEmpty
                    ? EmptyContactsState(
                        onAddContact: () {
                          // Navigate to add contact screen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please add emergency contacts in Profile > Emergency Contacts',
                              ),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                      )
                    : Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Emergency Contacts',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      '${_emergencyContacts.length} contact${_emergencyContacts.length != 1 ? 's' : ''}',
                                    ),
                                    backgroundColor: Colors.green.shade100,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ..._emergencyContacts.map((contact) => ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: contact.isPrimary
                                          ? Colors.red
                                          : Colors.grey,
                                      child: Text(
                                        contact.name[0].toUpperCase(),
                                        style:
                                            const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    title: Text(contact.name),
                                    subtitle: Text(contact.phone),
                                    trailing: contact.isPrimary
                                        ? const Chip(
                                            label: Text('Primary'),
                                            backgroundColor: Colors.red,
                                            labelStyle: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                          )
                                        : null,
                                  )),
                            ],
                          ),
                        ),
                      ),
                const SizedBox(height: 16),

                // Cancel Button (if SOS is active)
                if (state.isTriggered && state.activeAlert != null)
                  OutlinedButton.icon(
                    onPressed: state.isLoading
                        ? null
                        : () => context.read<SosCubit>().cancelSOS(),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel False Alarm'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),

                const SizedBox(height: 16),

                // What happens when you trigger SOS
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'What happens when you trigger SOS?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.location_on, 'Your current location is captured'),
                        _buildInfoRow(Icons.videocam, '30-second video recording starts'),
                        _buildInfoRow(Icons.sms, 'SMS sent to all emergency contacts'),
                        _buildInfoRow(Icons.phone, 'Call made to primary contact'),
                        _buildInfoRow(Icons.message, 'WhatsApp messages sent'),
                        _buildInfoRow(Icons.email, 'Email alerts sent'),
                        _buildInfoRow(Icons.cloud_upload, 'Data uploaded to server'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

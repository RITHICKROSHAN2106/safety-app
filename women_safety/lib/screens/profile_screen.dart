import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../bloc/auth/auth_cubit.dart';
import '../models/app_user.dart';
import '../models/guardian.dart';
import '../services/global_sos_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  static const routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<List<Guardian>>? _contactsFuture;
  String? _loadedUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authState = context.read<AuthCubit>().state;
    final user = authState.user;
    if (user != null && _loadedUserId != user.uid) {
      _scheduleContactsLoad(user);
    }
  }

  void _scheduleContactsLoad(AppUser user) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _primeContactsForUser(user);
    });
  }

  void _primeContactsForUser(AppUser user) {
    setState(() {
      _loadedUserId = user.uid;
      _contactsFuture = _fetchContacts(user.uid);
    });
  }

  Future<List<Guardian>> _fetchContacts(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final contactIds = (userDoc.data()?['emergencyContactIds'] as List?)
            ?.map((dynamic e) => '$e')
            .toList() ??
        <String>[];

    if (contactIds.isEmpty) {
      return <Guardian>[];
    }

    final futures = contactIds.map((id) async {
      final doc = await FirebaseFirestore.instance
          .collection('guardians')
          .doc(id)
          .get();
      if (!doc.exists) return null;
      return Guardian.fromJson({'id': doc.id, ...doc.data()!});
    });

    final contacts = await Future.wait(futures);
    return contacts.whereType<Guardian>().toList()
      ..sort((a, b) => a.isPrimary == b.isPrimary
          ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
          : (a.isPrimary ? -1 : 1));
  }

  Future<void> _refreshContacts(String userId) async {
    final future = _fetchContacts(userId);
    setState(() {
      _contactsFuture = future;
    });
    await future;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addGuardian(AppUser user) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final relationController = TextEditingController(text: 'Friend');
    bool isPrimary = false;

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Guardian>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add guardian'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Enter guardian name' : null,
                    ),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone number'),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Enter phone number' : null,
                    ),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email (optional)'),
                    ),
                    TextFormField(
                      controller: relationController,
                      decoration: const InputDecoration(labelText: 'Relationship'),
                    ),
                    const SizedBox(height: 12),
                    StatefulBuilder(
                      builder: (context, setDialogState) {
                        return SwitchListTile.adaptive(
                          value: isPrimary,
                          title: const Text('Primary guardian'),
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) {
                            setDialogState(() => isPrimary = value);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(
                    Guardian(
                      id: '',
                      name: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      email: emailController.text.trim().isEmpty
                          ? null
                          : emailController.text.trim(),
                      relationship: relationController.text.trim().isEmpty
                          ? 'Friend'
                          : relationController.text.trim(),
                      isPrimary: isPrimary,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    await _saveGuardian(user, result);
  }

  Future<void> _saveGuardian(AppUser user, Guardian guardian) async {
    try {
      final doc = FirebaseFirestore.instance.collection('guardians').doc();
      await doc.set(
        guardian
            .copyWith(id: doc.id, ownerId: user.uid)
            .toJson(),
      );

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        final ids = <String>{};
        if (snapshot.exists) {
          final data = snapshot.data() ?? <String, dynamic>{};
          ids.addAll(
            (data['emergencyContactIds'] as List?)
                    ?.map((dynamic e) => '$e')
                    .toList() ??
                <String>[],
          );
        }
        ids.add(doc.id);
        if (snapshot.exists) {
          transaction.update(userRef, {'emergencyContactIds': ids.toList()});
        } else {
          transaction.set(
            userRef,
            {'emergencyContactIds': ids.toList()},
            SetOptions(merge: true),
          );
        }
      });

      if (!mounted) return;
      _showSnack('Guardian added successfully');
      await context.read<AuthCubit>().refreshProfile();
      if (!mounted) return;
      _primeContactsForUser(context.read<AuthCubit>().state.user!);
    } catch (e) {
      _showSnack('Failed to add guardian: $e');
    }
  }

  Future<void> _removeGuardian(AppUser user, Guardian guardian) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove guardian'),
          content: Text('Remove ${guardian.name} from your guardian list?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('guardians').doc(guardian.id).delete();
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) {
          transaction.set(
            userRef,
            {'emergencyContactIds': <String>[]},
            SetOptions(merge: true),
          );
          return;
        }

        final data = snapshot.data() ?? <String, dynamic>{};
        final ids = <String>{
          ...(data['emergencyContactIds'] as List?)
                  ?.map((dynamic e) => '$e')
                  .toList() ??
              <String>[],
        };
        ids.remove(guardian.id);
        transaction.update(userRef, {'emergencyContactIds': ids.toList()});
      });

      if (!mounted) return;
      _showSnack('Guardian removed');
      await context.read<AuthCubit>().refreshProfile();
      if (!mounted) return;
      _primeContactsForUser(context.read<AuthCubit>().state.user!);
    } catch (e) {
      _showSnack('Failed to remove guardian: $e');
    }
  }

  Future<void> _setPrimaryGuardian(
    AppUser user,
    Guardian selected,
    List<Guardian> contacts,
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final guardian in contacts) {
        final ref = FirebaseFirestore.instance.collection('guardians').doc(guardian.id);
        batch.update(ref, {'isPrimary': guardian.id == selected.id});
      }
      await batch.commit();

      if (!mounted) return;
      _showSnack('${selected.name} is now your primary guardian');
      await context.read<AuthCubit>().refreshProfile();
      if (!mounted) return;
      _primeContactsForUser(context.read<AuthCubit>().state.user!);
    } catch (e) {
      _showSnack('Unable to update primary guardian: $e');
    }
  }

  Future<void> _openManageGuardians(AppUser user) async {
  final contactsFuture = _contactsFuture ?? _fetchContacts(user.uid);
  final contacts = await contactsFuture;

    if (!mounted) return;

    if (contacts.isEmpty) {
      _showSnack('No guardians yet. Add one to get started.');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Manage guardians',
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                    IconButton(
                      tooltip: 'Add guardian',
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _addGuardian(user);
                      },
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Tap a guardian to set as primary or remove them.'),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: contacts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final guardian = contacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(guardian.name.characters.first.toUpperCase()),
                        ),
                        title: Text(guardian.name),
                        subtitle: Text(
                          [
                            guardian.relationship,
                            guardian.phone,
                            if (guardian.email != null && guardian.email!.isNotEmpty)
                              guardian.email!,
                            if (guardian.isPrimary) 'Primary guardian',
                          ].where((segment) => segment.isNotEmpty).join(' • '),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            Navigator.of(sheetContext).pop();
                            if (value == 'primary') {
                              _setPrimaryGuardian(user, guardian, contacts);
                            } else if (value == 'remove') {
                              _removeGuardian(user, guardian);
                            }
                          },
                          itemBuilder: (context) => [
                            if (!guardian.isPrimary)
                              const PopupMenuItem(
                                value: 'primary',
                                child: Text('Set as primary'),
                              ),
                            const PopupMenuItem(
                              value: 'remove',
                              child: Text('Remove guardian'),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          if (!guardian.isPrimary) {
                            _setPrimaryGuardian(user, guardian, contacts);
                          } else {
                            _showSnack('${guardian.name} is already primary');
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWidgetInstructions(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚨 Panic Widget Setup'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Emergency SOS Widget to Home Screen:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('• Long press on empty space on home screen'),
              const Text('• Select "Widgets" from menu'),
              const Text('• Find "Panic SOS" or "Women Safety"'),
              const Text('• Drag widget to home screen'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap widget for instant SOS',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(AppUser user) async {
    final authCubit = context.read<AuthCubit>();
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.displayName ?? user.name);
    final phoneController = TextEditingController(text: user.phoneNumber ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit profile'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone number'),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Save changes'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final displayName = nameController.text.trim();
    final phone = phoneController.text.trim();
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.updateDisplayName(displayName);
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          'displayName': displayName,
          'phoneNumber': phone.isEmpty ? null : phone,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await authCubit.refreshProfile();
      if (!context.mounted) return;
      _showSnack('Profile updated');
    } catch (e) {
      if (!context.mounted) return;
      _showSnack('Failed to update profile: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState.user;

    if (authState.loading && !authState.initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle_outlined, size: 96, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('You are not signed in. Please login to view your profile.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/login'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadedUserId != user.uid && _contactsFuture == null) {
      _scheduleContactsLoad(user);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit profile',
            onPressed: () => _editProfile(user),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshContacts(user.uid),
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _ProfileHeader(user: user),
            const SizedBox(height: 16),
            _ProfileStats(
              contactsFuture: _contactsFuture,
              onAddPressed: () => _addGuardian(user),
              onManagePressed: () => _openManageGuardians(user),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Guardian>>(
              future: _contactsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _SectionCard(
                    title: 'Emergency Contacts',
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _SectionCard(
                    title: 'Emergency Contacts',
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Unable to load your contacts right now.',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(snapshot.error.toString()),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => _refreshContacts(user.uid),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final contacts = snapshot.data ?? <Guardian>[];
                if (contacts.isEmpty) {
                    return _SectionCard(
                      title: 'Emergency Contacts',
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'No guardians added yet',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add at least one trusted guardian so SOS alerts reach them instantly.',
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => _addGuardian(user),
                              icon: const Icon(Icons.group_add_outlined),
                              label: const Text('Add guardian'),
                            ),
                          ],
                        ),
                      ),
                    );
                }

                return _SectionCard(
                  title: 'Emergency Contacts',
                  trailing: TextButton.icon(
                    onPressed: () => _addGuardian(user),
                    icon: const Icon(Icons.group_outlined),
                    label: const Text('Add guardian'),
                  ),
                  child: Column(
                    children: [
                      for (final contact in contacts)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Text(contact.name.isNotEmpty
                                ? contact.name.characters.first.toUpperCase()
                                : '?'),
                          ),
                          title: Text(contact.name),
                          subtitle: () {
                            final details = <String>[
                              if (contact.relationship.isNotEmpty)
                                contact.relationship,
                              if (contact.phone.isNotEmpty) contact.phone,
                              if (contact.email != null && contact.email!.isNotEmpty)
                                contact.email!,
                              if (contact.isPrimary) 'Primary guardian',
                            ];
                            return Text(details.join(' • '));
                          }(),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'primary') {
                                _setPrimaryGuardian(user, contact, contacts);
                              } else if (value == 'remove') {
                                _removeGuardian(user, contact);
                              }
                            },
                            itemBuilder: (context) => [
                              if (!contact.isPrimary)
                                const PopupMenuItem(
                                  value: 'primary',
                                  child: Text('Set as primary'),
                                ),
                              const PopupMenuItem(
                                value: 'remove',
                                child: Text('Remove guardian'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Quick Actions',
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.share_location, color: Colors.green),
                    title: const Text('Share My Location'),
                    subtitle: const Text('Send location to emergency contacts'),
                    onTap: () => Navigator.pushNamed(context, '/map'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.rocket_launch, color: Colors.deepPurple),
                    title: const Text('Revolutionary Features'),
                    subtitle: const Text('Access 8 advanced safety features'),
                    onTap: () => Navigator.pushNamed(context, '/revolutionary-features'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.widgets, color: Colors.red),
                    title: const Text('Panic Widget Setup'),
                    subtitle: const Text('Add emergency widget to home screen'),
                    onTap: () => _showWidgetInstructions(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: 'Account',
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.lock_reset),
                    title: const Text('Reset password'),
                    subtitle: const Text('Send a password reset email'),
                    onTap: () async {
                      final email = user.email;
                      if (email == null) {
                        _showSnack('Your account has no email address to reset.');
                        return;
                      }
                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                        if (!mounted) return;
                        _showSnack('Password reset email sent to $email');
                      } catch (e) {
                        _showSnack('Failed to send reset email: $e');
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign out'),
                    onTap: () async {
                      final authCubit = context.read<AuthCubit>();
                      GlobalSOSManager.teardown();
                      await authCubit.signOut();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signed out')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      title: 'Your Details',
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: theme.colorScheme.primary.withAlpha((255 * 0.15).round()),
            child: Text(
              user.name.characters.first.toUpperCase(),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                if (user.email != null)
                  Text(user.email!, style: theme.textTheme.bodyMedium),
                if (user.phoneNumber != null)
                  Text(user.phoneNumber!, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({
    required this.contactsFuture,
    required this.onManagePressed,
    required this.onAddPressed,
  });

  final Future<List<Guardian>>? contactsFuture;
  final VoidCallback onManagePressed;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Safety Snapshot',
      trailing: Wrap(
        spacing: 8,
        children: [
          TextButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('Add'),
          ),
          TextButton.icon(
            onPressed: onManagePressed,
            icon: const Icon(Icons.settings_input_component_outlined),
            label: const Text('Configure'),
          ),
        ],
      ),
      child: FutureBuilder<List<Guardian>>(
        future: contactsFuture,
        builder: (context, snapshot) {
          final total = snapshot.data?.length ?? 0;
          final primary = snapshot.data?.where((g) => g.isPrimary).length ?? 0;

          return Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Guardians',
                  value: '$total',
                  icon: Icons.diversity_1_outlined,
                ),
              ),
              Expanded(
                child: _StatTile(
                  label: 'Primary',
                  value: '$primary',
                  icon: Icons.star_border,
                ),
              ),
              Expanded(
                child: _StatTile(
                  label: 'Status',
                  value: total > 0 ? 'Ready' : 'Incomplete',
                  icon: total > 0 ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                  highlight: total > 0,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = highlight ? theme.colorScheme.primary : theme.iconTheme.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(color: color),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

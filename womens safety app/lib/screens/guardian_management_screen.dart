/// Guardian Management Screen
/// Add, edit, and manage emergency contacts
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/guardian_cubit.dart';
import '../cubits/auth_cubit.dart';
import '../models/guardian_model.dart';

class GuardianManagementScreen extends StatefulWidget {
  const GuardianManagementScreen({Key? key}) : super(key: key);

  @override
  State<GuardianManagementScreen> createState() => _GuardianManagementScreenState();
}

class _GuardianManagementScreenState extends State<GuardianManagementScreen> {
  @override
  void initState() {
    super.initState();
    _loadGuardians();
  }

  void _loadGuardians() {
    final user = context.read<AuthCubit>().getCurrentUser();
    if (user != null) {
      context.read<GuardianCubit>().loadGuardians(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardians'),
      ),
      body: BlocBuilder<GuardianCubit, GuardianState>(
        builder: (context, state) {
          if (state is GuardianLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is GuardianLoaded) {
            if (state.guardians.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: state.guardians.length,
              itemBuilder: (context, index) {
                return _buildGuardianCard(state.guardians[index]);
              },
            );
          } else if (state is GuardianError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: Text('Loading...'));
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGuardianDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Guardian'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Guardians Added',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Add trusted contacts for emergencies',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardianCard(Guardian guardian) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: guardian.isPrimary ? Colors.red : Colors.blue,
          child: Text(
            guardian.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(guardian.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(guardian.phone),
            if (guardian.relationship != null)
              Text(guardian.relationship!, style: TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (guardian.isPrimary)
              const Chip(label: Text('Primary', style: TextStyle(fontSize: 10))),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'primary', child: Text('Set as Primary')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteGuardian(guardian);
                } else if (value == 'primary') {
                  _setPrimary(guardian);
                } else if (value == 'edit') {
                  _showEditGuardianDialog(guardian);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGuardianDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final relationshipController = TextEditingController();
    bool isPrimary = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Guardian'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name *'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone *'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: relationshipController,
                  decoration: const InputDecoration(labelText: 'Relationship'),
                ),
                CheckboxListTile(
                  title: const Text('Primary Guardian'),
                  value: isPrimary,
                  onChanged: (value) {
                    setState(() => isPrimary = value ?? false);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                  final user = this.context.read<AuthCubit>().getCurrentUser();
                  if (user != null) {
                    this.context.read<GuardianCubit>().addGuardian(
                          userId: user.uid,
                          name: nameController.text,
                          phone: phoneController.text,
                          email: emailController.text.isEmpty ? null : emailController.text,
                          relationship: relationshipController.text.isEmpty ? null : relationshipController.text,
                          isPrimary: isPrimary,
                        );
                  }
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGuardianDialog(Guardian guardian) {
    final nameController = TextEditingController(text: guardian.name);
    final phoneController = TextEditingController(text: guardian.phone);
    final emailController = TextEditingController(text: guardian.email ?? '');
    final relationshipController = TextEditingController(text: guardian.relationship ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Guardian'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: relationshipController, decoration: const InputDecoration(labelText: 'Relationship')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final user = this.context.read<AuthCubit>().getCurrentUser();
              if (user != null) {
                this.context.read<GuardianCubit>().updateGuardian(
                      user.uid,
                      guardian.copyWith(
                        name: nameController.text,
                        phone: phoneController.text,
                        email: emailController.text.isEmpty ? null : emailController.text,
                        relationship: relationshipController.text.isEmpty ? null : relationshipController.text,
                      ),
                    );
              }
              Navigator.pop(dialogContext);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _deleteGuardian(Guardian guardian) {
    final user = context.read<AuthCubit>().getCurrentUser();
    if (user != null) {
      context.read<GuardianCubit>().deleteGuardian(user.uid, guardian.id);
    }
  }

  void _setPrimary(Guardian guardian) {
    final user = context.read<AuthCubit>().getCurrentUser();
    if (user != null) {
      context.read<GuardianCubit>().setPrimaryGuardian(user.uid, guardian.id);
    }
  }
}

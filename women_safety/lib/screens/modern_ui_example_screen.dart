import 'package:flutter/material.dart';
import 'package:women_safety/theme/app_theme.dart';
import 'package:women_safety/widgets/index.dart';

/// Example Screen showing all the new Modern UI Components
/// This demonstrates best practices for building beautiful UIs with the new system
class ModernUIExampleScreen extends StatefulWidget {
  const ModernUIExampleScreen({super.key});

  static const routeName = '/modern-ui-example';

  @override
  State<ModernUIExampleScreen> createState() => _ModernUIExampleScreenState();
}

class _ModernUIExampleScreenState extends State<ModernUIExampleScreen> {
  int _selectedIndex = 0;
  bool _isChecked = false;
  double _sliderValue = 50;
  String _selectedRelationship = 'Friend';
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Modern UI Components',
        gradient: AppTheme.sosPrimaryGradient(),
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECTION 1: Buttons
            _sectionTitle(context, 'Buttons'),
            PrimaryButton(
              label: 'Primary Button',
              onPressed: () => _showSnackBar('Primary button pressed'),
              icon: const Icon(Icons.check),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Secondary Button',
              onPressed: () => _showSnackBar('Secondary button pressed'),
              icon: const Icon(Icons.info),
            ),
            const SizedBox(height: 12),
            DangerButton(
              label: 'Danger Button',
              onPressed: () => _showSnackBar('Danger button pressed'),
              icon: const Icon(Icons.warning),
            ),
            const SizedBox(height: 24),

            // SECTION 2: Cards
            _sectionTitle(context, 'Feature Cards'),
            ModernFeatureCard(
              icon: Icons.location_on,
              title: 'Live Location',
              description: 'Share your real-time location with trusted guardians',
              onTap: () => _showSnackBar('Live Location tapped'),
              iconColor: Colors.blue,
              backgroundGradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.cyan.shade50],
              ),
            ),
            const SizedBox(height: 12),
            ModernFeatureCard(
              icon: Icons.emergency,
              title: 'Emergency SOS',
              description: 'Trigger instant alerts to all your guardians',
              onTap: () => _showSnackBar('Emergency SOS tapped'),
              iconColor: AppTheme.danger,
              backgroundGradient: LinearGradient(
                colors: [Colors.red.shade50, Colors.orange.shade50],
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 3: Status Cards
            _sectionTitle(context, 'Status Cards'),
            Row(
              children: [
                Expanded(
                  child: StatusCard(
                    label: 'Active Guards',
                    value: '5',
                    icon: Icons.people,
                    accentColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatusCard(
                    label: 'Location Shares',
                    value: '12',
                    icon: Icons.location_on,
                    accentColor: AppTheme.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // SECTION 4: Guardian Card
            _sectionTitle(context, 'Guardian Card'),
            GuardianCard(
              name: 'Jane Doe',
              phone: '+1 (555) 123-4567',
              relationship: 'Mother',
              onTap: () => _showSnackBar('Guardian card tapped'),
            ),
            const SizedBox(height: 24),

            // SECTION 5: Alert Card
            _sectionTitle(context, 'Alert Cards'),
            AlertCard(
              title: 'Location Access',
              message: 'Enable location access for SOS features',
              type: AlertType.warning,
            ),
            const SizedBox(height: 12),
            AlertCard(
              title: 'Success',
              message: 'Your guardian list has been updated',
              type: AlertType.success,
              onDismiss: () => _showSnackBar('Alert dismissed'),
            ),
            const SizedBox(height: 24),

            // SECTION 6: Form Fields
            _sectionTitle(context, 'Form Fields'),
            ModernTextField(
              label: 'Full Name',
              hint: 'Enter your full name',
              controller: _nameController,
              prefixIcon: Icons.person,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),
            ModernDropdown<String>(
              label: 'Relationship',
              value: _selectedRelationship,
              items: const [
                DropdownMenuItem(value: 'Friend', child: Text('Friend')),
                DropdownMenuItem(value: 'Family', child: Text('Family')),
                DropdownMenuItem(value: 'Colleague', child: Text('Colleague')),
              ],
              onChanged: (value) => setState(() => _selectedRelationship = value ?? 'Friend'),
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            ModernCheckbox(
              value: _isChecked,
              onChanged: (value) => setState(() => _isChecked = value ?? false),
              label: 'I agree to share my location',
              activeColor: AppTheme.primary,
            ),
            const SizedBox(height: 16),
            ModernSlider(
              label: 'Alert Urgency',
              value: _sliderValue,
              onChanged: (value) => setState(() => _sliderValue = value),
              min: 1,
              max: 10,
              valueLabel: '${_sliderValue.toStringAsFixed(0)}/10',
            ),
            const SizedBox(height: 24),

            // SECTION 7: Segmented Control
            _sectionTitle(context, 'Segmented Control'),
            ModernSegmentedControl(
              items: const ['Active', 'Inactive', 'Pending'],
              selectedIndex: _selectedIndex,
              onChanged: (index) => setState(() => _selectedIndex = index),
            ),
            const SizedBox(height: 24),

            // SECTION 8: Animations
            _sectionTitle(context, 'Animations'),
            PulseAnimation(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Pulse Animation',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeInAnimation(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.info,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Fade In Animation',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // SECTION 9: Loading States
            _sectionTitle(context, 'Loading States'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ModernLoadingSpinner(
                  color: AppTheme.primary,
                ),
                ShimmerLoading(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // SECTION 10: Empty State
            _sectionTitle(context, 'Empty State'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: EmptyState(
                  icon: Icons.people_outline,
                  title: 'No Guardians Added',
                  description: 'Add your first guardian to get started',
                  onAction: () => _showSnackBar('Add guardian tapped'),
                  actionLabel: 'Add Guardian',
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
          fontWeight: FontWeight.w700,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

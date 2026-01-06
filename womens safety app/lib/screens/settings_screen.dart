/// Settings Screen
/// App settings and preferences
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/theme_cubit.dart';
import '../cubits/auth_cubit.dart';
import '../routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          // Theme Settings
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: const Text('App appearance'),
          ),
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text('Light'),
                    value: ThemeMode.light,
                    groupValue: themeMode,
                    onChanged: (value) {
                      context.read<ThemeCubit>().setLightTheme();
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('Dark'),
                    value: ThemeMode.dark,
                    groupValue: themeMode,
                    onChanged: (value) {
                      context.read<ThemeCubit>().setDarkTheme();
                    },
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text('System'),
                    value: ThemeMode.system,
                    groupValue: themeMode,
                    onChanged: (value) {
                      context.read<ThemeCubit>().setSystemTheme();
                    },
                  ),
                ],
              );
            },
          ),
          const Divider(),
          // Notifications
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Receive alerts and updates'),
            value: true,
            onChanged: (value) {},
          ),
          // Location
          SwitchListTile(
            secondary: const Icon(Icons.location_on),
            title: const Text('Location Services'),
            subtitle: const Text('Always allow location access'),
            value: true,
            onChanged: (value) {},
          ),
          const Divider(),
          // About
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Women Safety App',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2026 Women Safety App',
              );
            },
          ),
          // Privacy Policy
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () {},
          ),
          // Terms of Service
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            onTap: () {},
          ),
          const Divider(),
          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.read<AuthCubit>().logout();
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.login,
                          (route) => false,
                        );
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

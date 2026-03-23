import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth/auth_cubit.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  static const routeName = '/';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false;

  void _goTo(String route) {
    if (_navigated || !mounted) return;
    setState(() => _navigated = true);
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.initialized != current.initialized ||
          previous.user != current.user,
      listener: (context, state) {
        if (!state.initialized) {
          return;
        }
        if (state.user != null) {
          _goTo(HomeScreen.routeName);
        } else {
          _goTo(LoginScreen.routeName);
        }
      },
      child: const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Preparing your experience...'),
            ],
          ),
        ),
      ),
    );
  }
}

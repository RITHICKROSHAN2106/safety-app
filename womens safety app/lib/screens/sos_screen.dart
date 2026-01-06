/// SOS Screen
/// Emergency SOS activation with countdown and alert system
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/sos_cubit.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/guardian_cubit.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({Key? key}) : super(key: key);

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  int _clickCount = 0;
  bool _countdownStarted = false;

  void _handleSosClick() {
    setState(() {
      _clickCount++;
    });

    if (_clickCount >= 3 && !_countdownStarted) {
      setState(() {
        _countdownStarted = true;
      });
      context.read<SosCubit>().startSosCountdown();
    }

    // Reset click count after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_countdownStarted) {
        setState(() {
          _clickCount = 0;
        });
      }
    });
  }

  void _confirmSos() {
    final user = context.read<AuthCubit>().getCurrentUser();
    final guardians = context.read<GuardianCubit>().getGuardians();

    if (user != null && guardians.isNotEmpty) {
      context.read<SosCubit>().triggerSos(
            userId: user.uid,
            userName: user.name,
            guardians: guardians,
          );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add guardians before triggering SOS'),
        ),
      );
      _cancelSos();
    }
  }

  void _cancelSos() {
    setState(() {
      _clickCount = 0;
      _countdownStarted = false;
    });
    context.read<SosCubit>().cancelSos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<SosCubit, SosState>(
        listener: (context, state) {
          if (state is SosTriggered) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('SOS Alert Sent Successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pop(context);
              }
            });
          } else if (state is SosError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is SosCancelled) {
            setState(() {
              _clickCount = 0;
              _countdownStarted = false;
            });
          }
        },
        builder: (context, state) {
          if (state is SosCountdown) {
            return _buildCountdownUI(state.remainingSeconds);
          } else if (state is SosTriggering) {
            return _buildTriggeringUI();
          } else if (state is SosTriggered) {
            return _buildSuccessUI();
          } else {
            return _buildInitialUI();
          }
        },
      ),
    );
  }

  Widget _buildInitialUI() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.red.shade400,
            Colors.red.shade700,
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 100,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              const Text(
                'EMERGENCY SOS',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _clickCount == 0
                    ? 'Tap button 3 times to activate'
                    : 'Tapped $_clickCount/3 times',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 48),
              // SOS Button
              GestureDetector(
                onTap: _handleSosClick,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: const Text(
                  'This will send your location and alert to all guardians',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownUI(int remaining) {
    return Container(
      color: Colors.red.shade700,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ACTIVATING SOS IN',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Center(
                  child: Text(
                    '$remaining',
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: remaining == 0 ? _confirmSos : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'SEND ALERT NOW',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _cancelSos,
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTriggeringUI() {
    return Container(
      color: Colors.red.shade700,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 5,
            ),
            SizedBox(height: 24),
            Text(
              'Sending SOS Alert...',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Fetching location\nAlerting guardians\nActivating emergency protocols',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessUI() {
    return Container(
      color: Colors.green.shade700,
      child: const SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 100,
                color: Colors.white,
              ),
              SizedBox(height: 24),
              Text(
                'SOS ALERT SENT!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Your guardians have been notified',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

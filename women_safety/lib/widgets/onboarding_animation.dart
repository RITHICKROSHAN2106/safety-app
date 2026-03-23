import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OnboardingAnimation extends StatelessWidget {
  const OnboardingAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Lottie.asset('assets/lottie/onboarding.json', repeat: true);
  }
}

import 'dart:io';

bool get isTestEnvironment {
  final environment = Platform.environment;
  return environment.containsKey('FLUTTER_TEST') ||
      environment.containsKey('DART_TEST') ||
      environment.containsKey('INTEGRATION_TEST');
}
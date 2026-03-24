/// Permissions Service
/// Handles all runtime permissions required by the app
import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  // Request initial critical permissions on app start
  Future<void> requestInitialPermissions() async {
    await Future.wait([
      Permission.location.request(),
      Permission.notification.request(),
    ]);
  }

  // Request location permissions
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      return false;
    }
    return true;
  }

  // Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // Request storage permission
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  // Request phone call permission
  Future<bool> requestPhonePermission() async {
    final status = await Permission.phone.request();
    return status.isGranted;
  }

  // Request SMS permission
  Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  // Request all SOS-related permissions
  Future<Map<String, bool>> requestSosPermissions() async {
    final results = await Future.wait([
      Permission.location.request(),
      Permission.camera.request(),
      Permission.microphone.request(),
      Permission.phone.request(),
      Permission.sms.request(),
    ]);

    return {
      'location': results[0].isGranted,
      'camera': results[1].isGranted,
      'microphone': results[2].isGranted,
      'phone': results[3].isGranted,
      'sms': results[4].isGranted,
    };
  }

  // Check if location permission is granted
  Future<bool> isLocationPermissionGranted() async {
    return await Permission.location.isGranted;
  }

  // Open app settings if permission is permanently denied
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}

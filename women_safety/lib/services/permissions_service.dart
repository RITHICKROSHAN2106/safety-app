import 'dart:io';
import 'package:permission_handler/permission_handler.dart' as ph;

class PermissionsService {
  static Future<void> ensureLocation() async {
    if (await ph.Permission.location.isGranted) return;
    await ph.Permission.location.request();
  }

  static Future<void> ensureNotifications() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final status = await ph.Permission.notification.status;
    if (!status.isGranted) {
      await ph.Permission.notification.request();
    }
  }

  static Future<void> ensureCameraAndMic() async {
    if (!await ph.Permission.camera.isGranted) {
      await ph.Permission.camera.request();
    }
    if (!await ph.Permission.microphone.isGranted) {
      await ph.Permission.microphone.request();
    }
  }
}

import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Request browser notification permission.
Future<bool> requestWebNotificationPermission() async {
  try {
    final result = await web.Notification.requestPermission().toDart;
    return result.toDart == 'granted';
  } catch (_) {
    return false;
  }
}

/// Check if browser notifications are permitted.
Future<bool> hasWebNotificationPermission() async {
  try {
    return web.Notification.permission == 'granted';
  } catch (_) {
    return false;
  }
}

/// Show a browser desktop notification.
void showWebNotification(String title, String body) {
  try {
    if (web.Notification.permission == 'granted') {
      web.Notification(
        title,
        web.NotificationOptions(
          body: body,
          icon: 'icons/Icon-192.png',
        ),
      );
    }
  } catch (_) {}
}

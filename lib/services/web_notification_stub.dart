/// Stub for non-web platforms.
Future<bool> requestWebNotificationPermission() async => false;

Future<bool> hasWebNotificationPermission() async => false;

void showWebNotification(String title, String body) {}

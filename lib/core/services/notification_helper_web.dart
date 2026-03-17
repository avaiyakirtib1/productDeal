// Web implementation - show browser notification when app is in foreground
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

void showWebForegroundNotification(String title, String body) {
  if (html.Notification.permission == 'granted') {
    html.Notification(title, body: body);
  }
}

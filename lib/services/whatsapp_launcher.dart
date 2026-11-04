import 'package:url_launcher/url_launcher.dart';

class WhatsAppLauncher {
  /// Opens the WhatsApp chat with a prefilled message.
  /// Returns true if a URL handler accepted the intent.
  static Future<bool> openChat({
    required String e164Number,
    required String message,
  }) async {
    final digitsOnly = e164Number.replaceAll(RegExp(r'\D'), '');
    final encoded = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$digitsOnly?text=$encoded');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
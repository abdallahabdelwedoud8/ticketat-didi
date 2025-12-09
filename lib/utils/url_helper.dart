import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class UrlHelper {
  static Future<void> sendPartnerApplicationEmail({
    required BuildContext context,
    required String organizerName,
    required String organizerEmail,
    required String organizerPhone,
  }) async {
    final subject = Uri.encodeComponent('Ticketat Partner Application - $organizerName');
    final body = Uri.encodeComponent('''Hello Ticketat Team,

I would like to apply for Partner Organizer status on the Ticketat platform.

Organizer Details:
- Name: $organizerName
- Email: $organizerEmail
- Phone: $organizerPhone

I understand that as a Partner Organizer:
• I will pay 0% commission to Ticketat
• My clients will pay 65 MRU for tickets under 500 MRU, or 14% for tickets 500 MRU and above

Please review my application and let me know the next steps.

Thank you!
''');

    final emailUri = Uri.parse('mailto:abdallahabdelwedoud8@gmail.com?subject=$subject&body=$body');

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email client. Please email abdallahabdelwedoud8@gmail.com directly.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

import 'package:share_plus/share_plus.dart';
import 'package:eventide/models/app_models.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShareHelper {
  static Future<void> shareEvent(EventModel event) async {
    final formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(event.date);
    final formattedTime = DateFormat('HH:mm').format(event.date);
    
    final shareText = '''
🎉 ${event.title}

📅 Date: $formattedDate
🕐 Time: $formattedTime
📍 Venue: ${event.venue}
🎫 Category: ${event.category}
💰 Price: ${event.price} MRU

${event.description}

🎟️ Get your tickets now on Ticketat - Mauritania's Digital Gateway to All Events!

Available Tickets: ${event.capacity - event.soldTickets}/${event.capacity}

📱 Download Ticketat: https://ticketat.mr
''';
    
    await Share.share(
      shareText,
      subject: event.title,
    );
  }
  
  static Future<void> shareTicket(String eventTitle, String ticketId, DateTime eventDate, String venue) async {
    final formattedDate = DateFormat('EEEE, dd MMMM yyyy').format(eventDate);
    final formattedTime = DateFormat('HH:mm').format(eventDate);
    
    final shareText = '''
🎟️ My Ticket for $eventTitle

📅 $formattedDate at $formattedTime
📍 $venue

Ticket ID: $ticketId

Powered by Ticketat 🎉

📱 Download Ticketat: https://ticketat.mr
''';
    
    await Share.share(shareText);
  }
  
  static Future<void> shareApp() async {
    const shareText = '''
🎉 Discover Ticketat - Mauritania's Digital Gateway to All Events!

✅ Buy & store tickets securely with QR codes
✅ Discover amazing events near you
✅ Get personalized recommendations
✅ Organize events with powerful analytics

Download Ticketat today and never miss an event!

📱 Get Ticketat: https://ticketat.mr
''';
    
    await Share.share(shareText);
  }
  
  static Future<void> shareEventLink(String eventTitle, String link) async {
    final shareText = '''
🎉 You're Invited to $eventTitle!

This is a private event. Click the link below to view details and get your ticket:

🔗 $link

Powered by Ticketat - Mauritania's Digital Event Platform
''';
    
    await Share.share(shareText, subject: 'Invitation: $eventTitle');
  }
  
  static Future<void> copyToClipboard(String text, BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: text));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:eventide/models/app_models.dart';
import 'package:eventide/services/event_service.dart';
import 'package:eventide/services/auth_service.dart';
import 'package:eventide/services/ticket_service.dart';
import 'package:eventide/utils/constants.dart';
import 'package:eventide/screens/auth_screen.dart';
import 'package:eventide/screens/payment_screen.dart';
import 'package:intl/intl.dart';

class PrivateEventPage extends StatefulWidget {
  final String eventCode;
  final bool fromQRScan;

  const PrivateEventPage({
    super.key,
    required this.eventCode,
    this.fromQRScan = false,
  });

  @override
  State<PrivateEventPage> createState() => _PrivateEventPageState();
}

class _PrivateEventPageState extends State<PrivateEventPage> {
  EventModel? _event;
  AppUser? _currentUser;
  TicketModel? _userTicket;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEventAndTrack();
  }

  Future<void> _loadEventAndTrack() async {
    setState(() => _isLoading = true);

    try {
      // Find event by private code
      final event = await EventService.getEventByPrivateCode(widget.eventCode);
      
      if (event == null) {
        setState(() {
          _error = 'Private event not found';
          _isLoading = false;
        });
        return;
      }

      // Track the view
      await EventService.trackPrivateEventView(event.eventId, widget.fromQRScan);

      // Check if user is logged in
      final user = await AuthService.getCurrentUser();

      // If user is logged in, check if they already have a ticket
      TicketModel? ticket;
      if (user != null) {
        final userTickets = await TicketService.getUserTickets(user.userId);
        ticket = userTickets.where((t) => t.eventId == event.eventId).firstOrNull;
      }

      setState(() {
        _event = event;
        _currentUser = user;
        _userTicket = ticket;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading event: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppConstants.primaryColor),
              const SizedBox(height: 16),
              Text(
                widget.fromQRScan ? 'Scanning QR Code...' : 'Loading event...',
                style: const TextStyle(color: AppConstants.greyColor),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _event == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppConstants.whiteColor,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Event not found',
                  style: const TextStyle(fontSize: 18, color: AppConstants.textColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
                  child: const Text('Go Back', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If user has a ticket, show the ticket
    if (_userTicket != null) {
      return _buildTicketView();
    }

    // Otherwise, show the event landing page
    return _buildEventLandingPage();
  }

  Widget _buildEventLandingPage() {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppConstants.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(_event!.imageUrl, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Private Invitation',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _event!.title,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppConstants.textColor),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.celebration, color: Colors.purple, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'You\'ve Been Invited!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'This is a private event. Sign up or log in to get your ticket.',
                          style: TextStyle(color: AppConstants.greyColor, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow(Icons.calendar_today, 'Date', DateFormat('EEEE, MMMM dd, yyyy').format(_event!.date)),
                  _buildInfoRow(Icons.access_time, 'Time', DateFormat('HH:mm').format(_event!.date)),
                  _buildInfoRow(Icons.location_on, 'Venue', _event!.venue),
                  _buildInfoRow(Icons.category, 'Category', _event!.category),
                  if (_event!.isFreeEvent || _event!.price == 0)
                    _buildInfoRow(Icons.card_giftcard, 'Price', 'FREE')
                  else
                    _buildInfoRow(Icons.payments, 'Price', '${_event!.price} MRU'),
                  const SizedBox(height: 24),
                  const Text('About This Event', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(_event!.description, style: const TextStyle(fontSize: 16, color: AppConstants.greyColor, height: 1.5)),
                  const SizedBox(height: 32),
                  if (_currentUser == null)
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _handleSignupLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Sign Up / Login to Get Ticket', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'You need to create an account or log in to receive your ticket',
                          style: TextStyle(color: AppConstants.greyColor, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _handleGetTicket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Get My Ticket', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Ticket', style: TextStyle(color: AppConstants.textColor)),
        backgroundColor: AppConstants.whiteColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You\'re all set! Your ticket is ready.',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppConstants.whiteColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(_event!.imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 16),
                  Text(_event!.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(DateFormat('EEEE, MMMM dd, yyyy • HH:mm').format(_event!.date), style: const TextStyle(color: AppConstants.greyColor)),
                  const SizedBox(height: 8),
                  Text(_event!.venue, style: const TextStyle(color: AppConstants.greyColor), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.whiteColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppConstants.greyColor.withValues(alpha: 0.3), width: 2),
                    ),
                    child: Container(
                      width: 200,
                      height: 100,
                      padding: const EdgeInsets.all(8),
                      child: CustomPaint(
                        painter: BarcodePainter(_userTicket!.qrData),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Ticket ID: ${_userTicket!.ticketId.substring(0, 8).toUpperCase()}', style: const TextStyle(color: AppConstants.greyColor, fontSize: 12)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Show this barcode at the event entrance',
                            style: TextStyle(color: Colors.blue, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Dashboard'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
                side: const BorderSide(color: AppConstants.primaryColor),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppConstants.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppConstants.greyColor)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignupLogin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );

    // Reload data after returning from auth
    if (result == true) {
      await _loadEventAndTrack();
    }
  }

  Future<void> _handleGetTicket() async {
    // For free events, directly create tickets without payment
    if (_event!.isFreeEvent || _event!.price == 0) {
      setState(() => _isLoading = true);
      try {
        await TicketService.purchaseTicket(_currentUser!.userId, _event!.eventId);
        await _loadEventAndTrack();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket obtained successfully!'), backgroundColor: Colors.green),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } else {
      // Paid event - navigate to payment screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            event: _event!,
            fromPrivateEvent: true,
          ),
        ),
      );

      // If payment completed, reload to show ticket
      if (result == true) {
        await _loadEventAndTrack();
      }
    }
  }
}

// Custom painter for linear barcode
class BarcodePainter extends CustomPainter {
  final String data;

  BarcodePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Generate barcode pattern from data
    final hash = data.hashCode.abs();
    final random = hash % 1000;
    
    // Create varying bar widths based on data
    final barCount = 60;
    double x = 0;
    final barWidth = size.width / barCount;

    for (int i = 0; i < barCount; i++) {
      // Vary bar pattern based on position and data hash
      final shouldDraw = ((random + i * 7) % 3) != 0;
      final heightVariation = ((random + i * 11) % 5) / 10;
      
      if (shouldDraw) {
        final barHeight = size.height * (0.7 + heightVariation);
        final yOffset = (size.height - barHeight) / 2;
        
        canvas.drawRect(
          Rect.fromLTWH(x, yOffset, barWidth * 0.8, barHeight),
          paint,
        );
      }
      
      x += barWidth;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

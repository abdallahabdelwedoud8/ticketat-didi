import 'package:flutter/material.dart';
import 'package:eventide/utils/constants.dart';
import 'package:eventide/models/app_models.dart';
import 'package:eventide/services/ticket_service.dart';
import 'package:eventide/services/event_service.dart';
import 'package:eventide/services/auth_service.dart';
import 'package:eventide/screens/onboarding_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class SecurityDashboard extends StatefulWidget {
  const SecurityDashboard({super.key});

  @override
  State<SecurityDashboard> createState() => _SecurityDashboardState();
}

class _SecurityDashboardState extends State<SecurityDashboard> {
  MobileScannerController? _controller;
  String? _scannedTicketId;
  TicketModel? _currentTicket;
  EventModel? _currentEvent;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
        title: const Text('Ticketat Security', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await AuthService.logout();
              if (!mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Icon(Icons.barcode_reader, size: 80, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'Scan Ticket Barcode',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  _isProcessing ? 'Processing...' : 'Point camera at ticket barcode',
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _currentTicket == null
                ? _buildBarcodeScanner()
                : _buildTicketDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeScanner() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: MobileScanner(
          controller: _controller,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null && !_isProcessing) {
                _processTicket(barcode.rawValue!);
                break;
              }
            }
          },
        ),
      ),
    );
  }

  Widget _buildTicketDetails() {
    final ticket = _currentTicket!;
    final event = _currentEvent!;
    final isValid = ticket.status == TicketStatus.valid;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isValid ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isValid ? Colors.green : Colors.red,
                width: 3,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.cancel,
                  size: 80,
                  color: isValid ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  isValid ? 'VALID TICKET' : 'INVALID TICKET',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isValid ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.status == TicketStatus.used
                      ? 'This ticket has already been used'
                      : ticket.status == TicketStatus.expired
                          ? 'This ticket has expired'
                          : 'Grant entry to this guest',
                  style: TextStyle(
                    fontSize: 16,
                    color: isValid ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Event Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Divider(height: 24),
                _buildDetailRow('Event', event.title),
                _buildDetailRow('Date', '${event.date.day}/${event.date.month}/${event.date.year}'),
                _buildDetailRow('Venue', event.venue),
                _buildDetailRow('Price Paid', '${ticket.pricePaid.toStringAsFixed(0)} MRU'),
                _buildDetailRow('Purchase Date', '${ticket.purchaseDate.day}/${ticket.purchaseDate.month}/${ticket.purchaseDate.year}'),
                _buildDetailRow('Ticket ID', ticket.ticketId.substring(0, 8)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (isValid)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _markTicketAsUsed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'MARK AS USED & GRANT ENTRY',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _resetScanner,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppConstants.primaryColor, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Scan Next Ticket',
                style: TextStyle(color: AppConstants.primaryColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppConstants.greyColor, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: AppConstants.textColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processTicket(String barcodeData) async {
    setState(() => _isProcessing = true);
    await _controller?.stop();
    
    final ticket = await TicketService.getTicketByBarcode(barcodeData);
    
    if (ticket == null) {
      _showSnackBar('Invalid Barcode', Colors.red);
      await _controller?.start();
      setState(() => _isProcessing = false);
      return;
    }
    
    final event = await EventService.getEventById(ticket.eventId);
    
    if (event == null) {
      _showSnackBar('Event not found', Colors.red);
      await _controller?.start();
      setState(() => _isProcessing = false);
      return;
    }
    
    setState(() {
      _scannedTicketId = ticket.ticketId;
      _currentTicket = ticket;
      _currentEvent = event;
      _isProcessing = false;
    });
  }

  Future<void> _markTicketAsUsed() async {
    if (_currentTicket == null) return;
    
    await TicketService.markTicketAsUsed(_currentTicket!.ticketId);
    
    _showSnackBar('Ticket marked as used - Entry granted', Colors.green);
    
    await Future.delayed(const Duration(seconds: 2));
    _resetScanner();
  }

  void _resetScanner() {
    setState(() {
      _scannedTicketId = null;
      _currentTicket = null;
      _currentEvent = null;
    });
    _controller?.start();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

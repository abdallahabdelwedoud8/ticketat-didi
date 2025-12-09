import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:eventide/utils/constants.dart';
import 'package:eventide/utils/share_helper.dart';
import 'package:eventide/utils/url_helper.dart';
import 'package:eventide/utils/image_helper.dart';
import 'package:eventide/models/app_models.dart';
import 'package:eventide/services/auth_service.dart';
import 'package:eventide/services/event_service.dart';
import 'package:eventide/services/ticket_service.dart';
import 'package:eventide/services/sponsor_service.dart';
import 'package:eventide/services/firebase_event_service.dart';
import 'package:eventide/screens/auth_screen.dart';
import 'package:eventide/screens/buyer_dashboard.dart';
import 'package:eventide/screens/security_dashboard.dart';
import 'package:eventide/services/storage_service.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';

class OrganizerDashboard extends StatefulWidget {
  const OrganizerDashboard({super.key});

  @override
  State<OrganizerDashboard> createState() => _OrganizerDashboardState();
}

class _OrganizerDashboardState extends State<OrganizerDashboard> {
  int _currentIndex = 0;
  AppUser? _currentUser;
  List<EventModel> _myEvents = [];
  List<ProviderModel> _providers = [];
  bool _isLoading = true;
  String? _selectedEventForSponsorship;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _currentUser = await AuthService.getCurrentUser();
    final allEvents = await EventService.getAllEvents();
    _myEvents = allEvents.where((e) => e.organizerId == _currentUser?.userId).toList();
    _providers = await EventService.getAllProviders();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 16),
          child: Image.asset('assets/images/main_logo.png', height: 26),
        ),
        leadingWidth: 150,
        backgroundColor: AppConstants.whiteColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20, top: 16),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppConstants.textColor, size: 28),
              onPressed: _showMenu,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
          : _buildBody(),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavIcon(Icons.event, 0),
            _buildNavIcon(Icons.business, 1),
            _buildNavIcon(Icons.star, 2),
            _buildNavIcon(Icons.barcode_reader, 3),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _currentIndex == 0 ? _showCreateEventDialog : null,
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? AppConstants.primaryColor : AppConstants.greyColor,
        size: 28,
      ),
      onPressed: () => setState(() => _currentIndex = index),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildEventsTab();
      case 1:
        return _buildProvidersTab();
      case 2:
        return _buildSponsorsTab();
      case 3:
        return _buildScannerTab();
      default:
        return _buildEventsTab();
    }
  }

  Widget _buildEventsTab() {
    if (_myEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: AppConstants.greyColor.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('No events created yet', style: TextStyle(fontSize: 18, color: AppConstants.greyColor)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _showCreateEventDialog,
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
              child: const Text('Create Your First Event', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myEvents.length,
        itemBuilder: (ctx, index) => _buildEventCard(_myEvents[index]),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: ImageHelper.buildImage(event.imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover),
              ),
              if (event.isPrivate)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text('Private', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: AppConstants.greyColor),
                    const SizedBox(width: 4),
                    Text(DateFormat('dd MMM yyyy').format(event.date), style: const TextStyle(color: AppConstants.greyColor)),
                  ],
                ),
                const SizedBox(height: 8),
                if (event.isPrivate) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Barcode Scans', style: TextStyle(fontSize: 12, color: AppConstants.greyColor)),
                          Text('${event.qrScans}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Link Clicks', style: TextStyle(fontSize: 12, color: AppConstants.greyColor)),
                          Text('${event.linkClicks}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Attendees', style: TextStyle(fontSize: 12, color: AppConstants.greyColor)),
                          Text('${event.soldTickets}/${event.capacity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tickets Sold', style: TextStyle(fontSize: 12, color: AppConstants.greyColor)),
                          Text('${event.soldTickets}/${event.capacity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Revenue', style: TextStyle(fontSize: 12, color: AppConstants.greyColor)),
                          Text('${event.soldTickets * event.price} MRU', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                        ],
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showEditEventDialog(event),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppConstants.primaryColor),
                        ),
                        child: const Text('Edit', style: TextStyle(color: AppConstants.primaryColor)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showEventAnalytics(event),
                        style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
                        child: const Text('Analytics', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => ShareHelper.shareEvent(event),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppConstants.primaryColor,
                          side: const BorderSide(color: AppConstants.primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: event.isSponsored && event.date.isAfter(DateTime.now())
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.rocket_launch, color: Colors.orange, size: 18),
                                const SizedBox(width: 4),
                                Text('Boosted ${event.sponsoredDays}d', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          )
                        : OutlinedButton.icon(
                            onPressed: event.date.isAfter(DateTime.now()) ? () => _showBoostEventDialog(event) : null,
                            icon: const Icon(Icons.rocket_launch, size: 18),
                            label: const Text('Boost'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                            ),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    final activeEvents = _myEvents.where((e) => e.date.isAfter(DateTime.now())).toList();
    
    if (activeEvents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No active events available. Create an event to generate security credentials.',
            style: TextStyle(color: AppConstants.greyColor, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security Login Credentials',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select an event to view its security team login details',
            style: TextStyle(fontSize: 14, color: AppConstants.greyColor),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: activeEvents.length,
              itemBuilder: (ctx, index) {
                final event = activeEvents[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ExpansionTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ImageHelper.buildImage(event.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                    ),
                    title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(event.date)),
                    children: [
                      FutureBuilder<SecurityStaff?>(
                        future: _getSecurityStaff(event.eventId),
                        builder: (ctx, snapshot) {
                          if (!snapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No security credentials found', style: TextStyle(color: AppConstants.greyColor)),
                            );
                          }
                          
                          final security = snapshot.data!;
                          return Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppConstants.primaryColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Security Team Login:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.person, color: AppConstants.primaryColor, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Username:', style: TextStyle(fontSize: 12, color: AppConstants.greyColor)),
                                          Text(security.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.lock, color: AppConstants.primaryColor, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Password:', style: TextStyle(fontSize: 12, color: AppConstants.greyColor)),
                                          Text(security.tempPassword.isNotEmpty ? security.tempPassword : '••••••••', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          // Auto-login using security credentials
                                          final user = await AuthService.login(security.username, security.tempPassword);
                                          if (user != null && mounted) {
                                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SecurityDashboard()));
                                          } else {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Security login failed'), backgroundColor: Colors.red),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.login, color: Colors.white),
                                        label: const Text('Login as Security', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppConstants.primaryColor,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          final credentials = 'Username: ${security.username}\\nPassword: ${security.tempPassword}';
                                          // Copy to clipboard (requires services package)
                                          // For now, show a dialog with the text
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text('Credentials Copied!'),
                                              content: Text(credentials),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(ctx),
                                                  child: const Text('OK'),
                                                ),
                                              ],
                                            ),
                                          );
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Credentials displayed'), backgroundColor: Colors.green),
                                          );
                                        },
                                        icon: const Icon(Icons.copy, size: 16),
                                        label: const Text('Copy', style: TextStyle(fontWeight: FontWeight.bold)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppConstants.primaryColor,
                                          side: const BorderSide(color: AppConstants.primaryColor, width: 2),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text('⚠️ Tap the button above to instantly login to the security scanner portal.', style: TextStyle(fontSize: 12, color: Colors.red, fontStyle: FontStyle.italic)),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<SecurityStaff?> _getSecurityStaff(String eventId) async {
    final allStaff = StorageService.getAllData(StorageService.securityBox);
    for (final staffData in allStaff) {
      final staff = SecurityStaff.fromJson(staffData);
      if (staff.eventId == eventId) return staff;
    }
    return null;
  }

  Widget _buildAnalyticsTab() {
    if (_myEvents.isEmpty) {
      return const Center(child: Text('No events to analyze', style: TextStyle(color: AppConstants.greyColor)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myEvents.length,
      itemBuilder: (ctx, index) => _buildAnalyticsCard(_myEvents[index]),
    );
  }

  Widget _buildAnalyticsCard(EventModel event) {
    return FutureBuilder<Map<String, dynamic>>(
      future: TicketService.getEventAnalytics(event.eventId),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        
        final analytics = snapshot.data!;
        final totalSales = analytics['totalSales'] ?? 0;
        final revenue = analytics['revenue'] ?? 0.0;
        final attendance = analytics['attendance'] ?? 0;
        final available = analytics['availableTickets'] ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Sold', '$totalSales', Icons.confirmation_number),
                    _buildStatItem('Revenue', '${revenue.toStringAsFixed(0)} MRU', Icons.attach_money),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Attended', '$attendance', Icons.check_circle),
                    _buildStatItem('Available', '$available', Icons.event_seat),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: event.capacity > 0 ? totalSales / event.capacity : 0,
                  backgroundColor: AppConstants.greyColor.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Capacity: ${((totalSales / event.capacity) * 100).toStringAsFixed(1)}% filled',
                  style: const TextStyle(fontSize: 12, color: AppConstants.greyColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppConstants.primaryColor, size: 32),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppConstants.greyColor)),
      ],
    );
  }

  void _showPrivateEventSuccessDialog(EventModel event) {
    final eventLink = 'ticketat.app/e/${event.privateEventCode}';
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.purple, size: 28),
            const SizedBox(width: 8),
            const Text('Private Event Created!', style: TextStyle(color: Colors.purple, fontSize: 20)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your private event has been created successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.purple, size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      'Share this link or QR code with your invitees',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Event Link:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppConstants.primaryColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        eventLink,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: AppConstants.primaryColor),
                      onPressed: () {
                        ShareHelper.copyToClipboard(eventLink, context);
                      },
                      tooltip: 'Copy link',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('QR Code:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppConstants.greyColor.withValues(alpha: 0.3), width: 2),
                  ),
                  child: QrImageView(
                    data: eventLink,
                    version: QrVersions.auto,
                    size: 200,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ShareHelper.shareEventLink(event.title, eventLink),
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('Share Link'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppConstants.primaryColor,
                        side: const BorderSide(color: AppConstants.primaryColor),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Track QR scans and link clicks in the event analytics dashboard',
                        style: const TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => _showEventAnalytics(event),
            child: const Text('View Analytics'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditEventDialog(EventModel event) {
    final titleController = TextEditingController(text: event.title);
    final venueController = TextEditingController(text: event.venue);
    final capacityController = TextEditingController(text: event.capacity.toString());
    final descController = TextEditingController(text: event.description);
    final googleMapsController = TextEditingController(text: event.googleMapsLink ?? '');
    final websiteController = TextEditingController(text: event.websiteLink ?? '');
    final socialMediaController = TextEditingController(text: event.socialMediaLink ?? '');
    
    final paymentControllers = {
      'Bankily': {'number': TextEditingController(), 'confirm': TextEditingController()},
      'Sedad': {'number': TextEditingController(), 'confirm': TextEditingController()},
      'Bimbank': {'number': TextEditingController(), 'confirm': TextEditingController()},
    };
    final selectedPaymentMethods = <String>{};
    final uploadedMediaFiles = <String>[...event.mediaUrls];
    String? mainImagePath;
    Uint8List? mainImageBytes;
    final additionalMediaPaths = <String>[...event.mediaUrls];
    final additionalMediaBytes = <Uint8List>[];
    final ticketTiers = <TicketTier>[...event.ticketTiers];
    
    // Pre-fill existing payment options
    for (final paymentOption in event.paymentOptions) {
      selectedPaymentMethods.add(paymentOption.provider);
      paymentControllers[paymentOption.provider]!['number']!.text = paymentOption.accountNumber;
      paymentControllers[paymentOption.provider]!['confirm']!.text = paymentOption.accountNumber;
    }
    
    String selectedCategory = event.category;
    DateTime selectedDate = event.date;
    String selectedImage = event.imageUrl;
    bool isFreeEvent = event.paymentOptions.isEmpty;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Event Title'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: AppConstants.eventCategories.skip(1).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setDialogState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: venueController,
                  decoration: const InputDecoration(labelText: 'Venue'),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: capacityController,
                  builder: (context, value, child) {
                    final hasError = value.text.isNotEmpty && int.tryParse(value.text) == null;
                    return TextField(
                      controller: capacityController,
                      decoration: InputDecoration(
                        labelText: 'Total Capacity',
                        suffixIcon: hasError
                            ? const Icon(Icons.error, color: Colors.red, size: 20)
                            : null,
                      ),
                      keyboardType: TextInputType.number,
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text('Ticket Tiers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Edit ticket types with different prices and capacities', style: TextStyle(fontSize: 13, color: AppConstants.greyColor)),
                const SizedBox(height: 12),
                _buildTicketTiersSection(setDialogState, ticketTiers),
                const SizedBox(height: 16),
                const Divider(),
                const Text('Event Media', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Update main image and additional media', style: TextStyle(fontSize: 13, color: AppConstants.greyColor)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppConstants.greyColor.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Main Event Image', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            allowMultiple: false,
                            withData: true,
                          );
                          if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
                            setDialogState(() {
                              mainImagePath = result.files.first.name;
                              mainImageBytes = result.files.first.bytes;
                            });
                          }
                        },
                        icon: const Icon(Icons.upload, size: 16),
                        label: const Text('Change Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (mainImagePath != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'New: $mainImagePath',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () => setDialogState(() {
                                  mainImagePath = null;
                                  mainImageBytes = null;
                                }),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Text('Additional Media', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.media,
                            allowMultiple: true,
                            withData: true,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            setDialogState(() {
                              for (final file in result.files) {
                                if (file.bytes != null) {
                                  additionalMediaPaths.add(file.name);
                                  additionalMediaBytes.add(file.bytes!);
                                }
                              }
                            });
                          }
                        },
                        icon: const Icon(Icons.add_photo_alternate, size: 16),
                        label: const Text('Add Media'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.secondaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      if (additionalMediaPaths.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: additionalMediaPaths.length,
                            itemBuilder: (ctx, index) {
                              final mediaPath = additionalMediaPaths[index];
                              final isVideo = mediaPath.toLowerCase().endsWith('.mp4') ||
                                  mediaPath.toLowerCase().endsWith('.mov') ||
                                  mediaPath.toLowerCase().endsWith('.avi');
                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppConstants.primaryColor.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isVideo ? Icons.videocam : Icons.image,
                                      color: AppConstants.primaryColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        mediaPath,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                      onPressed: () {
                                        setDialogState(() {
                                          additionalMediaPaths.removeAt(index);
                                          if (index < additionalMediaBytes.length) {
                                            additionalMediaBytes.removeAt(index);
                                          }
                                        });
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: googleMapsController,
                  decoration: const InputDecoration(
                    labelText: 'Google Maps Link (Optional)',
                    hintText: 'https://maps.google.com/...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Website Link (Optional)',
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: socialMediaController,
                  decoration: const InputDecoration(
                    labelText: 'Social Media Link (Optional)',
                    hintText: 'Instagram, Facebook, etc.',
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text('Event Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppConstants.greyColor.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: const Text('Free Event'),
                    subtitle: const Text('No payment required for tickets', style: TextStyle(fontSize: 12, color: AppConstants.greyColor)),
                    value: isFreeEvent,
                    activeColor: Colors.green,
                    onChanged: (val) => setDialogState(() => isFreeEvent = val),
                  ),
                ),
                if (!isFreeEvent) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  Row(
                    children: [
                      const Text('Payment Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      const Text('*', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Select at least one payment method and enter your number:', style: TextStyle(fontSize: 13, color: AppConstants.greyColor)),
                  const SizedBox(height: 8),
                  if (selectedPaymentMethods.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'At least one payment method is required',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  ...['Bankily', 'Sedad', 'Bimbank'].map((method) {
                    final isSelected = selectedPaymentMethods.contains(method);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? AppConstants.primaryColor : AppConstants.greyColor.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: Text(method, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            value: isSelected,
                            activeColor: AppConstants.primaryColor,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  selectedPaymentMethods.add(method);
                                } else {
                                  selectedPaymentMethods.remove(method);
                                  paymentControllers[method]!['number']!.clear();
                                  paymentControllers[method]!['confirm']!.clear();
                                }
                              });
                            },
                          ),
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: paymentControllers[method]!['number'],
                                    decoration: InputDecoration(
                                      labelText: 'Enter $method Number',
                                      hintText: '+222 XX XX XX XX',
                                      prefixIcon: const Icon(Icons.phone_android),
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: paymentControllers[method]!['confirm'],
                                    decoration: InputDecoration(
                                      labelText: 'Confirm $method Number',
                                      hintText: '+222 XX XX XX XX',
                                      prefixIcon: const Icon(Icons.check_circle),
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || venueController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all required fields'), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                // Validate payment options (skip if free event)
                final paymentOptions = <PaymentOption>[];
                if (!isFreeEvent) {
                for (final method in selectedPaymentMethods) {
                  final numberController = paymentControllers[method]!['number']!;
                  final confirmController = paymentControllers[method]!['confirm']!;
                  
                  if (numberController.text.trim().isEmpty || confirmController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please fill both fields for $method'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  
                  if (numberController.text.trim() != confirmController.text.trim()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$method numbers do not match'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  
                  paymentOptions.add(PaymentOption(provider: method, accountNumber: numberController.text.trim()));
                }
                
                  if (paymentOptions.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please add at least one payment method'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                }
                
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor)),
                );
                
                // Upload main image if changed
                String finalImageUrl = event.imageUrl;
                if (mainImageBytes != null) {
                  final uploadedUrl = await FirebaseEventService.uploadEventImage(event.eventId, mainImageBytes!);
                  if (uploadedUrl != null) {
                    finalImageUrl = uploadedUrl;
                  }
                }
                
                // Upload new additional media if provided
                final finalMediaUrls = <String>[...event.mediaUrls];
                for (int i = 0; i < additionalMediaBytes.length; i++) {
                  final uploadedUrl = await FirebaseEventService.uploadEventMedia(
                    event.eventId,
                    additionalMediaBytes[i],
                    additionalMediaPaths[event.mediaUrls.length + i],
                  );
                  if (uploadedUrl != null) {
                    finalMediaUrls.add(uploadedUrl);
                  }
                }
                
                final updatedEvent = event.copyWith(
                  title: titleController.text,
                  category: selectedCategory,
                  date: selectedDate,
                  venue: venueController.text,
                  price: ticketTiers.isEmpty ? event.price : ticketTiers.first.price,
                  capacity: int.tryParse(capacityController.text) ?? event.capacity,
                  ticketTiers: ticketTiers.isEmpty ? event.ticketTiers : ticketTiers,
                  description: descController.text,
                  imageUrl: finalImageUrl,
                  mediaUrls: finalMediaUrls,
                  paymentOptions: paymentOptions,
                  googleMapsLink: googleMapsController.text.trim().isEmpty ? null : googleMapsController.text.trim(),
                  websiteLink: websiteController.text.trim().isEmpty ? null : websiteController.text.trim(),
                  socialMediaLink: socialMediaController.text.trim().isEmpty ? null : socialMediaController.text.trim(),
                  updatedAt: DateTime.now(),
                );
                
                await EventService.updateEvent(updatedEvent);
                
                // Close loading
                if (!mounted) return;
                Navigator.pop(context);
                
                Navigator.pop(ctx);
                _loadData();
                
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event updated successfully!'), backgroundColor: Colors.green),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
              child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateEventDialog() {
    final titleController = TextEditingController();
    final venueController = TextEditingController();
    final priceController = TextEditingController();
    final capacityController = TextEditingController();
    final descController = TextEditingController();
    final googleMapsController = TextEditingController();
    final websiteController = TextEditingController();
    final socialMediaController = TextEditingController();
    
    final paymentControllers = {
      'Bankily': {'number': TextEditingController(), 'confirm': TextEditingController()},
      'Sedad': {'number': TextEditingController(), 'confirm': TextEditingController()},
      'Bimbank': {'number': TextEditingController(), 'confirm': TextEditingController()},
    };
    final selectedPaymentMethods = <String>{};
    final uploadedMediaFiles = <String>[];
    String? mainImagePath;
    Uint8List? mainImageBytes;
    final additionalMediaPaths = <String>[];
    final additionalMediaBytes = <Uint8List>[];
    final ticketTiers = <TicketTier>[];
    
    String selectedCategory = 'Music';
    bool isPrivateEvent = false;
    bool isFreeEvent = false;
    bool enableAnalytics = false;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    final imageOptions = [
      'assets/images/Music_Concert_null_1760744885951.jpg',
      'assets/images/Sports_Event_null_1760744886724.jpg',
      'assets/images/Cultural_Festival_null_1760744887596.jpg',
      'assets/images/Business_Conference_null_1760744888431.jpg',
    ];
    String selectedImage = imageOptions[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create New Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _currentUser?.isPartner == true ? Colors.green.withValues(alpha: 0.1) : AppConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _currentUser?.isPartner == true ? Colors.green : AppConstants.primaryColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUser?.isPartner == true ? '✅ Partner Status Active' : '📌 Commission Notice',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentUser?.isPartner == true
                            ? 'As a partner organizer, you pay 0% commission. Clients pay: 65 MRU for tickets <500 MRU, or 14% for tickets ≥500 MRU.'
                            : 'Non-partner organizers: You pay 10% commission. Clients pay 10% additional fee.',
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (_currentUser?.isPartner == false) ...[                        const SizedBox(height: 8),
                        const Text('💡 Want 0% commission? Apply for partner status!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Event Title'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: AppConstants.eventCategories.skip(1).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setDialogState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: venueController,
                  decoration: const InputDecoration(labelText: 'Venue'),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: capacityController,
                  builder: (context, value, child) {
                    final hasError = value.text.isNotEmpty && int.tryParse(value.text) == null;
                    return TextField(
                      controller: capacityController,
                      decoration: InputDecoration(
                        labelText: 'Total Capacity',
                        suffixIcon: hasError
                            ? const Icon(Icons.error, color: Colors.red, size: 20)
                            : null,
                      ),
                      keyboardType: TextInputType.number,
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text('Event Settings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppConstants.greyColor.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<bool>(
                        title: const Text('Public Event', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Visible in marketplace to all users', style: TextStyle(fontSize: 12, color: AppConstants.greyColor)),
                        value: false,
                        groupValue: isPrivateEvent,
                        activeColor: AppConstants.primaryColor,
                        onChanged: (val) => setDialogState(() => isPrivateEvent = false),
                      ),
                      const Divider(height: 1),
                      RadioListTile<bool>(
                        title: const Text('Private Event', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Only accessible via invitation link/QR code', style: TextStyle(fontSize: 12, color: AppConstants.greyColor)),
                        value: true,
                        groupValue: isPrivateEvent,
                        activeColor: Colors.purple,
                        onChanged: (val) => setDialogState(() => isPrivateEvent = true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: isFreeEvent ? Colors.green : AppConstants.greyColor.withValues(alpha: 0.3), width: isFreeEvent ? 2 : 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: const Text('Free Event', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('No payment required for tickets', style: TextStyle(fontSize: 12, color: AppConstants.greyColor)),
                    value: isFreeEvent,
                    activeColor: Colors.green,
                    onChanged: (val) => setDialogState(() => isFreeEvent = val),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text('Ticket Tiers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Create multiple ticket types with different prices and capacities', style: TextStyle(fontSize: 13, color: AppConstants.greyColor)),
                const SizedBox(height: 12),
                _buildTicketTiersSection(setDialogState, ticketTiers),
                const SizedBox(height: 16),
                const Divider(),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: googleMapsController,
                  decoration: const InputDecoration(
                    labelText: 'Google Maps Link (Optional)',
                    hintText: 'https://maps.google.com/...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: websiteController,
                  decoration: const InputDecoration(
                    labelText: 'Website Link (Optional)',
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: socialMediaController,
                  decoration: const InputDecoration(
                    labelText: 'Social Media Link (Optional)',
                    hintText: 'Instagram, Facebook, etc.',
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text('Event Image', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Upload a main image for your event', style: TextStyle(fontSize: 13, color: AppConstants.greyColor)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppConstants.greyColor.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              allowMultiple: false,
                              withData: true,
                            );
                            if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
                              setDialogState(() {
                                mainImagePath = result.files.first.name;
                                mainImageBytes = result.files.first.bytes;
                              });
                            }
                          },
                          icon: const Icon(Icons.upload, size: 16),
                          label: const Text('Upload Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (mainImagePath != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  mainImagePath!,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () => setDialogState(() {
                                  mainImagePath = null;
                                  mainImageBytes = null;
                                }),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isFreeEvent) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  Row(
                    children: [
                      const Text('Payment Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      const Text('*', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Select at least one payment method and enter your number:', style: TextStyle(fontSize: 13, color: AppConstants.greyColor)),
                  const SizedBox(height: 8),
                  if (selectedPaymentMethods.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'At least one payment method is required',
                              style: TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  ...['Bankily', 'Sedad', 'Bimbank'].map((method) {
                    final isSelected = selectedPaymentMethods.contains(method);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? AppConstants.primaryColor : AppConstants.greyColor.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            title: Text(method, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            value: isSelected,
                            activeColor: AppConstants.primaryColor,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  selectedPaymentMethods.add(method);
                                } else {
                                  selectedPaymentMethods.remove(method);
                                  paymentControllers[method]!['number']!.clear();
                                  paymentControllers[method]!['confirm']!.clear();
                                }
                              });
                            },
                          ),
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: paymentControllers[method]!['number'],
                                    decoration: InputDecoration(
                                      labelText: 'Enter $method Number',
                                      hintText: '+222 XX XX XX XX',
                                      prefixIcon: const Icon(Icons.phone_android),
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: paymentControllers[method]!['confirm'],
                                    decoration: InputDecoration(
                                      labelText: 'Confirm $method Number',
                                      hintText: '+222 XX XX XX XX',
                                      prefixIcon: const Icon(Icons.check_circle),
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || venueController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all required fields'), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                // Validate payment options (skip if free event)
                final paymentOptions = <PaymentOption>[];
                if (!isFreeEvent) {
                for (final method in selectedPaymentMethods) {
                  final numberController = paymentControllers[method]!['number']!;
                  final confirmController = paymentControllers[method]!['confirm']!;
                  
                  if (numberController.text.trim().isEmpty || confirmController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please fill both fields for $method'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  
                  if (numberController.text.trim() != confirmController.text.trim()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$method numbers do not match'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  
                  paymentOptions.add(PaymentOption(provider: method, accountNumber: numberController.text.trim()));
                }
                
                  if (paymentOptions.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please add at least one payment method'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                }
                
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor)),
                );
                
                final now = DateTime.now();
                final eventId = 'evt_${now.millisecondsSinceEpoch}';
                final privateCode = isPrivateEvent ? EventService.generatePrivateEventCode() : null;
                
                // Upload main image if provided
                String finalImageUrl = selectedImage;
                if (mainImageBytes != null) {
                  final uploadedUrl = await FirebaseEventService.uploadEventImage(eventId, mainImageBytes!);
                  if (uploadedUrl != null) {
                    finalImageUrl = uploadedUrl;
                  }
                }
                
                // Upload additional media if provided
                final uploadedMediaUrls = <String>[];
                for (int i = 0; i < additionalMediaBytes.length; i++) {
                  final uploadedUrl = await FirebaseEventService.uploadEventMedia(
                    eventId,
                    additionalMediaBytes[i],
                    additionalMediaPaths[i],
                  );
                  if (uploadedUrl != null) {
                    uploadedMediaUrls.add(uploadedUrl);
                  }
                }
                
                // Handle ticket tiers - require at least one tier
                if (ticketTiers.isEmpty) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please add at least one ticket tier'), backgroundColor: Colors.red, duration: Duration(seconds: 4)),
                  );
                  return;
                }
                
                // Validate that total tier capacity doesn't exceed event capacity
                final totalCapacity = int.tryParse(capacityController.text) ?? 0;
                final totalTierCapacity = ticketTiers.fold<int>(0, (sum, tier) => sum + tier.capacity);
                
                if (totalTierCapacity > totalCapacity) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Total ticket tier capacity ($totalTierCapacity) cannot exceed event capacity ($totalCapacity)'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                  return;
                }
                
                final finalTicketTiers = ticketTiers;
                
                final event = EventModel(
                  eventId: eventId,
                  title: titleController.text,
                  category: selectedCategory,
                  date: selectedDate,
                  venue: venueController.text,
                  price: finalTicketTiers.first.price,
                  capacity: int.tryParse(capacityController.text) ?? 100,
                  ticketTiers: finalTicketTiers,
                  organizerId: _currentUser!.userId,
                  description: descController.text,
                  imageUrl: finalImageUrl,
                  paymentOptions: paymentOptions,
                  googleMapsLink: googleMapsController.text.trim().isEmpty ? null : googleMapsController.text.trim(),
                  websiteLink: websiteController.text.trim().isEmpty ? null : websiteController.text.trim(),
                  socialMediaLink: socialMediaController.text.trim().isEmpty ? null : socialMediaController.text.trim(),
                  mediaUrls: uploadedMediaUrls,
                  isPrivate: isPrivateEvent,
                  privateEventCode: privateCode,
                  createdAt: now,
                  updatedAt: now,
                );
                
                await EventService.createEvent(event);
                
                // Close loading dialog
                if (!mounted) return;
                Navigator.pop(context);
                
                // Generate security credentials for this event
                final securityUsername = 'security_${event.eventId.substring(4, 10)}';
                final securityPassword = 'sec${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                
                // Create a real user account for security staff so they can login
                final securityUserId = 'sec_${DateTime.now().millisecondsSinceEpoch}';
                final securityUser = AppUser(
                  userId: securityUserId,
                  name: 'Security - ${event.title}',
                  phoneNumber: securityUsername, // Use username as phone number for security
                  username: securityUsername,
                  passwordHash: AuthService.hashPassword(securityPassword),
                  role: UserRole.security,
                  joinedDate: DateTime.now(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                await StorageService.saveData(StorageService.usersBox, securityUser.userId, securityUser.toJson());
                
                // Also store in security staff table for event tracking
                final securityStaff = SecurityStaff(
                  staffId: securityUserId,
                  eventId: event.eventId,
                  userId: securityUserId,
                  username: securityUsername,
                  tempPassword: securityPassword,
                  createdAt: DateTime.now(),
                );
                
                await StorageService.saveData(StorageService.securityBox, securityStaff.staffId, securityStaff.toJson());
                
                Navigator.pop(ctx);
                _loadData();
                
                // Show success dialog with private event details or security credentials
                if (isPrivateEvent) {
                  _showPrivateEventSuccessDialog(event);
                } else {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Event Created!', style: TextStyle(color: Colors.green)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your event has been created successfully!', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          const Text('Security Team Login:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppConstants.primaryColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Username: $securityUsername', style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Password: $securityPassword', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('⚠️ Save these credentials! Your security team will need them to scan tickets.', style: TextStyle(fontSize: 12, color: Colors.red, fontStyle: FontStyle.italic)),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
                          child: const Text('Got it!', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
              child: const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetails(EventModel event) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(event.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Category: ${event.category}'),
              Text('Date: ${DateFormat('dd MMM yyyy, HH:mm').format(event.date)}'),
              Text('Venue: ${event.venue}'),
              Text('Price: ${event.price} MRU'),
              Text('Capacity: ${event.capacity}'),
              const SizedBox(height: 8),
              Text(event.description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEventAnalytics(EventModel event) {
    // Check if user has premium analytics access
    final now = DateTime.now();
    final hasAccess = _currentUser?.hasPremiumAnalytics == true && 
                      _currentUser?.premiumExpiryDate?.isAfter(now) == true;
    
    // Calculate days remaining in free trial (2 months from account creation)
    final accountCreatedDate = _currentUser?.createdAt ?? now;
    final freeTrialEndDate = accountCreatedDate.add(const Duration(days: 60));
    final daysRemaining = freeTrialEndDate.difference(now).inDays;
    final isInFreeTrial = daysRemaining > 0;
    
    if (!hasAccess && !isInFreeTrial) {
      _showPremiumPaywall();
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventAnalyticsScreen(event: event, user: _currentUser!, isInFreeTrial: isInFreeTrial, daysRemaining: daysRemaining),
      ),
    );
  }
  
  void _showPremiumPaywall() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: AppConstants.primaryColor, size: 28),
            SizedBox(width: 8),
            Text('Premium Analytics'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your free 2-month analytics trial has ended.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text('Unlock premium analytics to access:'),
            const SizedBox(height: 12),
            _buildPaywallFeature('📊 Detailed event analytics'),
            _buildPaywallFeature('👥 Audience demographics'),
            _buildPaywallFeature('💰 Revenue tracking'),
            _buildPaywallFeature('📈 Real-time attendance data'),
            const SizedBox(height: 16),
            const Text('Choose your plan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppConstants.primaryColor),
              ),
              child: const Column(
                children: [
                  Text('Per Event Unlock', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                  SizedBox(height: 4),
                  Text('5,000 MRU', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.textColor)),
                  SizedBox(height: 4),
                  Text('Unlock analytics for one event', style: TextStyle(fontSize: 12, color: AppConstants.greyColor)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Monthly Subscription', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                      SizedBox(width: 8),
                      Icon(Icons.star, color: Colors.amber, size: 20),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text('20,000 MRU / month', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.textColor)),
                  SizedBox(height: 4),
                  Text('Unlimited analytics for all events', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showUpgradePaymentDialog(null);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
            child: const Text('Choose Plan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaywallFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
  
  void _showUpgradePaymentDialog(EventModel? event) {
    String selectedPlan = 'monthly';
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Unlock Premium Analytics'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select your plan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setDialogState(() => selectedPlan = 'per_event'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selectedPlan == 'per_event' ? AppConstants.primaryColor.withValues(alpha: 0.1) : Colors.white,
                      border: Border.all(color: selectedPlan == 'per_event' ? AppConstants.primaryColor : AppConstants.greyColor.withValues(alpha: 0.3), width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Per Event Unlock', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                              const Text('5,000 MRU', style: TextStyle(fontSize: 18, color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
                              if (event != null) Text('Unlock analytics for "${event.title}"', style: const TextStyle(fontSize: 11, color: AppConstants.greyColor)),
                            ],
                          ),
                        ),
                        if (selectedPlan == 'per_event') const Icon(Icons.check_circle, color: AppConstants.primaryColor, size: 28),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => setDialogState(() => selectedPlan = 'monthly'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selectedPlan == 'monthly' ? Colors.green.withValues(alpha: 0.1) : Colors.white,
                      border: Border.all(color: selectedPlan == 'monthly' ? Colors.green : AppConstants.greyColor.withValues(alpha: 0.3), width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text('Monthly Subscription', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                ],
                              ),
                              const Text('20,000 MRU / month', style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)),
                              const Text('Unlimited analytics for all events', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        if (selectedPlan == 'monthly') const Icon(Icons.check_circle, color: Colors.green, size: 28),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Send payment to:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                _buildPaymentOption('Bankily / Sedad', AppConstants.platformPaymentAccount),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        '1. Send ${selectedPlan == 'per_event' ? '5,000' : '20,000'} MRU to ${AppConstants.platformPaymentAccount}\n2. Screenshot your transaction\n3. Contact support with your username and screenshot\n4. Access will be granted within 24 hours',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentOption(String provider, String number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppConstants.greyColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_android, color: AppConstants.primaryColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(provider, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(number, style: const TextStyle(fontSize: 12, color: AppConstants.greyColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProvidersTab() {
    if (_providers.isEmpty) {
      return const Center(
        child: Text('No service providers available', style: TextStyle(color: AppConstants.greyColor)),
      );
    }

    // Group providers by service type
    final providersByCategory = <String, List<ProviderModel>>{};
    for (final provider in _providers) {
      if (!providersByCategory.containsKey(provider.serviceType)) {
        providersByCategory[provider.serviceType] = [];
      }
      providersByCategory[provider.serviceType]!.add(provider);
    }
    
    final categories = providersByCategory.keys.toList()..sort();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppConstants.primaryColor, AppConstants.primaryColor.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Column(
            children: [
              Icon(Icons.business_center, size: 48, color: Colors.white),
              SizedBox(height: 12),
              Text(
                'Everything You Need for Your Event',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Browse our trusted service providers',
                style: TextStyle(fontSize: 14, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
      itemBuilder: (ctx, index) {
        final category = categories[index];
        final providers = providersByCategory[category]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    category == 'DJ & Music' ? Icons.music_note :
                    category == 'Catering' ? Icons.restaurant :
                    category == 'Lighting' ? Icons.lightbulb :
                    category == 'Sound System' ? Icons.speaker :
                    category == 'Security' ? Icons.security : Icons.business,
                    color: AppConstants.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.textColor),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${providers.length}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
            ...providers.map((provider) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppConstants.primaryColor,
                  child: Icon(
                    category == 'DJ & Music' ? Icons.music_note :
                    category == 'Catering' ? Icons.restaurant :
                    category == 'Lighting' ? Icons.lightbulb :
                    category == 'Sound System' ? Icons.speaker :
                    category == 'Security' ? Icons.security : Icons.business,
                    color: Colors.white,
                  ),
                ),
                title: Text(provider.companyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${provider.serviceType} • ${provider.contactInfo}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(' ${provider.rating}'),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(provider.companyName),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Service: ${provider.serviceType}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(provider.description),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 20),
                              Text(' ${provider.rating} Rating', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('📞 ${provider.contactInfo}', style: const TextStyle(color: AppConstants.primaryColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )).toList(),
            const SizedBox(height: 12),
          ],
        );
      },
          ),
        ),
      ],
    );
  }

  Widget _buildSponsorsTab() {
    final activeEvents = _myEvents.where((e) => e.date.isAfter(DateTime.now())).toList();
    
    if (activeEvents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Create an active event to apply for sponsorships',
            style: TextStyle(color: AppConstants.greyColor, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Event for Sponsorship', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Choose Event',
              border: OutlineInputBorder(),
            ),
            items: activeEvents.map((event) {
              return DropdownMenuItem(
                value: event.eventId,
                child: Text(event.title, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (eventId) {
              if (eventId != null) {
                setState(() => _selectedEventForSponsorship = eventId);
              }
            },
          ),
          const SizedBox(height: 24),
          if (_selectedEventForSponsorship != null) ...[
            _buildSponsorApplicationsCard(_myEvents.firstWhere((e) => e.eventId == _selectedEventForSponsorship)),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            const Text('Available Platform Sponsors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Apply to be sponsored by these companies:', style: TextStyle(fontSize: 13, color: AppConstants.greyColor)),
            const SizedBox(height: 16),
            _buildPlatformSponsorsCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildSponsorApplicationsCard(EventModel event) {
    return FutureBuilder<List<SponsorApplication>>(
      future: SponsorService.getApplicationsByEvent(event.eventId),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        
        final applications = snapshot.data!;
        final pendingCount = applications.where((a) => a.status == SponsorApplicationStatus.pending).length;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: pendingCount > 0 ? Colors.orange : AppConstants.primaryColor,
              child: Text('$pendingCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${applications.length} sponsor application(s)'),
            children: applications.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No sponsor applications yet', style: TextStyle(color: AppConstants.greyColor)),
                    )
                  ]
                : applications.map((app) => _buildApplicationTile(app)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildApplicationTile(SponsorApplication application) {
    Color statusColor;
    switch (application.status) {
      case SponsorApplicationStatus.pending:
        statusColor = Colors.orange;
        break;
      case SponsorApplicationStatus.accepted:
        statusColor = Colors.green;
        break;
      case SponsorApplicationStatus.rejected:
        statusColor = Colors.red;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(application.brandName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  application.status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Budget: ${application.budgetOffered.toStringAsFixed(0)} MRU', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
          const SizedBox(height: 4),
          Text(application.message, style: const TextStyle(fontSize: 13, color: AppConstants.greyColor), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (application.status == SponsorApplicationStatus.pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await SponsorService.rejectApplication(application.applicationId);
                      _loadData();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Application rejected'), backgroundColor: Colors.red),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await SponsorService.acceptApplication(application.applicationId);
                      _loadData();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Application accepted! Sponsor will receive your contact info'), backgroundColor: Colors.green),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Accept', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  void _showBoostEventDialog(EventModel event) {
    int selectedDays = 1;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.rocket_launch, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              const Expanded(child: Text('Boost Event')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Boost your event to appear at the top of the sponsored events section!',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppConstants.primaryColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Benefits:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      _buildBoostBenefit('🎯 Top placement in event listings'),
                      _buildBoostBenefit('👁️ Higher visibility to buyers'),
                      _buildBoostBenefit('📈 Increased ticket sales'),
                      _buildBoostBenefit('⭐ Special "Sponsored" badge'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Select Boost Duration:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...List.generate(7, (index) {
                  final days = index + 1;
                  final cost = days * AppConstants.boostPricePerDay;
                  final isSelected = selectedDays == days;
                  
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedDays = days),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.orange.withValues(alpha: 0.1) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? Colors.orange : AppConstants.greyColor.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$days ${days == 1 ? "Day" : "Days"}',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.orange : AppConstants.textColor,
                            ),
                          ),
                          Text(
                            '${cost.toStringAsFixed(0)} MRU',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.orange : AppConstants.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Total Cost',
                        style: TextStyle(fontSize: 14, color: AppConstants.greyColor),
                      ),
                      Text(
                        '${(selectedDays * AppConstants.boostPricePerDay).toStringAsFixed(0)} MRU',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final totalCost = selectedDays * AppConstants.boostPricePerDay;
                
                // Update event to be sponsored
                final updatedEvent = event.copyWith(
                  isSponsored: true,
                  sponsoredDays: selectedDays,
                  updatedAt: DateTime.now(),
                );
                
                await EventService.updateEvent(updatedEvent);
                
                Navigator.pop(ctx);
                _loadData();
                
                if (!mounted) return;
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 32),
                        SizedBox(width: 8),
                        Text('Event Boosted!'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your event has been successfully boosted!', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Text('Duration: $selectedDays ${selectedDays == 1 ? "day" : "days"}'),
                        Text('Cost: ${totalCost.toStringAsFixed(0)} MRU'),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Instructions:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '1. Send payment to ${AppConstants.platformPaymentAccount} (Bankily)\n2. Screenshot your transaction\n3. Contact support with screenshot\n4. Your boost will be activated within 24 hours',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        child: const Text('Got it!', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Boost Event', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBoostBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppConstants.primaryColor,
                child: Text(_currentUser?.name.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(_currentUser?.name ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_currentUser?.email ?? ''),
            ),
            const Divider(),
            if (_currentUser?.isPartner == false)
              ListTile(
                leading: const Icon(Icons.workspace_premium, color: Colors.blue),
                title: const Text('Apply for Partner Status'),
                subtitle: const Text('Get 0% commission rate', style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await UrlHelper.sendPartnerApplicationEmail(
                    context: context,
                    organizerName: _currentUser?.name ?? '',
                    organizerEmail: _currentUser?.email ?? '',
                    organizerPhone: _currentUser?.phoneNumber ?? '',
                  );
                },
              ),
            if (_currentUser?.isPartner == true)
              ListTile(
                leading: const Icon(Icons.verified, color: Colors.green),
                title: const Text('Partner Status Active'),
                subtitle: const Text('0% commission rate', style: TextStyle(fontSize: 12, color: Colors.green)),
                enabled: false,
              ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: AppConstants.primaryColor),
              title: const Text('Switch to Buyer'),
              onTap: () async {
                Navigator.pop(ctx);
                final updatedUser = _currentUser!.copyWith(role: UserRole.buyer);
                await AuthService.updateUserRole(updatedUser);
                if (!mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BuyerDashboard()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(ctx);
                await AuthService.logout();
                if (!mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformSponsorsCard() {
    final platformSponsors = [
      {
        'name': 'Bankily',
        'category': 'Financial Services',
        'description': 'Leading mobile money platform in Mauritania. Ideal for events with large audiences.',
        'budgetRange': '50,000 - 500,000 MRU',
        'targetAudience': 'Young Adults, Tech-savvy, Urban',
      },
      {
        'name': 'Second Cup',
        'category': 'Food & Beverage',
        'description': 'Premium coffee chain. Perfect for cultural events, business conferences, and art exhibitions.',
        'budgetRange': '30,000 - 200,000 MRU',
        'targetAudience': 'Professionals, Students, Coffee Lovers',
      },
      {
        'name': 'La Mairie de Nouakchott',
        'category': 'Government & Community',
        'description': 'Municipal government. Supports community events, sports, cultural festivals, and education.',
        'budgetRange': '100,000 - 1,000,000 MRU',
        'targetAudience': 'Families, Community, All Ages',
      },
    ];

    return Column(
      children: platformSponsors.map((sponsor) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        sponsor['name']!.substring(0, 1),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(sponsor['name']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(sponsor['category']!, style: const TextStyle(fontSize: 12, color: AppConstants.greyColor)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(sponsor['description']!, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.attach_money, color: AppConstants.primaryColor, size: 18),
                    const SizedBox(width: 4),
                    Text('Budget: ${sponsor['budgetRange']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppConstants.greyColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Target: ${sponsor['targetAudience']}', style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showSponsorApplicationDialog(sponsor['name']!),
                    style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
                    child: const Text('Apply for Sponsorship', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showSponsorApplicationDialog(String sponsorName) {
    if (_selectedEventForSponsorship == null) return;
    
    final event = _myEvents.firstWhere((e) => e.eventId == _selectedEventForSponsorship);
    final brandController = TextEditingController(text: _currentUser?.name ?? '');
    final budgetController = TextEditingController();
    final messageController = TextEditingController(
      text: 'We would like to sponsor ${event.title} with your brand $sponsorName. Looking forward to a successful partnership!',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Apply to $sponsorName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Event: ${event.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: brandController,
                decoration: const InputDecoration(
                  labelText: 'Your Brand/Organization Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: budgetController,
                decoration: const InputDecoration(
                  labelText: 'Requested Budget (MRU)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message to Sponsor',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (brandController.text.isEmpty || budgetController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields'), backgroundColor: Colors.red),
                );
                return;
              }
              
              await SponsorService.submitApplication(
                sponsorId: 'platform_$sponsorName',
                eventId: event.eventId,
                brandName: '$sponsorName → ${brandController.text}',
                budgetOffered: double.tryParse(budgetController.text) ?? 0,
                message: messageController.text,
              );
              
              Navigator.pop(ctx);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Application sent to $sponsorName successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
            child: const Text('Submit Application', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketTiersSection(StateSetter setDialogState, List<TicketTier> ticketTiers) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppConstants.greyColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ticketTiers.isEmpty) ...[
            const Text(
              'No custom ticket tiers added. Default tier will be created with main price/capacity.',
              style: TextStyle(color: AppConstants.greyColor, fontSize: 13),
            ),
            const SizedBox(height: 8),
          ],
          if (ticketTiers.isNotEmpty) ...[
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: ticketTiers.length,
                itemBuilder: (ctx, index) {
                  final tier = ticketTiers[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tier.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('${tier.price} MRU • ${tier.capacity} tickets', 
                                style: const TextStyle(fontSize: 12, color: AppConstants.greyColor)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                          onPressed: () => setDialogState(() => ticketTiers.removeAt(index)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddTicketTierDialog(context, setDialogState, ticketTiers),
              icon: const Icon(Icons.add, size: 16),
              label: Text(ticketTiers.isEmpty ? 'Add Ticket Tier' : 'Add Another Tier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTicketTierDialog(BuildContext dialogContext, StateSetter parentSetState, List<TicketTier> ticketTiers) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final capacityController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Ticket Tier'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tier Name',
                  hintText: 'e.g., VIP, Standard, Backstage',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: priceController,
                builder: (context, value, child) {
                  final hasError = value.text.isNotEmpty && double.tryParse(value.text) == null;
                  return TextField(
                    controller: priceController,
                    decoration: InputDecoration(
                      labelText: 'Price (MRU)',
                      border: const OutlineInputBorder(),
                      suffixIcon: hasError
                          ? const Icon(Icons.error, color: Colors.red, size: 20)
                          : null,
                    ),
                    keyboardType: TextInputType.number,
                  );
                },
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: capacityController,
                builder: (context, value, child) {
                  final hasError = value.text.isNotEmpty && int.tryParse(value.text) == null;
                  return TextField(
                    controller: capacityController,
                    decoration: InputDecoration(
                      labelText: 'Capacity',
                      border: const OutlineInputBorder(),
                      suffixIcon: hasError
                          ? const Icon(Icons.error, color: Colors.red, size: 20)
                          : null,
                    ),
                    keyboardType: TextInputType.number,
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty || 
                  priceController.text.isEmpty || 
                  capacityController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.red, duration: Duration(seconds: 4)),
                );
                return;
              }
              
              final price = double.tryParse(priceController.text);
              final capacity = int.tryParse(capacityController.text);
              
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid price'), backgroundColor: Colors.red, duration: Duration(seconds: 4)),
                );
                return;
              }
              
              if (capacity == null || capacity <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid capacity'), backgroundColor: Colors.red, duration: Duration(seconds: 4)),
                );
                return;
              }

              final newTier = TicketTier(
                name: nameController.text,
                price: price,
                capacity: capacity,
              );

              parentSetState(() => ticketTiers.add(newTier));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
            child: const Text('Add Tier', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMediaSection(StateSetter setDialogState, String? mainImagePath, List<String> additionalMediaPaths) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppConstants.greyColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Main Event Image', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                      allowMultiple: false,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      setDialogState(() {
                        mainImagePath = result.files.first.name;
                      });
                    }
                  },
                  icon: const Icon(Icons.upload, size: 16),
                  label: const Text('Change Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          if (mainImagePath != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'New: $mainImagePath',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setDialogState(() => mainImagePath = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Additional Media', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.media,
                      allowMultiple: true,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      setDialogState(() {
                        additionalMediaPaths.addAll(result.files.map((f) => f.name));
                      });
                    }
                  },
                  icon: const Icon(Icons.add_photo_alternate, size: 16),
                  label: const Text('Add Media'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          if (additionalMediaPaths.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: additionalMediaPaths.length,
                itemBuilder: (ctx, index) {
                  final mediaPath = additionalMediaPaths[index];
                  final isVideo = mediaPath.toLowerCase().endsWith('.mp4') || 
                                 mediaPath.toLowerCase().endsWith('.mov') || 
                                 mediaPath.toLowerCase().endsWith('.avi');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isVideo ? Icons.videocam : Icons.image,
                          color: AppConstants.primaryColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            mediaPath,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                          onPressed: () {
                            setDialogState(() => additionalMediaPaths.removeAt(index));
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BarcodeScannerScreen extends StatefulWidget {
  final String eventId;
  const BarcodeScannerScreen({super.key, required this.eventId});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Ticket Barcode'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) async {
          if (_isProcessing) return;
          
          final barcodes = capture.barcodes;
          if (barcodes.isEmpty) return;
          
          final barcodeData = barcodes.first.rawValue;
          if (barcodeData == null) return;
          
          setState(() => _isProcessing = true);
          
          final isValid = await TicketService.validateTicket(barcodeData, widget.eventId);
          
          if (!mounted) return;
          
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(isValid ? 'Valid Ticket' : 'Invalid Ticket'),
              content: Text(isValid
                  ? 'Ticket validated successfully!'
                  : 'This ticket is invalid, already used, or doesn\'t match this event.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _isProcessing = false);
                  },
                  child: const Text('Continue Scanning'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class EventAnalyticsScreen extends StatelessWidget {
  final EventModel event;
  final AppUser user;
  final bool isInFreeTrial;
  final int daysRemaining;
  
  const EventAnalyticsScreen({
    super.key,
    required this.event,
    required this.user,
    required this.isInFreeTrial,
    required this.daysRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Analytics'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: TicketService.getEventAnalytics(event.eventId),
        builder: (ctx, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor));
          }
          
          final analytics = snapshot.data!;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isInFreeTrial) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppConstants.primaryColor.withValues(alpha: 0.1),
                          Colors.orange.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppConstants.primaryColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: AppConstants.primaryColor, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Free Trial Active',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                '$daysRemaining days remaining in your 2-month free trial',
                                style: const TextStyle(fontSize: 13, color: AppConstants.greyColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(event.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _buildAnalyticsGrid(analytics),
                const SizedBox(height: 24),
                const Text('Event Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildDetailItem('Date', DateFormat('dd MMM yyyy, HH:mm').format(event.date)),
                _buildDetailItem('Venue', event.venue),
                _buildDetailItem('Category', event.category),
                _buildDetailItem('Ticket Price', '${event.price} MRU'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsGrid(Map<String, dynamic> analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildAnalyticsBox('Total Sales', '${analytics['totalSales']}', Icons.confirmation_number, Colors.blue),
            _buildAnalyticsBox('Revenue', '${analytics['revenue'].toStringAsFixed(0)} MRU', Icons.attach_money, Colors.green),
            _buildAnalyticsBox('Attendance', '${analytics['attendance']}', Icons.check_circle, Colors.orange),
            _buildAnalyticsBox('Available', '${analytics['availableTickets']}', Icons.event_seat, Colors.purple),
          ],
        ),
        const SizedBox(height: 32),
        const Text('Ticket Purchase Patterns', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildPurchaseTimeGraph('Purchase Times by Hour', analytics['purchaseTimesByHour'] ?? {}, true),
        const SizedBox(height: 16),
        _buildPurchaseTimeGraph('Purchase Times by Day', analytics['purchaseTimesByDay'] ?? {}, false),
        const SizedBox(height: 32),
        const Text('Audience Demographics', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildDemographicsSection('Age Groups', analytics['ageGroups'] ?? {}, Icons.cake),
        const SizedBox(height: 16),
        _buildDemographicsSection('Gender Distribution', analytics['genderDistribution'] ?? {}, Icons.people),
        const SizedBox(height: 16),
        _buildDemographicsSection('Top Neighborhoods', analytics['neighborhoods'] ?? {}, Icons.location_city),
      ],
    );
  }
  
  Widget _buildPurchaseTimeGraph(String title, Map<dynamic, int> data, bool isHourly) {
    if (data.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.show_chart, color: AppConstants.greyColor),
              const SizedBox(width: 12),
              Text('$title: No data yet', style: const TextStyle(color: AppConstants.greyColor)),
            ],
          ),
        ),
      );
    }
    
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);
    final peakKey = data.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: AppConstants.primaryColor, size: 24),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Peak: ${isHourly ? "${peakKey}:00" : peakKey} with ${data[peakKey]} tickets',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: isHourly ? _buildHourlyChart(data, maxValue, peakKey as int) : _buildDailyChart(data, maxValue, peakKey as String),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHourlyChart(Map<dynamic, int> data, int maxValue, int peakHour) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(24, (index) {
        final count = data[index] ?? 0;
        final height = maxValue > 0 ? (count / maxValue * 160) : 0.0;
        final isPeak = index == peakHour;
        
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (count > 0)
                Text('$count', style: TextStyle(fontSize: 10, fontWeight: isPeak ? FontWeight.bold : FontWeight.normal, color: isPeak ? Colors.orange : AppConstants.greyColor)),
              const SizedBox(height: 4),
              Container(
                height: height.clamp(4.0, 160.0),
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: isPeak ? Colors.orange : AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isPeak ? [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ] : null,
                ),
              ),
              const SizedBox(height: 4),
              if (index % 3 == 0)
                Text('$index', style: const TextStyle(fontSize: 10, color: AppConstants.greyColor)),
            ],
          ),
        );
      }),
    );
  }
  
  Widget _buildDailyChart(Map<dynamic, int> data, int maxValue, String peakDay) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: dayNames.map((day) {
        final count = data[day] ?? 0;
        final height = maxValue > 0 ? (count / maxValue * 160) : 0.0;
        final isPeak = day == peakDay;
        
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (count > 0)
                Text('$count', style: TextStyle(fontSize: 12, fontWeight: isPeak ? FontWeight.bold : FontWeight.normal, color: isPeak ? Colors.orange : AppConstants.greyColor)),
              const SizedBox(height: 4),
              Container(
                height: height.clamp(4.0, 160.0),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isPeak ? Colors.orange : AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isPeak ? [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ] : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(day, style: TextStyle(fontSize: 11, fontWeight: isPeak ? FontWeight.bold : FontWeight.normal, color: isPeak ? Colors.orange : AppConstants.greyColor)),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildDemographicsSection(String title, Map<String, int> data, IconData icon) {
    if (data.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppConstants.greyColor),
              const SizedBox(width: 12),
              Text('$title: No data yet', style: const TextStyle(color: AppConstants.greyColor)),
            ],
          ),
        ),
      );
    }
    
    final sortedEntries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = data.values.fold<int>(0, (sum, count) => sum + count);
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppConstants.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...sortedEntries.map((entry) {
              final percentage = (entry.value / total * 100).toStringAsFixed(1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: const TextStyle(fontSize: 14)),
                        Text('${entry.value} ($percentage%)', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: entry.value / total,
                      backgroundColor: AppConstants.greyColor.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

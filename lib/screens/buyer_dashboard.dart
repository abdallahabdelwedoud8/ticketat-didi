import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eventide/utils/constants.dart';
import 'package:eventide/utils/share_helper.dart';
import 'package:eventide/utils/image_helper.dart';
import 'package:eventide/models/app_models.dart';
import 'package:eventide/services/auth_service.dart';
import 'package:eventide/services/event_service.dart';
import 'package:eventide/services/ticket_service.dart';
import 'package:eventide/screens/auth_screen.dart';
import 'package:eventide/screens/payment_screen.dart';
import 'package:eventide/screens/organizer_dashboard.dart';
import 'package:intl/intl.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  int _currentIndex = 0;
  AppUser? _currentUser;
  List<EventModel> _events = [];
  List<EventModel> _filteredEvents = [];
  List<TicketModel> _tickets = [];
  List<EventModel> _recommendations = [];
  List<EventModel> _sponsoredEvents = [];
  Set<String> _favoriteEventIds = {};
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _currentUser = await AuthService.getCurrentUser();
    _events = await EventService.getPublicEvents();
    _filteredEvents = _events;
    
    if (_currentUser != null) {
      _tickets = await TicketService.getUserTickets(_currentUser!.userId);
      _recommendations = await EventService.getRecommendations(_currentUser!.preferences);
      _sponsoredEvents = await EventService.getSponsoredEvents();
    }
    
    setState(() => _isLoading = false);
  }

  void _filterEvents(String category) {
    setState(() {
      _selectedCategory = category;
      _filteredEvents = category == 'All'
          ? _events
          : _events.where((e) => e.category == category).toList();
    });
  }

  void _searchEvents(String query) async {
    if (query.isEmpty) {
      setState(() => _filteredEvents = _events);
      return;
    }
    final results = await EventService.searchEvents(query);
    setState(() => _filteredEvents = results);
  }

  Future<void> _purchaseTicket(EventModel event) async {
    if (_currentUser == null) return;
    
    int selectedQuantity = 1;
    TicketTier? selectedTier;
    
    // Calculate max allowed tickets for this user & event (hard limit of 6)
    final userTickets = _tickets.where((t) => t.eventId == event.eventId).length;
    final remainingAllowed = AppConstants.maxTicketsPerUserPerEvent - userTickets;
    final maxAllowed = remainingAllowed.clamp(0, AppConstants.maxTicketsPerPurchase);
    
    if (maxAllowed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have reached the maximum ticket limit for this event (6 tickets per user)'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final availableTiers = event.ticketTiers.where((t) => t.soldTickets < t.capacity).toList();
          
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: AppConstants.whiteColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ImageHelper.buildImage(event.imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 24),
                        Text(event.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 14, color: AppConstants.greyColor),
                            const SizedBox(width: 6),
                            Text(DateFormat('EEEE, dd MMMM yyyy').format(event.date), style: TextStyle(fontSize: 14, color: AppConstants.greyColor.withValues(alpha: 0.9))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (event.googleMapsLink != null && event.googleMapsLink!.isNotEmpty) ...
                        [
                          InkWell(
                            onTap: () async {
                              final uri = Uri.parse(event.googleMapsLink!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: AppConstants.primaryColor),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    event.venue,
                                    style: const TextStyle(fontSize: 14, color: AppConstants.primaryColor, decoration: TextDecoration.underline),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                        else ...
                        [
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: AppConstants.greyColor),
                              const SizedBox(width: 6),
                              Expanded(child: Text(event.venue, style: TextStyle(fontSize: 14, color: AppConstants.greyColor.withValues(alpha: 0.9)))),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.people, size: 16, color: AppConstants.greyColor),
                            const SizedBox(width: 6),
                            Text('${event.soldTickets} people joined', style: TextStyle(fontSize: 14, color: AppConstants.greyColor.withValues(alpha: 0.9))),
                          ],
                        ),
                        
                        if (availableTiers.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text('Select Ticket Tier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          ...availableTiers.map((tier) {
                            final isSelected = selectedTier == tier;
                            return InkWell(
                              onTap: () => setModalState(() => selectedTier = tier),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppConstants.primaryColor.withValues(alpha: 0.1) : Colors.white,
                                  border: Border.all(color: isSelected ? AppConstants.primaryColor : AppConstants.greyColor.withValues(alpha: 0.3), width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(tier.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                          Text(
                                            event.isFreeEvent ? 'FREE' : '${tier.price.toStringAsFixed(0)} MRU',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: event.isFreeEvent ? Colors.green : AppConstants.primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text('${tier.capacity - tier.soldTickets} tickets remaining', style: const TextStyle(fontSize: 12, color: AppConstants.greyColor)),
                                        ],
                                      ),
                                    ),
                                    if (isSelected) const Icon(Icons.check_circle, color: AppConstants.primaryColor, size: 28),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ] else if (event.isFreeEvent) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green, width: 2),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'This is a FREE event! No payment required.',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        Text('How many tickets (Max: $maxAllowed)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 2.5,
                          ),
                          itemCount: maxAllowed,
                          itemBuilder: (ctx, index) {
                            final quantity = index + 1;
                            final isSelected = quantity == selectedQuantity;
                            return InkWell(
                              onTap: () => setModalState(() => selectedQuantity = quantity),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? AppConstants.primaryColor : AppConstants.whiteColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppConstants.greyColor.withValues(alpha: 0.3)),
                                ),
                                child: Center(
                                  child: Text('$quantity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? AppConstants.whiteColor : AppConstants.textColor)),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              // Only require tier selection if there are tiers and event is not free
                              if (availableTiers.isNotEmpty && selectedTier == null && !event.isFreeEvent) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please select a ticket tier'),
                                    backgroundColor: Colors.red,
                                    duration: Duration(seconds: 4),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }
                              
                              Navigator.pop(ctx);
                              
                              // For free events, directly create tickets without payment
                              if (event.isFreeEvent || (selectedTier != null && selectedTier!.price == 0)) {
                                try {
                                  final ticket = await TicketService.purchaseTicket(
                                    _currentUser!.userId,
                                    event.eventId,
                                    tierName: selectedTier?.name,
                                    quantity: selectedQuantity,
                                  );
                                  
                                  if (ticket != null) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Ticket obtained successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    _loadData();
                                  } else {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to get ticket. Event may be sold out.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }
                              
                              // For paid events, go to payment screen
                              final ticketPrice = selectedTier?.price ?? event.price;
                              final discountRate = !_currentUser!.firstPurchaseUsed ? AppConstants.firstPurchaseDiscount : 0.0;
                              
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PaymentScreen(
                                    event: event,
                                    quantity: selectedQuantity,
                                    totalPrice: ticketPrice,
                                    discount: discountRate,
                                    userId: _currentUser!.userId,
                                    selectedTierName: selectedTier?.name,
                                  ),
                                ),
                              );
                              
                              if (result == true) {
                                _loadData();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: event.isFreeEvent ? Colors.green : AppConstants.textColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: Text(
                              event.isFreeEvent ? 'Get Ticket' : 'Continue to Payment',
                              style: const TextStyle(color: AppConstants.whiteColor, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.creamyBg,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: AppConstants.creamyBg,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
          : _buildBody(),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: () => _switchRole(UserRole.organizer),
        backgroundColor: AppConstants.primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
            _buildNavIcon(Icons.home_rounded, 0),
            _buildNavIcon(Icons.confirmation_number_outlined, 1),
            _buildNavIcon(Icons.person, 2),
          ],
        ),
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
        return _buildHomeTab();
      case 1:
        return _buildTicketsTab();
      case 2:
        return _buildProvidersTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 20, right: 20, bottom: 0),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppConstants.primaryColor,
                    radius: 20,
                    child: Text(_currentUser?.name.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, color: AppConstants.textColor, size: 28),
                    onPressed: () => _showMenu(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello ${_currentUser?.name.split(' ').first ?? 'there'}!', style: const TextStyle(fontSize: 14, color: AppConstants.greyColor)),
                  const SizedBox(height: 4),
                  const Text('Discover Amazing Events', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppConstants.textColor)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              onChanged: _searchEvents,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: AppConstants.greyColor.withValues(alpha: 0.5), fontSize: 15),
                prefixIcon: Icon(Icons.search, color: AppConstants.greyColor.withValues(alpha: 0.5), size: 22),
                filled: true,
                fillColor: AppConstants.whiteColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: AppConstants.greyColor.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: AppConstants.greyColor.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: AppConstants.primaryColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
            ),
            const SizedBox(height: 40),
            if (_sponsoredEvents.isNotEmpty) ...[
              const Text('Sponsored events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppConstants.greyColor)),
              const SizedBox(height: 20),
              SizedBox(
                height: 280,
                child: _SponsoredCarousel(events: _sponsoredEvents, onTap: _purchaseTicket),
              ),
              const SizedBox(height: 32),
            ],
            const Text('Upcoming events', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppConstants.greyColor)),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: AppConstants.eventCategories.length,
                itemBuilder: (ctx, index) {
                  final category = AppConstants.eventCategories[index];
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (_) => _filterEvents(category),
                      selectedColor: AppConstants.primaryColor,
                      backgroundColor: AppConstants.whiteColor,
                      side: BorderSide(color: AppConstants.greyColor.withValues(alpha: 0.3)),
                      labelStyle: TextStyle(
                        color: isSelected ? AppConstants.whiteColor : AppConstants.textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.lightbulb, color: AppConstants.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  const Text('Recommended for You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recommendations.length,
                  itemBuilder: (ctx, index) => _buildEventCardHorizontal(_recommendations[index]),
                ),
              ),
            ],
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredEvents.length,
              itemBuilder: (ctx, index) => _buildEventCard(_filteredEvents[index]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    return InkWell(
      onTap: () => _purchaseTicket(event),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: ImageHelper.buildImage(event.imageUrl, height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                        ),
                        child: Column(
                          children: [
                            Text(DateFormat('d').format(event.date), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.textColor)),
                            Text(DateFormat('MMM').format(event.date), style: const TextStyle(fontSize: 12, color: AppConstants.greyColor)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_favoriteEventIds.contains(event.eventId)) {
                              _favoriteEventIds.remove(event.eventId);
                            } else {
                              _favoriteEventIds.add(event.eventId);
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_favoriteEventIds.contains(event.eventId) ? 'Added to favorites' : 'Removed from favorites'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                          ),
                          child: Icon(
                            _favoriteEventIds.contains(event.eventId) ? Icons.favorite : Icons.favorite_border,
                            color: _favoriteEventIds.contains(event.eventId) ? Colors.red : AppConstants.primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppConstants.greyColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.venue,
                          style: TextStyle(color: AppConstants.greyColor.withValues(alpha: 0.9), fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCardHorizontal(EventModel event) {
    return InkWell(
      onTap: () => _purchaseTicket(event),
      child: Card(
        margin: const EdgeInsets.only(right: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: SizedBox(
          width: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: ImageHelper.buildImage(event.imageUrl, height: 140, width: 180, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(DateFormat('d').format(event.date), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(DateFormat('MMM').format(event.date), style: const TextStyle(fontSize: 10, color: AppConstants.greyColor)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 12, color: AppConstants.greyColor),
                        const SizedBox(width: 2),
                        Expanded(child: Text(event.venue, style: TextStyle(fontSize: 12, color: AppConstants.greyColor.withValues(alpha: 0.9)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSponsoredCard3D(EventModel event) {
    return InkWell(
      onTap: () => _purchaseTicket(event),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Image.asset(
                event.imageUrl,
                height: 280,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
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
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('dd MMMM - ').format(event.date) + event.venue,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketsTab() {
    return _TicketTabView(tickets: _tickets, currentUser: _currentUser);
  }

  Widget _buildProvidersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile & Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppConstants.primaryColor,
                child: Text(_currentUser?.name.substring(0, 1).toUpperCase() ?? 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(_currentUser?.name ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text(_currentUser?.email ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: AppConstants.primaryColor),
                onPressed: _showEditProfile,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Switch Role', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildRoleSwitchCard(
            'Buyer Mode',
            'Browse and buy tickets for events',
            Icons.shopping_bag,
            _currentUser?.role == UserRole.buyer,
            () => _switchRole(UserRole.buyer),
          ),
          const SizedBox(height: 12),
          _buildRoleSwitchCard(
            'Organizer Mode',
            'Create and manage your events',
            Icons.event,
            _currentUser?.role == UserRole.organizer,
            () => _switchRole(UserRole.organizer),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await AuthService.logout();
                if (!mounted) return;
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSwitchCard(String title, String subtitle, IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? AppConstants.primaryColor.withValues(alpha: 0.1) : Colors.white,
          border: Border.all(color: isActive ? AppConstants.primaryColor : AppConstants.greyColor.withValues(alpha: 0.3), width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppConstants.primaryColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppConstants.greyColor)),
                ],
              ),
            ),
            if (isActive) const Icon(Icons.check_circle, color: AppConstants.primaryColor, size: 28),
          ],
        ),
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
            ListTile(
              leading: const Icon(Icons.person, color: AppConstants.primaryColor),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(ctx);
                _showProfileDetails();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppConstants.primaryColor),
              title: const Text('Edit Account'),
              onTap: () {
                Navigator.pop(ctx);
                _showEditProfile();
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: const Text('Favorite Events'),
              trailing: _favoriteEventIds.isNotEmpty ? CircleAvatar(
                backgroundColor: Colors.red,
                radius: 12,
                child: Text('${_favoriteEventIds.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ) : null,
              onTap: () {
                Navigator.pop(ctx);
                _showFavoriteEvents();
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: AppConstants.primaryColor),
              title: const Text('Switch to Organizer'),
              onTap: () {
                Navigator.pop(ctx);
                _switchRole(UserRole.organizer);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () async {
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

  void _showProfileDetails() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileItem('Name', _currentUser?.name ?? 'N/A'),
              _buildProfileItem('Email', _currentUser?.email ?? 'N/A'),
              _buildProfileItem('Birthday', _currentUser?.birthday != null ? DateFormat('dd/MM/yyyy').format(_currentUser!.birthday!) : 'Not set'),
              _buildProfileItem('Gender', _currentUser?.gender ?? 'Not set'),
              _buildProfileItem('Neighborhood', _currentUser?.neighborhood ?? 'Not set'),
              _buildProfileItem('Joined', DateFormat('dd MMM yyyy').format(_currentUser?.joinedDate ?? DateTime.now())),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showEditProfile();
            },
            child: const Text('Edit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppConstants.greyColor.withValues(alpha: 0.8))),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showEditProfile() {
    final nameController = TextEditingController(text: _currentUser?.name);
    final usernameController = TextEditingController(text: _currentUser?.username);
    final phoneController = TextEditingController(text: _currentUser?.phoneNumber);
    String? selectedNeighborhood = _currentUser?.neighborhood;
    DateTime? selectedBirthday = _currentUser?.birthday;
    String? selectedGender = _currentUser?.gender;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  enabled: false,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedNeighborhood,
                  decoration: const InputDecoration(labelText: 'Neighborhood', border: OutlineInputBorder()),
                  items: AppConstants.neighborhoods.map((n) => DropdownMenuItem(value: n['fr'], child: Text(n['fr']!))).toList(),
                  onChanged: (val) => setDialogState(() => selectedNeighborhood = val),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                  items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) => setDialogState(() => selectedGender = val),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedBirthday ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setDialogState(() => selectedBirthday = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Birthday', border: OutlineInputBorder()),
                    child: Text(
                      selectedBirthday != null ? DateFormat('dd/MM/yyyy').format(selectedBirthday!) : 'Select birthday',
                      style: TextStyle(color: selectedBirthday != null ? Colors.black : AppConstants.greyColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (usernameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Username cannot be empty'), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                final updatedUser = _currentUser!.copyWith(
                  name: nameController.text.trim(),
                  username: usernameController.text.trim(),
                  neighborhood: selectedNeighborhood,
                  gender: selectedGender,
                  birthday: selectedBirthday,
                  updatedAt: DateTime.now(),
                );
                await AuthService.updateUserProfile(updatedUser);
                setState(() => _currentUser = updatedUser);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showFavoriteEvents() {
    if (_favoriteEventIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No favorite events yet. Tap the heart icon on events to add them!'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final favoriteEvents = _events.where((e) => _favoriteEventIds.contains(e.eventId)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppConstants.whiteColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 28),
                  const SizedBox(width: 12),
                  const Text('Favorite Events', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: favoriteEvents.isEmpty
                  ? const Center(child: Text('No favorite events found', style: TextStyle(color: AppConstants.greyColor)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: favoriteEvents.length,
                      itemBuilder: (ctx, index) => _buildEventCard(favoriteEvents[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _switchRole(UserRole newRole) async {
    if (newRole == _currentUser?.role) return;
    
    final updatedUser = _currentUser!.copyWith(role: newRole);
    await AuthService.updateUserRole(updatedUser);
    
    if (!mounted) return;
    
    if (newRole == UserRole.organizer) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrganizerDashboard()));
    } else {
      _loadData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _SponsoredCarousel extends StatefulWidget {
  final List<EventModel> events;
  final Function(EventModel) onTap;

  const _SponsoredCarousel({required this.events, required this.onTap});

  @override
  State<_SponsoredCarousel> createState() => _SponsoredCarouselState();
}

class _SponsoredCarouselState extends State<_SponsoredCarousel> {
  late PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.75, initialPage: 0);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
    
    Future.delayed(const Duration(seconds: 1), _autoScroll);
  }

  void _autoScroll() {
    if (!mounted) return;
    
    final nextPage = (_currentPage + 1) % widget.events.length;
    _pageController.animateToPage(
      nextPage.toInt(),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
    
    Future.delayed(const Duration(seconds: 3), _autoScroll);
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.events.length,
      itemBuilder: (ctx, index) {
        final scale = 1.0 - ((_currentPage - index).abs() * 0.15).clamp(0.0, 0.3);
        final opacity = 1.0 - ((_currentPage - index).abs() * 0.5).clamp(0.0, 0.7);
        
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: _buildSponsoredCard(widget.events[index]),
          ),
        );
      },
    );
  }

  Widget _buildSponsoredCard(EventModel event) {
    return InkWell(
      onTap: () => widget.onTap(event),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              ImageHelper.buildImage(event.imageUrl, height: 280, width: double.infinity, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(DateFormat('dd MMMM - ').format(event.date) + event.venue, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// Custom ticket tab view with rounded rectangular buttons
class _TicketTabView extends StatefulWidget {
  final List<TicketModel> tickets;
  final AppUser? currentUser;

  const _TicketTabView({required this.tickets, required this.currentUser});

  @override
  State<_TicketTabView> createState() => _TicketTabViewState();
}

class _TicketTabViewState extends State<_TicketTabView> {
  int _selectedTab = 0; // 0 = Active, 1 = Past

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom tab buttons
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildTabButton('Active', 0),
              ),
              Expanded(
                child: _buildTabButton('Past', 1),
              ),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: _selectedTab == 0
              ? _buildTicketList(TicketStatus.valid)
              : _buildPastTicketList(),
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : AppConstants.greyColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildTicketList(TicketStatus status) {
    final filteredTickets = widget.tickets.where((t) => t.status == status).toList();
    
    if (filteredTickets.isEmpty) {
      return const Center(child: Text('No tickets found', style: TextStyle(color: AppConstants.greyColor)));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredTickets.length,
      itemBuilder: (ctx, index) => _buildSimpleTicketCard(filteredTickets[index], false),
    );
  }

  Widget _buildPastTicketList() {
    final pastTickets = widget.tickets.where((t) => t.status == TicketStatus.used || t.status == TicketStatus.expired).toList();
    
    if (pastTickets.isEmpty) {
      return const Center(child: Text('No past tickets', style: TextStyle(color: AppConstants.greyColor)));
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: pastTickets.length,
      itemBuilder: (ctx, index) => _buildSimpleTicketCard(pastTickets[index], true),
    );
  }

  Widget _buildSimpleTicketCard(TicketModel ticket, bool isPast) {
    return FutureBuilder<EventModel?>(
      future: EventService.getEventById(ticket.eventId),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final event = snapshot.data!;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isPast ? Colors.grey.shade300 : AppConstants.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              // Event image
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                child: ImageHelper.buildImage(
                  event.imageUrl,
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),
              // Event details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Purchase date : ${DateFormat('MMM dd, yyyy').format(ticket.purchaseDate)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'Valid until : ${DateFormat('MMM dd, yyyy').format(event.date)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // View button
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ElevatedButton(
                  onPressed: () {
                    // Show full ticket details
                    _showFullTicketDialog(ticket, event);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('View', style: TextStyle(fontSize: 13)),
                      SizedBox(width: 4),
                      Icon(Icons.visibility, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFullTicketDialog(TicketModel ticket, EventModel event) {
    final tierName = ticket.ticketTierName ?? ticket.tierName ?? 'General Admission';
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header section
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 40),
                        const Text(
                          'My ticket',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 26),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ticket downloaded!'), backgroundColor: Colors.green),
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 26),
                              onPressed: () => Navigator.pop(ctx),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // White ticket body
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        // Event image
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: ImageHelper.buildImage(event.imageUrl, width: double.infinity, fit: BoxFit.cover),
                          ),
                        ),
                        
                        // Ticket details
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppConstants.primaryColor,
                                  letterSpacing: 0.3,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 28),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('NAME:', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, letterSpacing: 1.5)),
                                        const SizedBox(height: 6),
                                        Text(
                                          widget.currentUser?.name.toUpperCase() ?? 'TICKET HOLDER',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('LOCATION:', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, letterSpacing: 1.5)),
                                        const SizedBox(height: 6),
                                        Text(
                                          event.venue.toUpperCase(),
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
                                          maxLines: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('DATE:', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, letterSpacing: 1.5)),
                                        const SizedBox(height: 6),
                                        Text(
                                          DateFormat('EEEE, MMM d').format(event.date).toUpperCase(),
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('TIME:', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, letterSpacing: 1.5)),
                                        const SizedBox(height: 6),
                                        Text(
                                          DateFormat('h:mm a').format(event.date).toUpperCase(),
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('SEAT:', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, letterSpacing: 1.5)),
                                        const SizedBox(height: 6),
                                        const Text('NO SEAT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('SECTOR:', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, letterSpacing: 1.5)),
                                        const SizedBox(height: 6),
                                        Text(tierName.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              
                              if (ticket.status == TicketStatus.valid) ...[
                                const SizedBox(height: 28),
                                Center(
                                  child: Text(
                                    'Scan this barcode',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: List.generate(
                                    30,
                                    (index) => Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 1),
                                        height: 2,
                                        color: index.isEven ? Colors.grey.shade300 : Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Center(
                                  child: Container(
                                    width: double.infinity,
                                    height: 100,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: CustomPaint(
                                      painter: BarcodePainter(ticket.qrData),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ] else ...[
                                const SizedBox(height: 28),
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  decoration: BoxDecoration(
                                    color: ticket.status == TicketStatus.used 
                                        ? Colors.green.withValues(alpha: 0.08)
                                        : Colors.grey.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: ticket.status == TicketStatus.used ? Colors.green : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      ticket.status == TicketStatus.used ? 'TICKET USED' : 'TICKET EXPIRED',
                                      style: TextStyle(
                                        color: ticket.status == TicketStatus.used ? Colors.green : Colors.grey.shade600,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

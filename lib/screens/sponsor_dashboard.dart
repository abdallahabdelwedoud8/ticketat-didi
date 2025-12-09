import 'package:flutter/material.dart';
import 'package:eventide/utils/constants.dart';
import 'package:eventide/utils/image_helper.dart';
import 'package:eventide/models/app_models.dart';
import 'package:eventide/services/auth_service.dart';
import 'package:eventide/services/event_service.dart';
import 'package:eventide/services/sponsor_service.dart';
import 'package:eventide/screens/auth_screen.dart';
import 'package:intl/intl.dart';

class SponsorDashboard extends StatefulWidget {
  const SponsorDashboard({super.key});

  @override
  State<SponsorDashboard> createState() => _SponsorDashboardState();
}

class _SponsorDashboardState extends State<SponsorDashboard> {
  int _currentIndex = 0;
  AppUser? _currentUser;
  SponsorModel? _sponsorProfile;
  List<EventModel> _events = [];
  List<SponsorApplication> _myApplications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _currentUser = await AuthService.getCurrentUser();
    
    if (_currentUser != null) {
      _sponsorProfile = await SponsorService.getSponsorByUserId(_currentUser!.userId);
      _events = await EventService.getAllEvents();
      _myApplications = await SponsorService.getApplicationsBySponsor(_sponsorProfile?.sponsorId ?? '');
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sponsor Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppConstants.whiteColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppConstants.primaryColor),
            onPressed: () async {
              await AuthService.logout();
              if (!mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.primaryColor))
          : _sponsorProfile == null
              ? _buildCreateProfileScreen()
              : _buildBody(),
      bottomNavigationBar: _sponsorProfile != null
          ? BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              selectedItemColor: AppConstants.primaryColor,
              unselectedItemColor: AppConstants.greyColor,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
                BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'Applications'),
                BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Profile'),
              ],
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDiscoverTab();
      case 1:
        return _buildApplicationsTab();
      case 2:
        return _buildProfileTab();
      default:
        return _buildDiscoverTab();
    }
  }

  Widget _buildCreateProfileScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_center, size: 80, color: AppConstants.primaryColor.withValues(alpha: 0.5)),
            const SizedBox(height: 24),
            const Text('Create Your Sponsor Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text('Set up your sponsor profile to start discovering and applying for event sponsorship opportunities', style: TextStyle(fontSize: 16, color: AppConstants.greyColor), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _showCreateProfileDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Create Profile', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateProfileDialog() {
    final companyController = TextEditingController();
    String selectedCategory = AppConstants.sponsorCategories[0];
    String selectedBudget = AppConstants.budgetRanges[0];
    List<String> selectedAudiences = [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Sponsor Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppConstants.primaryColor),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📌 Commission Notice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(height: 8),
                      Text('Ticketat charges a 10% commission on all sponsorship budgets.', style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: companyController,
                  decoration: const InputDecoration(labelText: 'Company/Brand Name'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: AppConstants.sponsorCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setDialogState(() => selectedCategory = val!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedBudget,
                  decoration: const InputDecoration(labelText: 'Budget Range'),
                  items: AppConstants.budgetRanges.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (val) => setDialogState(() => selectedBudget = val!),
                ),
                const SizedBox(height: 16),
                const Text('Target Audience:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: AppConstants.eventCategories.skip(1).map((cat) {
                    final isSelected = selectedAudiences.contains(cat);
                    return FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            selectedAudiences.add(cat);
                          } else {
                            selectedAudiences.remove(cat);
                          }
                        });
                      },
                    );
                  }).toList(),
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
                if (companyController.text.isEmpty) return;
                
                await SponsorService.createSponsorProfile(
                  userId: _currentUser!.userId,
                  companyName: companyController.text,
                  category: selectedCategory,
                  budgetRange: selectedBudget,
                  targetAudience: selectedAudiences,
                );
                
                Navigator.pop(ctx);
                _loadData();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
              child: const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverTab() {
    final upcomingEvents = _events.where((e) => e.date.isAfter(DateTime.now())).toList();
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: upcomingEvents.length,
        itemBuilder: (ctx, index) => _buildEventCard(upcomingEvents[index]),
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: ImageHelper.buildImage(event.imageUrl, height: 150, width: double.infinity, fit: BoxFit.cover),
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
                    const Icon(Icons.category, size: 16, color: AppConstants.greyColor),
                    const SizedBox(width: 4),
                    Text(event.category, style: const TextStyle(color: AppConstants.greyColor)),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today, size: 16, color: AppConstants.greyColor),
                    const SizedBox(width: 4),
                    Text(DateFormat('dd MMM yyyy').format(event.date), style: const TextStyle(color: AppConstants.greyColor)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Estimated Attendees: ${event.capacity}', style: const TextStyle(fontSize: 14, color: AppConstants.greyColor)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => _showApplicationDialog(event),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  child: const Text('Apply for Sponsorship', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showApplicationDialog(EventModel event) {
    final budgetController = TextEditingController();
    final messageController = TextEditingController();
    final daysController = TextEditingController(text: '7');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final daysSponsored = int.tryParse(daysController.text) ?? 7;
          final costPerDay = 5000.0; // 5000 MRU per day
          final totalCost = daysSponsored * costPerDay;
          
          return AlertDialog(
            title: Text('Sponsor: ${event.title}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppConstants.primaryColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡 Sponsorship Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Text('Cost: 5,000 MRU per day', style: TextStyle(color: AppConstants.greyColor.withValues(alpha: 0.9))),
                        const SizedBox(height: 4),
                        Text('Your event will appear in the "Sponsored" carousel on the home screen', style: TextStyle(fontSize: 13, color: AppConstants.greyColor.withValues(alpha: 0.8))),
                        const SizedBox(height: 8),
                        const Text('📌 Note: Ticketat charges a 10% commission on all sponsorship budgets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppConstants.primaryColor)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: daysController,
                    decoration: const InputDecoration(
                      labelText: 'Days of Sponsorship',
                      hintText: '7',
                      helperText: 'How many days do you want to sponsor this event?',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Cost:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('${totalCost.toStringAsFixed(0)} MRU', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: budgetController,
                    decoration: const InputDecoration(
                      labelText: 'Budget Offered (MRU)',
                      hintText: 'Additional budget for brand placement',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message to Organizer',
                      hintText: 'Tell the organizer about your brand...',
                    ),
                    maxLines: 3,
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
                  if (daysController.text.isEmpty || messageController.text.isEmpty) {
                    return;
                  }
                  
                  final daysSponsored = int.tryParse(daysController.text) ?? 7;
                  final totalCost = daysSponsored * 5000.0;
                  
                  // Submit sponsorship payment and application
                  await SponsorService.promoteEvent(
                    eventId: event.eventId,
                    daysPromoted: daysSponsored,
                    totalCost: totalCost,
                  );
                  
                  await SponsorService.submitApplication(
                    sponsorId: _sponsorProfile!.sponsorId,
                    eventId: event.eventId,
                    brandName: _sponsorProfile!.companyName,
                    budgetOffered: double.tryParse(budgetController.text) ?? 0,
                    message: messageController.text,
                  );
                  
                  Navigator.pop(ctx);
                  _loadData();
                  
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sponsorship payment of ${totalCost.toStringAsFixed(0)} MRU successful! Your application has been submitted.'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
                child: const Text('Pay & Submit', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildApplicationsTab() {
    if (_myApplications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: AppConstants.greyColor),
            SizedBox(height: 16),
            Text('No applications yet', style: TextStyle(fontSize: 18, color: AppConstants.greyColor)),
            SizedBox(height: 8),
            Text('Browse events and apply for sponsorship opportunities', style: TextStyle(color: AppConstants.greyColor)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myApplications.length,
        itemBuilder: (ctx, index) => _buildApplicationCard(_myApplications[index]),
      ),
    );
  }

  Widget _buildApplicationCard(SponsorApplication application) {
    Color statusColor;
    IconData statusIcon;
    
    switch (application.status) {
      case SponsorApplicationStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case SponsorApplicationStatus.accepted:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case SponsorApplicationStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return FutureBuilder<EventModel?>(
      future: EventService.getEventById(application.eventId),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final event = snapshot.data!;
        
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
                    Expanded(
                      child: Text(event.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Icon(statusIcon, color: statusColor, size: 28),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Budget Offered: ${application.budgetOffered.toStringAsFixed(0)} MRU', style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    application.status.toString().split('.').last.toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                if (application.status == SponsorApplicationStatus.accepted && application.organizerContactInfo != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('✓ Application Accepted!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                        const SizedBox(height: 4),
                        Text('Organizer Contact: ${application.organizerContactInfo}', style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileTab() {
    if (_sponsorProfile == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppConstants.primaryColor,
                        child: Text(_sponsorProfile!.companyName[0].toUpperCase(), style: const TextStyle(fontSize: 24, color: Colors.white)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_sponsorProfile!.companyName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(_sponsorProfile!.category, style: const TextStyle(color: AppConstants.greyColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow('Budget Range', _sponsorProfile!.budgetRange),
                  const SizedBox(height: 12),
                  _buildInfoRow('Target Audience', _sponsorProfile!.targetAudience.join(', ')),
                  const SizedBox(height: 12),
                  _buildInfoRow('Applications Submitted', '${_myApplications.length}'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Accepted', '${_myApplications.where((a) => a.status == SponsorApplicationStatus.accepted).length}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Application Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Pending', _myApplications.where((a) => a.status == SponsorApplicationStatus.pending).length, Colors.orange),
                      _buildStatItem('Accepted', _myApplications.where((a) => a.status == SponsorApplicationStatus.accepted).length, Colors.green),
                      _buildStatItem('Rejected', _myApplications.where((a) => a.status == SponsorApplicationStatus.rejected).length, Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text('$count', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: AppConstants.greyColor)),
      ],
    );
  }
}

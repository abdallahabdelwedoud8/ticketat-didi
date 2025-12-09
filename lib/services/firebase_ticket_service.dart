import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventide/models/app_models.dart';
import 'package:flutter/foundation.dart';
import 'package:eventide/services/firebase_event_service.dart';
import 'package:eventide/services/firebase_user_service.dart';
import 'package:eventide/utils/constants.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class FirebaseTicketService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference get _ticketsCollection => _firestore.collection('tickets');

  // Generate secure barcode data (numeric format for barcode scanning)
  static String _generateBarcodeData(String ticketId, String eventId, String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final rawData = '$ticketId|$eventId|$userId|$timestamp';
    final bytes = utf8.encode(rawData);
    final hash = sha256.convert(bytes).toString();
    // Convert hex hash to numeric-only format for barcode compatibility
    final numericHash = hash.codeUnits.map((c) => c % 10).join();
    return numericHash.substring(0, 16); // 16-digit barcode
  }

  // Purchase Ticket with fee calculation
  static Future<TicketModel?> purchaseTicket({
    required String userId,
    required String eventId,
    String? tierName,
    int quantity = 1,
  }) async {
    try {
      final event = await FirebaseEventService.getEventById(eventId);
      if (event == null) return null;

      final user = await FirebaseUserService.getUserById(userId);
      if (user == null) return null;

      // Calculate pricing
      TicketTier? selectedTier;
      double basePrice = event.price;
      
      if (tierName != null && event.ticketTiers.isNotEmpty) {
        selectedTier = event.ticketTiers.firstWhere(
          (t) => t.name == tierName,
          orElse: () => event.ticketTiers.first,
        );
        basePrice = selectedTier.price;
      }

      // Check capacity for tier or overall event
      if (selectedTier != null) {
        // Check tier-specific capacity
        if (selectedTier.soldTickets + quantity > selectedTier.capacity) {
          debugPrint('Tier $tierName is sold out or insufficient capacity');
          return null;
        }
      } else {
        // Check overall event capacity
        if (event.soldTickets + quantity > event.capacity) {
          debugPrint('Event is sold out or insufficient capacity');
          return null;
        }
      }

      // For free events, skip fee calculation
      double platformFee = 0;
      double subtotal = basePrice * quantity;
      double totalFee = 0;
      double discount = 0.0;
      double finalPrice = 0;

      // Only calculate fees if event is not free
      if (!event.isFreeEvent && basePrice > 0) {
        // Calculate fees based on partner status
        final organizer = await FirebaseUserService.getUserById(event.organizerId);
        final isPartnerOrganizer = organizer?.isPartner ?? false;

        if (basePrice < 500) {
          platformFee = 65;
        } else {
          platformFee = basePrice * (isPartnerOrganizer ? 0.14 : 0.10);
        }

        totalFee = platformFee * quantity;
        subtotal = basePrice * quantity;

        // Apply first purchase discount (after fee)
        if (!user.firstPurchaseUsed) {
          discount = (subtotal + totalFee) * AppConstants.firstPurchaseDiscount;
        }

        finalPrice = subtotal + totalFee - discount;
      }

      // Create ticket
      final now = DateTime.now();
      final ticketId = 'tkt_${now.millisecondsSinceEpoch}';
      final barcodeData = _generateBarcodeData(ticketId, eventId, userId);

      final ticket = TicketModel(
        ticketId: ticketId,
        userId: userId,
        eventId: eventId,
        tierName: tierName,
        quantity: quantity,
        qrData: barcodeData,
        purchaseDate: now,
        pricePaid: finalPrice,
        discountApplied: discount,
        platformFee: totalFee,
        createdAt: now,
        updatedAt: now,
      );

      await _ticketsCollection.doc(ticketId).set(ticket.toJson());

      // Update event sold tickets
      await FirebaseEventService.updateEvent(
        event.copyWith(soldTickets: event.soldTickets + quantity)
      );

      // Update tier sold tickets if applicable
      if (selectedTier != null) {
        final updatedTiers = event.ticketTiers.map((t) {
          if (t.name == tierName) {
            return t.copyWith(soldTickets: t.soldTickets + quantity);
          }
          return t;
        }).toList();
        await FirebaseEventService.updateEvent(
          event.copyWith(ticketTiers: updatedTiers)
        );
      }

      // Mark first purchase as used
      if (!user.firstPurchaseUsed) {
        await FirebaseUserService.updateUser(
          user.copyWith(firstPurchaseUsed: true)
        );
      }

      // Update user preferences based on purchase history
      final userTickets = await getUserTickets(userId);
      if (userTickets.length >= AppConstants.recommendationThreshold) {
        final categories = <String>{};
        for (final t in userTickets) {
          final e = await FirebaseEventService.getEventById(t.eventId);
          if (e != null) categories.add(e.category);
        }
        await FirebaseUserService.updateUserProfile(
          userId: userId,
          preferences: categories.toList(),
        );
      }

      return ticket;
    } catch (e) {
      if (kDebugMode) print('Error purchasing ticket: $e');
      return null;
    }
  }

  // Get tickets for user
  static Future<List<TicketModel>> getUserTickets(String userId) async {
    try {
      final snapshot = await _ticketsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('purchaseDate', descending: true)
          .limit(100)
          .get();

      return snapshot.docs.map((doc) {
        return TicketModel.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'ticketId': doc.id,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching user tickets: $e');
      return [];
    }
  }

  // Get active tickets
  static Future<List<TicketModel>> getActiveTickets(String userId) async {
    try {
      final tickets = await getUserTickets(userId);
      final activeTickets = <TicketModel>[];

      for (final ticket in tickets) {
        final event = await FirebaseEventService.getEventById(ticket.eventId);
        if (event != null &&
            event.date.isAfter(DateTime.now()) &&
            ticket.status == TicketStatus.valid) {
          activeTickets.add(ticket);
        }
      }

      return activeTickets;
    } catch (e) {
      if (kDebugMode) print('Error fetching active tickets: $e');
      return [];
    }
  }

  // Get used tickets
  static Future<List<TicketModel>> getUsedTickets(String userId) async {
    try {
      final snapshot = await _ticketsCollection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'used')
          .orderBy('purchaseDate', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        return TicketModel.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'ticketId': doc.id,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching used tickets: $e');
      return [];
    }
  }

  // Get past tickets
  static Future<List<TicketModel>> getPastTickets(String userId) async {
    try {
      final tickets = await getUserTickets(userId);
      final pastTickets = <TicketModel>[];

      for (final ticket in tickets) {
        final event = await FirebaseEventService.getEventById(ticket.eventId);
        if (event != null &&
            event.date.isBefore(DateTime.now()) &&
            ticket.status != TicketStatus.used) {
          pastTickets.add(ticket);
        }
      }

      return pastTickets;
    } catch (e) {
      if (kDebugMode) print('Error fetching past tickets: $e');
      return [];
    }
  }

  // Validate ticket
  static Future<bool> validateTicket(String barcodeData, String eventId) async {
    try {
      final snapshot = await _ticketsCollection
          .where('qrData', isEqualTo: barcodeData)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return false;

      final ticket = TicketModel.fromJson({
        ...snapshot.docs.first.data() as Map<String, dynamic>,
        'ticketId': snapshot.docs.first.id,
      });

      if (ticket.status == TicketStatus.used) return false;

      final event = await FirebaseEventService.getEventById(eventId);
      if (event == null ||
          event.date.isBefore(DateTime.now().subtract(const Duration(hours: 6)))) {
        return false;
      }

      await _ticketsCollection.doc(ticket.ticketId).update({
        'status': 'used',
        'updatedAt': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      if (kDebugMode) print('Error validating ticket: $e');
      return false;
    }
  }

  // Get ticket by ID
  static Future<TicketModel?> getTicketById(String ticketId) async {
    try {
      final doc = await _ticketsCollection.doc(ticketId).get();
      if (!doc.exists) return null;

      return TicketModel.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'ticketId': doc.id,
      });
    } catch (e) {
      if (kDebugMode) print('Error fetching ticket: $e');
      return null;
    }
  }

  // Get tickets for event
  static Future<List<TicketModel>> getEventTickets(String eventId) async {
    try {
      final snapshot = await _ticketsCollection
          .where('eventId', isEqualTo: eventId)
          .orderBy('purchaseDate', descending: true)
          .limit(500)
          .get();

      return snapshot.docs.map((doc) {
        return TicketModel.fromJson({
          ...doc.data() as Map<String, dynamic>,
          'ticketId': doc.id,
        });
      }).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching event tickets: $e');
      return [];
    }
  }

  // Get event analytics
  static Future<Map<String, dynamic>> getEventAnalytics(String eventId) async {
    try {
      final tickets = await getEventTickets(eventId);
      final event = await FirebaseEventService.getEventById(eventId);

      if (event == null) return {};

      final totalSales = tickets.fold<int>(0, (sum, t) => sum + t.quantity);
      final revenue = tickets.fold<double>(0, (sum, t) => sum + t.pricePaid);
      final usedTickets =
          tickets.where((t) => t.status == TicketStatus.used).length;

      // Demographics
      final ageGroups = <String, int>{};
      final genderCounts = <String, int>{};
      final neighborhoodCounts = <String, int>{};

      for (final ticket in tickets) {
        final user = await FirebaseUserService.getUserById(ticket.userId);
        if (user != null) {
          if (user.birthday != null) {
            final age = DateTime.now().year - user.birthday!.year;
            String ageGroup;
            if (age < 18) {
              ageGroup = 'Under 18';
            } else if (age < 25) {
              ageGroup = '18-24';
            } else if (age < 35) {
              ageGroup = '25-34';
            } else if (age < 45) {
              ageGroup = '35-44';
            } else if (age < 55) {
              ageGroup = '45-54';
            } else {
              ageGroup = '55+';
            }
            ageGroups[ageGroup] = (ageGroups[ageGroup] ?? 0) + 1;
          }

          if (user.gender != null && user.gender!.isNotEmpty) {
            genderCounts[user.gender!] = (genderCounts[user.gender!] ?? 0) + 1;
          }

          if (user.neighborhood != null && user.neighborhood!.isNotEmpty) {
            neighborhoodCounts[user.neighborhood!] =
                (neighborhoodCounts[user.neighborhood!] ?? 0) + 1;
          }
        }
      }

      // Purchase times
      final purchaseTimesByHour = <int, int>{};
      final purchaseTimesByDay = <String, int>{};
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      for (final ticket in tickets) {
        final hour = ticket.purchaseDate.hour;
        purchaseTimesByHour[hour] = (purchaseTimesByHour[hour] ?? 0) + 1;

        final dayIndex = (ticket.purchaseDate.weekday - 1) % 7;
        final dayName = dayNames[dayIndex];
        purchaseTimesByDay[dayName] = (purchaseTimesByDay[dayName] ?? 0) + 1;
      }

      return {
        'totalSales': totalSales,
        'revenue': revenue,
        'attendance': usedTickets,
        'availableTickets': event.capacity - totalSales,
        'ageGroups': ageGroups,
        'genderDistribution': genderCounts,
        'neighborhoods': neighborhoodCounts,
        'purchaseTimesByHour': purchaseTimesByHour,
        'purchaseTimesByDay': purchaseTimesByDay,
      };
    } catch (e) {
      if (kDebugMode) print('Error getting event analytics: $e');
      return {};
    }
  }

  // Get ticket by barcode data
  static Future<TicketModel?> getTicketByBarcode(String barcodeData) async {
    try {
      final snapshot = await _ticketsCollection
          .where('qrData', isEqualTo: barcodeData)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return TicketModel.fromJson({
        ...snapshot.docs.first.data() as Map<String, dynamic>,
        'ticketId': snapshot.docs.first.id,
      });
    } catch (e) {
      if (kDebugMode) print('Error fetching ticket by barcode: $e');
      return null;
    }
  }

  // Mark ticket as used
  static Future<void> markTicketAsUsed(String ticketId) async {
    try {
      await _ticketsCollection.doc(ticketId).update({
        'status': 'used',
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) print('Error marking ticket as used: $e');
      rethrow;
    }
  }
}

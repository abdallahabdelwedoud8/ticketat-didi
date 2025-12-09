import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Ticketat';
  static const String appTagline = 'Digital Gateway to All Events';
  
  static const Color primaryColor = Color(0xFF7DD3C0);
  static const Color secondaryColor = Color(0xFFFFD700);
  static const Color accentColor = Color(0xFF0A3D3D);
  static const Color textColor = Color(0xFF000000);
  static const Color whiteColor = Color(0xFFFFF5E6);
  static const Color creamyBg = Color(0xFFFFF5E6);
  static const Color greyColor = Color(0xFF757575);
  static const Color ticketDarkBg = Color(0xFF0A3D3D);
  static const Color ticketGoldText = Color(0xFFFFD700);
  
  static const double firstPurchaseDiscount = 0.05;
  static const int recommendationThreshold = 2;
  static const int maxTicketsPerPurchase = 6;
  static const int maxTicketsPerUserPerEvent = 6;
  static const double promotionPricePerDay = 500.0;
  static const double boostPricePerDay = 500.0;
  static const String defaultMobileMoneyNumber = '+222 XX XX XX XX';
  
  // Commission & Fee Structure
  static const double sponsorCommission = 0.10; // 10% on sponsorships
  static const double organizerCommission = 0.10; // 10% for non-partner organizers
  static const double buyerFeeUnder500 = 65.0; // 65 MRU for tickets under 500
  static const double buyerFeeOver500Rate = 0.14; // 14% for tickets 500+
  static const double nonPartnerClientFee = 0.10; // 10% for non-partner clients
  static const double analyticsPerEventPrice = 3000.0; // 3000 MRU per event (non-partner)
  static const double analyticsPerEventPartnerPrice = 2000.0; // 2000 MRU per event (partner)
  static const double analyticsMonthlyPrice = 5000.0; // 5000 MRU per month (non-partner)
  static const double analyticsMonthlyPartnerPrice = 3500.0; // 3500 MRU per month (partner)
  static const String platformPaymentAccount = '33020350'; // Bankily/Sedad for boost payment
  static const String platformEmail = 'abdallahabdelwedoud8@gmail.com'; // For partner applications
  
  static const List<String> eventCategories = [
    'All',
    'Music',
    'Sports',
    'Culture',
    'Business',
    'Family',
    'Technology',
    'Education',
    'Food',
    'Art'
  ];
  
  static const List<String> mobileMoneyProviders = [
    'Bankily',
    'Sedad',
    'Masrvi',
    'Click',
    'Moov Money',
    'Mauritel Money',
  ];

  static const Map<String, List<String>> serviceCategories = {
    'Venues': ['Indoor Venues', 'Outdoor Venues', 'Hotels', 'Conference Centers'],
    'Production': ['DJs', 'Musicians', 'Sound Systems', 'Lighting', 'Stage Design'],
    'Catering': ['Food Catering', 'Beverage Services', 'Dessert Services'],
    'Photography & Video': ['Photographers', 'Videographers', 'Drone Services'],
    'Decoration': ['Event Decorators', 'Floral Arrangements', 'Furniture Rental'],
    'Transportation': ['Bus Services', 'Car Rental', 'Valet Services'],
    'Security': ['Event Security', 'Crowd Control'],
    'Other': ['MC/Hosts', 'Entertainment', 'Printing Services'],
  };
  
  static const List<String> sponsorCategories = [
    'Technology',
    'Food & Beverage',
    'Fashion',
    'Automotive',
    'Finance',
    'Healthcare',
    'Education',
    'Entertainment'
  ];
  
  static const List<String> budgetRanges = [
    'Under 100,000 MRU',
    '100,000 - 500,000 MRU',
    '500,000 - 1,000,000 MRU',
    'Over 1,000,000 MRU'
  ];
  
  static const List<Map<String, String>> neighborhoods = [
    {'fr': 'Ain Talh', 'ar': 'عين الطلح'},
    {'fr': 'Arafat', 'ar': 'عرفات'},
    {'fr': 'Basra', 'ar': 'البصرة'},
    {'fr': 'Bouhdida', 'ar': 'بوحديدة'},
    {'fr': 'Capitale', 'ar': 'العاصمة'},
    {'fr': 'Carrefour Madrid', 'ar': 'مفترق مدريد'},
    {'fr': 'Centre Émetteur', 'ar': 'المركز المرسل'},
    {'fr': 'Cinquième', 'ar': 'الخامس'},
    {'fr': 'Cité Plage', 'ar': 'سيتي بلاج'},
    {'fr': 'Dar El Barke', 'ar': 'دار البركة'},
    {'fr': 'Dar Naim', 'ar': 'دار النعيم'},
    {'fr': 'E-Nord', 'ar': 'إي-نورد'},
    {'fr': 'El Mina', 'ar': 'الميناء'},
    {'fr': 'Elvelouje', 'ar': 'الفلوج'},
    {'fr': 'Ettarhil', 'ar': 'الترحيل'},
    {'fr': 'F-Nord', 'ar': 'إف-نورد'},
    {'fr': 'Leksar', 'ar': 'لكصر'},
    {'fr': 'Mellah', 'ar': 'ملاح'},
    {'fr': 'Pique', 'ar': 'بيك'},
    {'fr': 'Riyadh', 'ar': 'الرياض'},
    {'fr': 'Sebkha', 'ar': 'سبخة'},
    {'fr': 'Sixième', 'ar': 'السادس'},
    {'fr': 'Tevragh Zeina', 'ar': 'تفرغ زينة'},
    {'fr': 'Teyaret', 'ar': 'تيارت'},
    {'fr': 'Toujounine', 'ar': 'توجنين'},
  ];
}

class Languages {
  static const Map<String, Map<String, String>> translations = {
    'en': {
      'welcome': 'Welcome to Ticketat',
      'tagline': 'Mauritania\'s digital gateway to all events',
      'buy_store': 'Buy & Store Tickets Securely',
      'qr_instant': 'QR code, instant, paperless',
      'organize_sponsor': 'Organize Smarter, Sponsor Better',
      'data_visibility': 'Data, visibility, and impact',
      'join_movement': 'Join the Movement',
      'digital_revolution': 'Be part of Mauritania\'s digital event revolution',
      'skip': 'Skip',
      'next': 'Next',
      'get_started': 'Get Started',
      'login': 'Login',
      'signup': 'Sign Up',
      'email': 'Email',
      'password': 'Password',
      'name': 'Full Name',
      'select_role': 'Select Your Role',
      'buyer': 'Buyer',
      'organizer': 'Organizer',
      'sponsor': 'Sponsor',
      'security': 'Security',
      'search_events': 'Search events...',
      'my_tickets': 'My Tickets',
      'buy_ticket': 'Buy Ticket',
      'create_event': 'Create Event',
      'scan_qr': 'Scan QR',
      'analytics': 'Analytics',
      'logout': 'Logout',
    },
    'fr': {
      'welcome': 'Bienvenue sur Ticketat',
      'tagline': 'La passerelle numérique de la Mauritanie vers tous les événements',
      'buy_store': 'Acheter et Stocker des Billets en Toute Sécurité',
      'qr_instant': 'Code QR, instantané, sans papier',
      'organize_sponsor': 'Organiser Plus Intelligemment, Parrainer Mieux',
      'data_visibility': 'Données, visibilité et impact',
      'join_movement': 'Rejoignez le Mouvement',
      'digital_revolution': 'Faites partie de la révolution numérique des événements en Mauritanie',
      'skip': 'Passer',
      'next': 'Suivant',
      'get_started': 'Commencer',
      'login': 'Connexion',
      'signup': 'S\'inscrire',
      'email': 'Email',
      'password': 'Mot de passe',
      'name': 'Nom Complet',
      'select_role': 'Sélectionnez Votre Rôle',
      'buyer': 'Acheteur',
      'organizer': 'Organisateur',
      'sponsor': 'Sponsor',
      'security': 'Sécurité',
      'search_events': 'Rechercher des événements...',
      'my_tickets': 'Mes Billets',
      'buy_ticket': 'Acheter un Billet',
      'create_event': 'Créer un Événement',
      'scan_qr': 'Scanner QR',
      'analytics': 'Analytique',
      'logout': 'Déconnexion',
    },
    'ar': {
      'welcome': 'مرحبا بك في تكيتات',
      'tagline': 'البوابة الرقمية لموريتانيا لجميع الفعاليات',
      'buy_store': 'شراء وتخزين التذاكر بأمان',
      'qr_instant': 'رمز QR، فوري، بدون ورق',
      'organize_sponsor': 'تنظيم أذكى، رعاية أفضل',
      'data_visibility': 'البيانات والرؤية والتأثير',
      'join_movement': 'انضم إلى الحركة',
      'digital_revolution': 'كن جزءًا من ثورة الفعاليات الرقمية في موريتانيا',
      'skip': 'تخطي',
      'next': 'التالي',
      'get_started': 'ابدأ',
      'login': 'تسجيل الدخول',
      'signup': 'إنشاء حساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'name': 'الاسم الكامل',
      'select_role': 'اختر دورك',
      'buyer': 'مشتري',
      'organizer': 'منظم',
      'sponsor': 'راعي',
      'security': 'أمن',
      'search_events': 'البحث عن الفعاليات...',
      'my_tickets': 'تذاكري',
      'buy_ticket': 'شراء تذكرة',
      'create_event': 'إنشاء فعالية',
      'scan_qr': 'مسح QR',
      'analytics': 'التحليلات',
      'logout': 'تسجيل الخروج',
    }
  };
  
  static String translate(String key, String languageCode) {
    return translations[languageCode]?[key] ?? translations['en']?[key] ?? key;
  }
}

class FeeCalculator {
  /// Calculate buyer fee based on ticket price
  static double calculateBuyerFee(double ticketPrice, bool isPartnerOrganizer) {
    if (isPartnerOrganizer) {
      // Partner organizer: only charge client
      if (ticketPrice < 500) {
        return AppConstants.buyerFeeUnder500;
      } else {
        return ticketPrice * AppConstants.buyerFeeOver500Rate;
      }
    } else {
      // Non-partner: charge both organizer and client
      return ticketPrice * AppConstants.nonPartnerClientFee;
    }
  }
  
  /// Calculate total with fees BEFORE discount
  static double calculateTotalBeforeDiscount(double ticketPrice, int quantity, bool isPartnerOrganizer) {
    final subtotal = ticketPrice * quantity;
    final feePerTicket = calculateBuyerFee(ticketPrice, isPartnerOrganizer);
    final totalFees = feePerTicket * quantity;
    return subtotal + totalFees;
  }
  
  /// Calculate final total with discount applied AFTER fees
  static double calculateFinalTotal(double ticketPrice, int quantity, bool isPartnerOrganizer, double discountRate) {
    final totalWithFees = calculateTotalBeforeDiscount(ticketPrice, quantity, isPartnerOrganizer);
    final discount = totalWithFees * discountRate;
    return totalWithFees - discount;
  }
  
  /// Get organizer fee display text
  static String getOrganizerFeeText(bool isPartner) {
    if (isPartner) {
      return 'As a Partner Organizer:\n• You pay 0% commission\n• Clients pay: 65 MRU (tickets under 500 MRU) or 14% (tickets 500+ MRU)';
    } else {
      return 'As a Non-Partner Organizer:\n• You pay 10% commission on ticket sales\n• Clients pay 10% platform fee';
    }
  }
  
  /// Get sponsor commission notice
  static String getSponsorCommissionNotice() => 'Note: Ticketat takes 10% commission from the total sponsorship budget.';
  
  /// Get analytics pricing text
  static String getAnalyticsPricing(bool isPartner) {
    if (isPartner) {
      return '📊 Premium Analytics:\n• Per Event: 2,000 MRU\n• Monthly Subscription: 3,500 MRU/month';
    } else {
      return '📊 Premium Analytics:\n• Per Event: 3,000 MRU\n• Monthly Subscription: 5,000 MRU/month';
    }
  }
  
  /// Get boost pricing text
  static String getBoostPricing() => '🚀 Boost Your Event:\n• 500 MRU per day\n• Payment to Bankily: ${AppConstants.platformPaymentAccount}';
}

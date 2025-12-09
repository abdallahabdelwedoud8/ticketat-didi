class AppUser {
  final String userId;
  final String name;
  final String phoneNumber; // Can be empty string for OAuth users
  final String username;
  final String? email;
  final String passwordHash; // For local auth only - Supabase manages passwords separately
  final UserRole role;
  final List<String> preferences;
  final DateTime joinedDate;
  final String language;
  final bool firstPurchaseUsed;
  final DateTime? birthday;
  final String? gender;
  final String? neighborhood;
  final bool hasPremiumAnalytics;
  final DateTime? premiumExpiryDate;
  final bool isPartner;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.userId,
    required this.name,
    this.phoneNumber = '', // Optional - can be empty
    required this.username,
    this.email,
    this.passwordHash = '', // Empty for OAuth users
    required this.role,
    this.preferences = const [],
    required this.joinedDate,
    this.language = 'fr',
    this.firstPurchaseUsed = false,
    this.birthday,
    this.gender,
    this.neighborhood,
    this.hasPremiumAnalytics = false,
    this.premiumExpiryDate,
    this.isPartner = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'name': name,
    'phoneNumber': phoneNumber,
    'username': username,
    'email': email,
    'passwordHash': passwordHash,
    'role': role.toString().split('.').last,
    'preferences': preferences,
    'joinedDate': joinedDate.toIso8601String(),
    'language': language,
    'firstPurchaseUsed': firstPurchaseUsed,
    'birthday': birthday?.toIso8601String(),
    'gender': gender,
    'neighborhood': neighborhood,
    'hasPremiumAnalytics': hasPremiumAnalytics,
    'premiumExpiryDate': premiumExpiryDate?.toIso8601String(),
    'isPartner': isPartner,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    userId: json['userId'] as String,
    name: json['name'] as String,
    phoneNumber: json['phoneNumber'] as String? ?? '',
    username: json['username'] as String? ?? 'user_${json['userId']}',
    email: json['email'] as String?,
    passwordHash: json['passwordHash'] as String? ?? '',
    role: UserRole.values.firstWhere((e) => e.toString().split('.').last == json['role']),
    preferences: List<String>.from(json['preferences'] ?? []),
    joinedDate: DateTime.parse(json['joinedDate'] as String),
    language: json['language'] as String? ?? 'fr',
    firstPurchaseUsed: json['firstPurchaseUsed'] as bool? ?? false,
    birthday: json['birthday'] != null ? DateTime.parse(json['birthday'] as String) : null,
    gender: json['gender'] as String?,
    neighborhood: json['neighborhood'] as String?,
    hasPremiumAnalytics: json['hasPremiumAnalytics'] as bool? ?? false,
    premiumExpiryDate: json['premiumExpiryDate'] != null ? DateTime.parse(json['premiumExpiryDate'] as String) : null,
    isPartner: json['isPartner'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  AppUser copyWith({
    String? userId,
    String? name,
    String? phoneNumber,
    String? username,
    String? email,
    String? passwordHash,
    UserRole? role,
    List<String>? preferences,
    DateTime? joinedDate,
    String? language,
    bool? firstPurchaseUsed,
    DateTime? birthday,
    String? gender,
    String? neighborhood,
    bool? hasPremiumAnalytics,
    DateTime? premiumExpiryDate,
    bool? isPartner,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AppUser(
    userId: userId ?? this.userId,
    name: name ?? this.name,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    username: username ?? this.username,
    email: email ?? this.email,
    passwordHash: passwordHash ?? this.passwordHash,
    role: role ?? this.role,
    preferences: preferences ?? this.preferences,
    joinedDate: joinedDate ?? this.joinedDate,
    language: language ?? this.language,
    firstPurchaseUsed: firstPurchaseUsed ?? this.firstPurchaseUsed,
    birthday: birthday ?? this.birthday,
    gender: gender ?? this.gender,
    neighborhood: neighborhood ?? this.neighborhood,
    hasPremiumAnalytics: hasPremiumAnalytics ?? this.hasPremiumAnalytics,
    premiumExpiryDate: premiumExpiryDate ?? this.premiumExpiryDate,
    isPartner: isPartner ?? this.isPartner,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

enum UserRole { buyer, organizer, sponsor, security }

class TicketTier {
  final String name;
  final double price;
  final int capacity;
  final int soldTickets;

  TicketTier({
    required this.name,
    required this.price,
    required this.capacity,
    this.soldTickets = 0,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
    'capacity': capacity,
    'soldTickets': soldTickets,
  };

  factory TicketTier.fromJson(Map<String, dynamic> json) => TicketTier(
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    capacity: json['capacity'] as int,
    soldTickets: json['soldTickets'] as int? ?? 0,
  );

  TicketTier copyWith({
    String? name,
    double? price,
    int? capacity,
    int? soldTickets,
  }) => TicketTier(
    name: name ?? this.name,
    price: price ?? this.price,
    capacity: capacity ?? this.capacity,
    soldTickets: soldTickets ?? this.soldTickets,
  );
}

class EventModel {
  final String eventId;
  final String title;
  final String category;
  final DateTime date;
  final String venue;
  final double price;
  final int capacity;
  final int soldTickets;
  final List<TicketTier> ticketTiers;
  final String organizerId;
  final String description;
  final String imageUrl;
  final EventStatus status;
  final bool isSponsored;
  final int sponsoredDays;
  final List<PaymentOption> paymentOptions;
  final String? googleMapsLink;
  final String? websiteLink;
  final String? socialMediaLink;
  final List<String> mediaUrls;
  final bool isPrivate;
  final bool isFreeEvent;
  final String? privateEventCode;
  final int qrScans;
  final int linkClicks;
  final int? maxTicketsPerAccount;
  final bool organizerIsPartner;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventModel({
    required this.eventId,
    required this.title,
    required this.category,
    required this.date,
    required this.venue,
    required this.price,
    required this.capacity,
    this.soldTickets = 0,
    this.ticketTiers = const [],
    required this.organizerId,
    required this.description,
    required this.imageUrl,
    this.status = EventStatus.active,
    this.isSponsored = false,
    this.sponsoredDays = 0,
    this.paymentOptions = const [],
    this.googleMapsLink,
    this.websiteLink,
    this.socialMediaLink,
    this.mediaUrls = const [],
    this.isPrivate = false,
    this.isFreeEvent = false,
    this.privateEventCode,
    this.qrScans = 0,
    this.linkClicks = 0,
    this.maxTicketsPerAccount,
    this.organizerIsPartner = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'title': title,
    'category': category,
    'date': date.toIso8601String(),
    'venue': venue,
    'price': price,
    'capacity': capacity,
    'soldTickets': soldTickets,
    'ticketTiers': ticketTiers.map((t) => t.toJson()).toList(),
    'organizerId': organizerId,
    'description': description,
    'imageUrl': imageUrl,
    'status': status.toString().split('.').last,
    'isSponsored': isSponsored,
    'sponsoredDays': sponsoredDays,
    'paymentOptions': paymentOptions.map((p) => p.toJson()).toList(),
    'googleMapsLink': googleMapsLink,
    'websiteLink': websiteLink,
    'socialMediaLink': socialMediaLink,
    'mediaUrls': mediaUrls,
    'isPrivate': isPrivate,
    'isFreeEvent': isFreeEvent,
    'privateEventCode': privateEventCode,
    'qrScans': qrScans,
    'linkClicks': linkClicks,
    'maxTicketsPerAccount': maxTicketsPerAccount,
    'organizerIsPartner': organizerIsPartner,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory EventModel.fromJson(Map<String, dynamic> json) => EventModel(
    eventId: json['eventId'] as String,
    title: json['title'] as String,
    category: json['category'] as String,
    date: DateTime.parse(json['date'] as String),
    venue: json['venue'] as String,
    price: (json['price'] as num).toDouble(),
    capacity: json['capacity'] as int,
    soldTickets: json['soldTickets'] as int? ?? 0,
    ticketTiers: (json['ticketTiers'] as List?)?.map((t) => TicketTier.fromJson(t)).toList() ?? [],
    organizerId: json['organizerId'] as String,
    description: json['description'] as String,
    imageUrl: json['imageUrl'] as String,
    status: EventStatus.values.firstWhere((e) => e.toString().split('.').last == json['status'], orElse: () => EventStatus.active),
    isSponsored: json['isSponsored'] as bool? ?? false,
    sponsoredDays: json['sponsoredDays'] as int? ?? 0,
    paymentOptions: (json['paymentOptions'] as List?)?.map((p) => PaymentOption.fromJson(p)).toList() ?? [],
    googleMapsLink: json['googleMapsLink'] as String?,
    websiteLink: json['websiteLink'] as String?,
    socialMediaLink: json['socialMediaLink'] as String?,
    mediaUrls: List<String>.from(json['mediaUrls'] ?? []),
    isPrivate: json['isPrivate'] as bool? ?? false,
    isFreeEvent: json['isFreeEvent'] as bool? ?? false,
    privateEventCode: json['privateEventCode'] as String?,
    qrScans: json['qrScans'] as int? ?? 0,
    linkClicks: json['linkClicks'] as int? ?? 0,
    maxTicketsPerAccount: json['maxTicketsPerAccount'] as int?,
    organizerIsPartner: json['organizerIsPartner'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  EventModel copyWith({
    String? eventId,
    String? title,
    String? category,
    DateTime? date,
    String? venue,
    double? price,
    int? capacity,
    int? soldTickets,
    List<TicketTier>? ticketTiers,
    String? organizerId,
    String? description,
    String? imageUrl,
    EventStatus? status,
    bool? isSponsored,
    int? sponsoredDays,
    List<PaymentOption>? paymentOptions,
    String? googleMapsLink,
    String? websiteLink,
    String? socialMediaLink,
    List<String>? mediaUrls,
    bool? isPrivate,
    bool? isFreeEvent,
    String? privateEventCode,
    int? qrScans,
    int? linkClicks,
    int? maxTicketsPerAccount,
    bool? organizerIsPartner,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => EventModel(
    eventId: eventId ?? this.eventId,
    title: title ?? this.title,
    category: category ?? this.category,
    date: date ?? this.date,
    venue: venue ?? this.venue,
    price: price ?? this.price,
    capacity: capacity ?? this.capacity,
    soldTickets: soldTickets ?? this.soldTickets,
    ticketTiers: ticketTiers ?? this.ticketTiers,
    organizerId: organizerId ?? this.organizerId,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    status: status ?? this.status,
    isSponsored: isSponsored ?? this.isSponsored,
    sponsoredDays: sponsoredDays ?? this.sponsoredDays,
    paymentOptions: paymentOptions ?? this.paymentOptions,
    googleMapsLink: googleMapsLink ?? this.googleMapsLink,
    websiteLink: websiteLink ?? this.websiteLink,
    socialMediaLink: socialMediaLink ?? this.socialMediaLink,
    mediaUrls: mediaUrls ?? this.mediaUrls,
    isPrivate: isPrivate ?? this.isPrivate,
    isFreeEvent: isFreeEvent ?? this.isFreeEvent,
    privateEventCode: privateEventCode ?? this.privateEventCode,
    qrScans: qrScans ?? this.qrScans,
    linkClicks: linkClicks ?? this.linkClicks,
    maxTicketsPerAccount: maxTicketsPerAccount ?? this.maxTicketsPerAccount,
    organizerIsPartner: organizerIsPartner ?? this.organizerIsPartner,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

enum EventStatus { active, past, cancelled }

class PaymentOption {
  final String provider;
  final String accountNumber;

  PaymentOption({required this.provider, required this.accountNumber});

  Map<String, dynamic> toJson() => {
    'provider': provider,
    'accountNumber': accountNumber,
  };

  factory PaymentOption.fromJson(Map<String, dynamic> json) => PaymentOption(
    provider: json['provider'] as String,
    accountNumber: json['accountNumber'] as String,
  );
}

class TicketModel {
  final String ticketId;
  final String userId;
  final String eventId;
  final String qrData;
  final TicketStatus status;
  final DateTime purchaseDate;
  final double pricePaid;
  final double discountApplied;
  final String? ticketTierName;
  final String? tierName;
  final int quantity;
  final double platformFee;
  final DateTime createdAt;
  final DateTime updatedAt;

  TicketModel({
    required this.ticketId,
    required this.userId,
    required this.eventId,
    required this.qrData,
    this.status = TicketStatus.valid,
    required this.purchaseDate,
    required this.pricePaid,
    this.discountApplied = 0.0,
    this.ticketTierName,
    this.tierName,
    this.quantity = 1,
    this.platformFee = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'ticketId': ticketId,
    'userId': userId,
    'eventId': eventId,
    'qrData': qrData,
    'status': status.toString().split('.').last,
    'purchaseDate': purchaseDate.toIso8601String(),
    'pricePaid': pricePaid,
    'discountApplied': discountApplied,
    'ticketTierName': ticketTierName,
    'tierName': tierName,
    'quantity': quantity,
    'platformFee': platformFee,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory TicketModel.fromJson(Map<String, dynamic> json) => TicketModel(
    ticketId: json['ticketId'] as String,
    userId: json['userId'] as String,
    eventId: json['eventId'] as String,
    qrData: json['qrData'] as String,
    status: TicketStatus.values.firstWhere((e) => e.toString().split('.').last == json['status']),
    purchaseDate: DateTime.parse(json['purchaseDate'] as String),
    pricePaid: (json['pricePaid'] as num).toDouble(),
    discountApplied: (json['discountApplied'] as num?)?.toDouble() ?? 0.0,
    ticketTierName: json['ticketTierName'] as String?,
    tierName: json['tierName'] as String?,
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  TicketModel copyWith({
    String? ticketId,
    String? userId,
    String? eventId,
    String? qrData,
    TicketStatus? status,
    DateTime? purchaseDate,
    double? pricePaid,
    double? discountApplied,
    String? ticketTierName,
    String? tierName,
    int? quantity,
    double? platformFee,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => TicketModel(
    ticketId: ticketId ?? this.ticketId,
    userId: userId ?? this.userId,
    eventId: eventId ?? this.eventId,
    qrData: qrData ?? this.qrData,
    status: status ?? this.status,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    pricePaid: pricePaid ?? this.pricePaid,
    discountApplied: discountApplied ?? this.discountApplied,
    ticketTierName: ticketTierName ?? this.ticketTierName,
    tierName: tierName ?? this.tierName,
    quantity: quantity ?? this.quantity,
    platformFee: platformFee ?? this.platformFee,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

enum TicketStatus { valid, used, expired }

enum PaymentMethod { mobileMoney, card }
enum PaymentStatus { pending, verified, rejected }

class PaymentProof {
  final String paymentId;
  final String ticketId;
  final PaymentMethod method;
  final String? screenshotUrl;
  final String? senderNumber;
  final String? transactionReference;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentProof({
    required this.paymentId,
    required this.ticketId,
    required this.method,
    this.screenshotUrl,
    this.senderNumber,
    this.transactionReference,
    this.status = PaymentStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'paymentId': paymentId,
    'ticketId': ticketId,
    'method': method.toString().split('.').last,
    'screenshotUrl': screenshotUrl,
    'senderNumber': senderNumber,
    'transactionReference': transactionReference,
    'status': status.toString().split('.').last,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PaymentProof.fromJson(Map<String, dynamic> json) => PaymentProof(
    paymentId: json['paymentId'] as String,
    ticketId: json['ticketId'] as String,
    method: PaymentMethod.values.firstWhere((e) => e.toString().split('.').last == json['method']),
    screenshotUrl: json['screenshotUrl'] as String?,
    senderNumber: json['senderNumber'] as String?,
    transactionReference: json['transactionReference'] as String?,
    status: PaymentStatus.values.firstWhere((e) => e.toString().split('.').last == json['status']),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  PaymentProof copyWith({
    String? paymentId,
    String? ticketId,
    PaymentMethod? method,
    String? screenshotUrl,
    String? senderNumber,
    String? transactionReference,
    PaymentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PaymentProof(
    paymentId: paymentId ?? this.paymentId,
    ticketId: ticketId ?? this.ticketId,
    method: method ?? this.method,
    screenshotUrl: screenshotUrl ?? this.screenshotUrl,
    senderNumber: senderNumber ?? this.senderNumber,
    transactionReference: transactionReference ?? this.transactionReference,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

enum SponsorApplicationStatus { pending, accepted, rejected }

class SponsorApplication {
  final String applicationId;
  final String sponsorId;
  final String eventId;
  final String brandName;
  final double budgetOffered;
  final String message;
  final SponsorApplicationStatus status;
  final String? organizerContactInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  SponsorApplication({
    required this.applicationId,
    required this.sponsorId,
    required this.eventId,
    required this.brandName,
    required this.budgetOffered,
    required this.message,
    this.status = SponsorApplicationStatus.pending,
    this.organizerContactInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'applicationId': applicationId,
    'sponsorId': sponsorId,
    'eventId': eventId,
    'brandName': brandName,
    'budgetOffered': budgetOffered,
    'message': message,
    'status': status.toString().split('.').last,
    'organizerContactInfo': organizerContactInfo,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SponsorApplication.fromJson(Map<String, dynamic> json) => SponsorApplication(
    applicationId: json['applicationId'] as String,
    sponsorId: json['sponsorId'] as String,
    eventId: json['eventId'] as String,
    brandName: json['brandName'] as String,
    budgetOffered: (json['budgetOffered'] as num).toDouble(),
    message: json['message'] as String,
    status: SponsorApplicationStatus.values.firstWhere((e) => e.toString().split('.').last == json['status']),
    organizerContactInfo: json['organizerContactInfo'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  SponsorApplication copyWith({
    String? applicationId,
    String? sponsorId,
    String? eventId,
    String? brandName,
    double? budgetOffered,
    String? message,
    SponsorApplicationStatus? status,
    String? organizerContactInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SponsorApplication(
    applicationId: applicationId ?? this.applicationId,
    sponsorId: sponsorId ?? this.sponsorId,
    eventId: eventId ?? this.eventId,
    brandName: brandName ?? this.brandName,
    budgetOffered: budgetOffered ?? this.budgetOffered,
    message: message ?? this.message,
    status: status ?? this.status,
    organizerContactInfo: organizerContactInfo ?? this.organizerContactInfo,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class EventPromotion {
  final String promotionId;
  final String eventId;
  final int daysPromoted;
  final double totalCost;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  EventPromotion({
    required this.promotionId,
    required this.eventId,
    required this.daysPromoted,
    required this.totalCost,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'promotionId': promotionId,
    'eventId': eventId,
    'daysPromoted': daysPromoted,
    'totalCost': totalCost,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory EventPromotion.fromJson(Map<String, dynamic> json) => EventPromotion(
    promotionId: json['promotionId'] as String,
    eventId: json['eventId'] as String,
    daysPromoted: json['daysPromoted'] as int,
    totalCost: (json['totalCost'] as num).toDouble(),
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: DateTime.parse(json['endDate'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class SecurityStaff {
  final String staffId;
  final String eventId;
  final String userId; // References the user account
  final String username; // Display username
  final String tempPassword; // Temporary password shown to organizer
  final DateTime createdAt;

  SecurityStaff({
    required this.staffId,
    required this.eventId,
    required this.userId,
    required this.username,
    required this.tempPassword,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'staff_id': staffId,
    'event_id': eventId,
    'user_id': userId,
    'username': username,
    'temp_password': tempPassword,
    'created_at': createdAt.toIso8601String(),
  };

  factory SecurityStaff.fromJson(Map<String, dynamic> json) => SecurityStaff(
    staffId: json['staff_id'] as String? ?? json['staffId'] as String,
    eventId: json['event_id'] as String? ?? json['eventId'] as String,
    userId: json['user_id'] as String? ?? json['userId'] as String,
    username: json['username'] as String,
    tempPassword: json['temp_password'] as String? ?? json['tempPassword'] as String? ?? '',
    createdAt: DateTime.parse((json['created_at'] ?? json['createdAt']) as String),
  );
}

class SponsorModel {
  final String sponsorId;
  final String userId;
  final String companyName;
  final String category;
  final String budgetRange;
  final List<String> targetAudience;
  final List<String> sponsoredEvents;
  final int impressions;
  final DateTime createdAt;
  final DateTime updatedAt;

  SponsorModel({
    required this.sponsorId,
    required this.userId,
    required this.companyName,
    required this.category,
    required this.budgetRange,
    this.targetAudience = const [],
    this.sponsoredEvents = const [],
    this.impressions = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'sponsorId': sponsorId,
    'userId': userId,
    'companyName': companyName,
    'category': category,
    'budgetRange': budgetRange,
    'targetAudience': targetAudience,
    'sponsoredEvents': sponsoredEvents,
    'impressions': impressions,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SponsorModel.fromJson(Map<String, dynamic> json) => SponsorModel(
    sponsorId: json['sponsorId'] as String,
    userId: json['userId'] as String,
    companyName: json['companyName'] as String,
    category: json['category'] as String,
    budgetRange: json['budgetRange'] as String,
    targetAudience: List<String>.from(json['targetAudience'] ?? []),
    sponsoredEvents: List<String>.from(json['sponsoredEvents'] ?? []),
    impressions: json['impressions'] as int? ?? 0,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  SponsorModel copyWith({
    String? sponsorId,
    String? userId,
    String? companyName,
    String? category,
    String? budgetRange,
    List<String>? targetAudience,
    List<String>? sponsoredEvents,
    int? impressions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SponsorModel(
    sponsorId: sponsorId ?? this.sponsorId,
    userId: userId ?? this.userId,
    companyName: companyName ?? this.companyName,
    category: category ?? this.category,
    budgetRange: budgetRange ?? this.budgetRange,
    targetAudience: targetAudience ?? this.targetAudience,
    sponsoredEvents: sponsoredEvents ?? this.sponsoredEvents,
    impressions: impressions ?? this.impressions,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class ProviderModel {
  final String providerId;
  final String userId;
  final String companyName;
  final String serviceType;
  final double rating;
  final String contactInfo;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProviderModel({
    required this.providerId,
    required this.userId,
    required this.companyName,
    required this.serviceType,
    this.rating = 5.0,
    required this.contactInfo,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'providerId': providerId,
    'userId': userId,
    'companyName': companyName,
    'serviceType': serviceType,
    'rating': rating,
    'contactInfo': contactInfo,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ProviderModel.fromJson(Map<String, dynamic> json) => ProviderModel(
    providerId: json['providerId'] as String,
    userId: json['userId'] as String,
    companyName: json['companyName'] as String,
    serviceType: json['serviceType'] as String,
    rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
    contactInfo: json['contactInfo'] as String,
    description: json['description'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  ProviderModel copyWith({
    String? providerId,
    String? userId,
    String? companyName,
    String? serviceType,
    double? rating,
    String? contactInfo,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProviderModel(
    providerId: providerId ?? this.providerId,
    userId: userId ?? this.userId,
    companyName: companyName ?? this.companyName,
    serviceType: serviceType ?? this.serviceType,
    rating: rating ?? this.rating,
    contactInfo: contactInfo ?? this.contactInfo,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class AnalyticsModel {
  final String eventId;
  final int totalSales;
  final double revenue;
  final int attendance;
  final Map<String, int> demographics;
  final double avgRating;
  final List<String> sponsorMatches;
  final DateTime createdAt;
  final DateTime updatedAt;

  AnalyticsModel({
    required this.eventId,
    this.totalSales = 0,
    this.revenue = 0.0,
    this.attendance = 0,
    this.demographics = const {},
    this.avgRating = 0.0,
    this.sponsorMatches = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'eventId': eventId,
    'totalSales': totalSales,
    'revenue': revenue,
    'attendance': attendance,
    'demographics': demographics,
    'avgRating': avgRating,
    'sponsorMatches': sponsorMatches,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) => AnalyticsModel(
    eventId: json['eventId'] as String,
    totalSales: json['totalSales'] as int? ?? 0,
    revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    attendance: json['attendance'] as int? ?? 0,
    demographics: Map<String, int>.from(json['demographics'] ?? {}),
    avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
    sponsorMatches: List<String>.from(json['sponsorMatches'] ?? []),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  AnalyticsModel copyWith({
    String? eventId,
    int? totalSales,
    double? revenue,
    int? attendance,
    Map<String, int>? demographics,
    double? avgRating,
    List<String>? sponsorMatches,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AnalyticsModel(
    eventId: eventId ?? this.eventId,
    totalSales: totalSales ?? this.totalSales,
    revenue: revenue ?? this.revenue,
    attendance: attendance ?? this.attendance,
    demographics: demographics ?? this.demographics,
    avgRating: avgRating ?? this.avgRating,
    sponsorMatches: sponsorMatches ?? this.sponsorMatches,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

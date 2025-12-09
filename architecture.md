# Ticketat - Architecture & Implementation Plan

## Overview
Ticketat is a comprehensive QR-based digital ticketing platform for events in Mauritania, connecting buyers, organizers, service providers, sponsors, and admins in one ecosystem.

## Technical Stack
- **Framework**: Flutter (Mobile & Web)
- **Storage**: Local Storage (SharedPreferences + Hive for structured data)
- **QR Code**: qr_flutter, mobile_scanner
- **State Management**: Provider
- **Localization**: Intl (French + Arabic)

## Architecture Pattern
**MVVM with Service Layer**
- Models: Data structures
- Services: Business logic & data operations
- Screens: UI pages with ViewModels
- Widgets: Reusable UI components
- Utils: Helpers, constants, and utilities

## User Roles
1. **Buyer** - Purchase tickets, access QR codes, get recommendations
2. **Organizer** - Create events, validate tickets, view analytics
3. **Service Provider** - Offer event logistics services
4. **Sponsor** - Connect with events, sponsor opportunities
5. **Admin** - Manage all data, analytics, and users

## File Structure (10 files total)
```
lib/
├── main.dart
├── theme.dart
├── models/
│   └── app_models.dart (User, Event, Ticket, Sponsor, Provider, Analytics)
├── services/
│   ├── auth_service.dart
│   ├── event_service.dart
│   ├── ticket_service.dart
│   └── storage_service.dart
├── screens/
│   ├── onboarding_screen.dart
│   ├── auth_screen.dart
│   ├── buyer_dashboard.dart
│   ├── organizer_dashboard.dart
│   └── admin_dashboard.dart
└── utils/
    └── constants.dart
```

## Data Models

### User Model
- user_id, name, email, password_hash, role (Buyer/Organizer/Provider/Sponsor/Admin)
- preferences (attended_categories[]), joined_date, language (fr/ar)
- first_purchase_used (for 5% discount), created_at, updated_at

### Event Model
- event_id, title, category, date, venue, price, capacity, sold_tickets
- organizer_id, description, image_url, status (active/past)
- created_at, updated_at

### Ticket Model
- ticket_id, user_id, event_id, qr_data (encrypted string)
- status (valid/used/expired), purchase_date, price_paid
- discount_applied, created_at, updated_at

### Sponsor Model
- sponsor_id, user_id, company_name, category, budget_range
- target_audience[], sponsored_events[], impressions
- created_at, updated_at

### Provider Model
- provider_id, user_id, company_name, service_type (DJ/Catering/Lighting/Security)
- rating, contact_info, description
- created_at, updated_at

### Analytics Model
- event_id, total_sales, revenue, attendance, demographics
- avg_rating, sponsor_matches[], created_at, updated_at

## Implementation Steps

### Phase 1: Setup & Core Infrastructure
1. Update theme with turquoise/teal colors (#3CD2B4, #40E0D0)
2. Add dependencies (qr_flutter, mobile_scanner, shared_preferences, hive, provider, intl)
3. Create all data models with toJson/fromJson/copyWith
4. Create storage service with Hive for local persistence
5. Create auth service with role-based authentication
6. Setup constants (categories, service types, colors)

### Phase 2: Onboarding & Authentication
7. Create 4-page onboarding flow with skip/next/get started
8. Create signup/login screen with role selection
9. Implement role-based routing to appropriate dashboards

### Phase 3: Buyer Experience
10. Create buyer dashboard with event cards, search, and filters
11. Implement event service with sample data (20+ events)
12. Create ticket purchase flow with simulated payment
13. Generate QR codes with encrypted ticket data
14. Build "My Tickets" page (active/used/past)
15. Implement recommendation engine based on attendance
16. Add 5% first purchase discount logic
17. Create notifications for upcoming events

### Phase 4: Organizer Features
18. Create organizer dashboard with event management
19. Build event creation/edit forms
20. Implement QR scanner for ticket validation
21. Create analytics dashboard (sales, revenue, demographics)
22. Add sponsorship match recommendations

### Phase 5: Service Provider & Sponsor
23. Create service provider directory with search/filter
24. Build sponsor dashboard with event matching
25. Implement AI-driven event suggestions for sponsors
26. Add sponsorship request functionality

### Phase 6: Admin Panel
27. Create admin dashboard with full CRUD
28. Add user/event/sponsor/provider management
29. Implement analytics and reporting
30. Add export functionality (CSV)

### Phase 7: Polish & Features
31. Implement French/Arabic language toggle
32. Add push notifications simulation
33. Create reusable UI components
34. Add form validation and error handling
35. Optimize performance and responsiveness

### Phase 8: Testing & Deployment
36. Run compile_project to fix Dart errors
37. Test all user flows and role-based features
38. Verify QR generation and validation
39. Test recommendation engine accuracy
40. Final UI polish and accessibility

## Smart Features

### Recommendation Engine
- Track user's attended categories
- Suggest events after 2+ events attended
- Weight by popularity and category match

### Sponsor-Event Matching
- Match sponsor target_audience with event demographics
- Calculate compatibility score
- Rank events by best fit

### QR Security
- Encrypt: "{ticket_id}|{event_id}|{user_id}|{timestamp}"
- Validate: check status, event date, and user ownership
- Mark as "used" after scan to prevent reuse

### Analytics Dashboard
- Real-time sales and revenue tracking
- Demographic breakdown (age, interests)
- Attendance trends and peak times
- Sponsor ROI metrics

## UI Design Principles
- **Colors**: Turquoise #3CD2B4, Teal #40E0D0, Black text
- **Typography**: Poppins/Inter, medium weight, generous spacing
- **Buttons**: Rounded corners, white text on turquoise
- **Cards**: Clean, minimal shadows, lots of whitespace
- **Layout**: Mobile-first, responsive for web

## Success Criteria
✅ All 5 user roles functional with separate dashboards
✅ Complete QR ticketing flow (purchase → generate → validate)
✅ Recommendation engine updates after 2 events
✅ Sponsor-event matching with AI suggestions
✅ Organizer analytics in real-time
✅ Admin full CRUD and reporting
✅ French/Arabic language toggle
✅ 5% first purchase discount working
✅ Production-ready UI with turquoise theme
✅ No backend dependency (all local storage)

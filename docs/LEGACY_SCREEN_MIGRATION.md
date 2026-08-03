# Flutter Legacy Screen Migration Plan

## Current State

- **36 legacy screens** in `lib/screens/`
- **55 feature screens** in `lib/features/`
- Both systems coexist, creating duplicate code and inconsistent design

## Migration Matrix

| Legacy Screen | Feature Replacement | Status | Action |
|---|---|---|---|
| `screens/home_screen.dart` | `features/shop/shop_screen.dart` | Replaced | Remove after verifying no route references |
| `screens/categories_screen.dart` | `features/discover/discover_screen.dart` | Replaced | Remove |
| `screens/category_businesses_screen.dart` | `features/explore/explore_screen.dart` | Partial | Merge into Explore |
| `screens/search_screen.dart` | `features/explore/explore_screen.dart` | Partial | Merge search into Explore |
| `screens/shopping_screen.dart` | `features/commerce/storefront_screen.dart` | Replaced | Remove |
| `screens/business_detail_screen.dart` | `features/shared/business_detail_screen.dart` | Duplicate | Keep feature version, remove screens/ version |
| `screens/profile_screen.dart` | `features/shared/profile_screen.dart` | Duplicate | Keep feature version |
| `screens/saved_screen.dart` | `features/shared/saved_screen.dart` | Duplicate | Keep feature version |
| `screens/map_screen.dart` | N/A | Keep | No feature replacement yet |
| `screens/notifications_screen.dart` | N/A | Keep | No feature replacement yet |
| `screens/settings_screen.dart` | N/A | Keep | No feature replacement yet |
| `screens/onboarding_screen.dart` | N/A | Keep | Onboarding flow |
| `screens/welcome_screen.dart` | N/A | Keep | Welcome flow |
| `screens/splash_screen.dart` | N/A | Keep | App entry |
| `screens/auth_screen.dart` | N/A | Keep | Auth flow |
| `screens/forgot_password_screen.dart` | N/A | Keep | Auth flow |
| `screens/email_verification_screen.dart` | N/A | Keep | Auth flow |
| `screens/booking_screen.dart` | `features/appointments/booking_summary_screen.dart` | Replaced | Remove |
| `screens/bookings_screen.dart` | Activity centre | Keep | Activity handles bookings |
| `screens/my_bookings_screen.dart` | Activity centre | Keep | Activity handles bookings |
| `screens/my_orders_screen.dart` | Activity centre | Keep | Activity handles orders |
| `screens/my_trips_screen.dart` | Activity centre | Keep | Activity handles trips |
| `screens/my_reports_screen.dart` | N/A | Keep | No feature replacement |
| `screens/my_claims_screen.dart` | N/A | Keep | No feature replacement |
| `screens/report_screen.dart` | N/A | Keep | No feature replacement |
| `screens/review_screen.dart` | `features/shared/` review components | Partial | Merge |
| `screens/chat_screen.dart` | N/A | Keep | Chat feature |
| `screens/conversations_screen.dart` | N/A | Keep | Chat feature |
| `screens/order_screen.dart` | Activity centre | Keep | Activity handles orders |
| `screens/trip_booking_screen.dart` | `features/transport/` | Replaced | Remove |
| `screens/product_list_screen.dart` | `features/commerce/storefront_screen.dart` | Replaced | Remove |
| `screens/owner_dashboard_screen.dart` | Vendor portal (web) | Deprecated | Remove (vendor uses web portal) |
| `screens/booking_calendar_screen.dart` | Vendor portal (web) | Deprecated | Remove |
| `screens/order_management_screen.dart` | Vendor portal (web) | Deprecated | Remove |
| `screens/owner_products_screen.dart` | Vendor portal (web) | Deprecated | Remove |

## Migration Priority

### Phase A — Remove replaced screens (safe)
1. `home_screen.dart` → Shop world
2. `categories_screen.dart` → Discover world
3. `shopping_screen.dart` → Commerce feature
4. `trip_booking_screen.dart` → Transport feature
5. `product_list_screen.dart` → Commerce feature
6. `booking_screen.dart` → Appointments feature

### Phase B — Consolidate duplicates
1. `business_detail_screen.dart` — keep feature version
2. `profile_screen.dart` — keep feature version
3. `saved_screen.dart` — keep feature version

### Phase C — Merge partial replacements
1. `category_businesses_screen.dart` → Explore
2. `search_screen.dart` → Explore
3. `review_screen.dart` → shared components

### Phase D — Remove deprecated vendor screens
1. `owner_dashboard_screen.dart`
2. `booking_calendar_screen.dart`
3. `order_management_screen.dart`
4. `owner_products_screen.dart`

### Phase E — Remaining legacy screens
Keep as-is (no feature replacement yet):
- `map_screen.dart`
- `notifications_screen.dart`
- `settings_screen.dart`
- Auth screens (splash, welcome, onboarding, auth, forgot_password, email_verification)
- Activity screens (bookings, orders, trips, reports, claims)
- Chat screens (chat, conversations)

## Rules
1. Never delete a legacy screen until its replacement is verified working
2. Update all route references before removing
3. Run `dart analyze` after each phase
4. Run `flutter test` after each phase
5. Do not remove screens that are still referenced in `main.dart` routes

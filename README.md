# KF Product Deal - Flutter Mobile App

Flutter mobile application for the Product Deal B2B wholesale platform. Built with Flutter 3.5+ and Riverpod for state management.

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.5+ or higher
- Dart 3.5+
- Android Studio / Xcode (for mobile development)
- Backend API running (see Backend folder)

### Installation

1. **Install dependencies:**
```bash
flutter pub get
```

2. **Configure API endpoint:**
Update `lib/core/networking/api_client.dart` with your backend URL:
```dart
final baseUrl = 'https://product-deal-express.vercel.app/api/v1';
```

3. **Run the app:**
```bash
flutter run
```

### Build for Production

#### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

## 📁 Project Structure

```
Flutter-Mobile/
├── lib/
│   ├── core/                 # Core functionality
│   │   ├── networking/       # API client, Dio setup
│   │   │   ├── api_client.dart
│   │   │   └── dio_provider.dart
│   │   └── storage/          # Secure storage
│   │       └── secure_storage.dart
│   ├── features/             # Feature modules
│   │   ├── auth/            # Authentication
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   └── repositories/
│   │   │   └── presentation/
│   │   │       └── screens/
│   │   ├── dashboard/        # Product browsing
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   └── repositories/
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       └── widgets/
│   │   ├── orders/          # Order management
│   │   │   ├── data/
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── my_orders_screen.dart
│   │   │       │   ├── my_order_detail_screen.dart
│   │   │       │   └── shipment_tracking_screen.dart
│   │   │       └── widgets/
│   │   │           ├── order_status_timeline.dart
│   │   │           └── shipment_timeline.dart
│   │   ├── deals/           # Deal management
│   │   └── stories/          # Story viewing
│   └── shared/              # Shared widgets/utils
│       └── widgets/
│           ├── curved_bottom_nav_bar.dart
│           ├── main_scaffold.dart
│           └── primary_button.dart
├── pubspec.yaml             # Dependencies
└── test/                    # Tests
```

## 🎯 Features

### Authentication
- User login and registration
- JWT token management
- Auto token refresh
- Secure token storage
- Role-based UI restrictions

### Product Browsing
- Product catalog with variants
- Category browsing
- Category tree view
- Product search
- Variant selection
- Product detail with images
- Wholesaler profiles

### Order Management
- Order creation with variants
- Order history
- Order detail with shipments
- Shipment tracking
- Status timeline
- Tracking URL support
- Public tracking screen

### Deal Management
- Deal browsing
- Deal detail
- Group buying participation
- Deal progress tracking

### Story Feature
- Story viewer (WhatsApp-style)
- Auto-advance stories
- Product/deal linking
- Story creation (wholesalers)
- Media support (images/videos)

### Cart & Checkout
- Shopping cart
- Variant selection in cart
- Checkout flow
- Shipping address management
- Payment method selection

## 🛠️ Tech Stack

- **Framework**: Flutter 3.5+
- **Language**: Dart 3.5+
- **State Management**: Riverpod 2.5+
- **Networking**: Dio 5.7+
- **Routing**: GoRouter 14.3+
- **Storage**: Flutter Secure Storage
- **Maps**: Geolocator, Flutter Map
- **UI**: Material Design 3

## 📡 API Integration

The app integrates with the backend API:

### Key Endpoints Used
- `POST /auth/login` - User login
- `POST /auth/refresh` - Refresh token
- `GET /catalog/dashboard` - Dashboard data
- `GET /catalog/products` - List products
- `GET /catalog/products/:id` - Product detail
- `GET /catalog/categories/tree` - Category tree
- `POST /orders` - Create order
- `GET /orders/my` - Get my orders
- `GET /orders/my/:id` - Get order detail
- `GET /catalog/shipments/:trackingNumber` - Track shipment

## 🎨 Key Screens

### Dashboard
- Product grid/list view
- Category navigation
- Featured products
- Wholesaler spotlight
- Stories carousel

### Product Detail
- Product images gallery
- Variant selector
- Price and stock info
- Add to cart
- Wholesaler info

### Order Detail
- Order items list
- Order status
- Shipment timeline
- Status history
- Shipping address
- Payment info

### Shipment Tracking
- Tracking number input
- Shipment details
- Status timeline
- Estimated delivery
- Tracking URL link

## 🔒 Security

- Secure token storage
- Auto token refresh
- Role-based access control
- Secure API communication
- Input validation

## 📦 Dependencies

### Core
- `flutter_riverpod` - State management
- `dio` - HTTP client
- `flutter_secure_storage` - Secure storage
- `go_router` - Navigation

### UI
- `google_fonts` - Custom fonts
- `flutter_animate` - Animations
- `cached_network_image` - Image caching
- `intl` - Internationalization

### Utilities
- `geolocator` - Location services
- `url_launcher` - URL launching
- `image_picker` - Image selection

## 🚀 Deployment

### Android
1. Generate keystore
2. Configure signing in `android/app/build.gradle`
3. Build release APK or App Bundle

### iOS
1. Configure signing in Xcode
2. Update bundle identifier
3. Build release archive

## 📝 License

Proprietary - Not for redistribution

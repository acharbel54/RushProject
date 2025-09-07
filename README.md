# FoodLink 🍎

**FoodLink** is an innovative Flutter mobile application that fights food waste by connecting donors and beneficiaries. Our geolocated platform facilitates the sharing of food surplus within your community.

## 🌟 Main Features

### 🔐 Authentication and User Management
- **Secure Registration/Login** with email validation
- **Three user types**: Donors, Beneficiaries, Administrators
- **Complete profile management** with personalized statistics
- **Password recovery**
- **Offline mode** with local JSON storage

### 🍎 Food Donation Management
- **Donation creation** with photos and geolocation
- **Various categories**: Fruits, vegetables, dairy products, meat, fish, etc.
- **Detailed information**: quantity, expiration date, pickup address
- **Tracking statuses**: Available, reserved, collected, expired
- **Donor management** of their own publications

### 📋 Reservation System
- **Simple reservation** for beneficiaries
- **Pickup slot management**
- **Real-time tracking** of reservation statuses
- **Complete history** of transactions
- **Automatic notifications** for updates

### 🗺️ Geolocation and Mapping
- **Interactive map** with Google Maps
- **Automatic user location**
- **Proximity search** with distance filtering
- **Integrated navigation** to pickup points

### 🔍 Discovery and Search
- **Intuitive discovery interface**
- **Advanced filters** by category, distance, availability
- **Text search** in titles and descriptions
- **Customizable sorting** by date, proximity, urgency

### 🔔 Notification System
- **Real-time push notifications**
- **Personalized alerts**: new reservations, confirmations, expirations
- **Configurable notification settings**
- **Notification history**

### 👨‍💼 Administration
- **Administrator dashboard** with global metrics
- **User management** and moderation
- **Donation and reservation supervision**
- **Detailed application statistics**

## 🛠️ Technologies Used

- **Framework**: Flutter (Dart)
- **Storage**: Local JSON + Firebase (optional)
- **Maps**: Google Maps API
- **Geolocation**: Geolocator
- **Notifications**: Firebase Messaging
- **State Management**: Provider
- **Interface**: Material Design 3

## 📱 Supported Platforms

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows

## 🚀 Installation and Configuration

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code
- Google Cloud Account (for maps)

### Installation

1. **Clone the project**
   ```bash
   git clone https://github.com/acharbel54/foodlink.git
   cd foodlink
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Google Maps Configuration**
   - Create a project on Google Cloud Console
   - Enable Google Maps API
   - Add your API key in:
     - `android/app/src/main/AndroidManifest.xml`
     - `ios/Runner/AppDelegate.swift`

4. **Firebase Configuration (optional)**
   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools
   
   # Configure Firebase
   firebase login
   flutterfire configure
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
lib/
├── core/                    # Core business logic
│   ├── models/             # Data models
│   ├── providers/          # State management
│   ├── services/           # Business services
│   └── utils/              # Utilities
├── features/               # Features by module
│   ├── auth/              # Authentication
│   ├── donations/         # Donation management
│   ├── reservations/      # Reservation system
│   ├── maps/              # Mapping
│   └── notifications/     # Notifications
├── services/              # Storage services
└── shared/                # Shared components
```

## 🎯 Usage

### For Donors
1. **Register** as a donor
2. **Create a donation** with photos and details
3. **Manage received reservations**
4. **Confirm pickups**

### For Beneficiaries
1. **Register** as a beneficiary
2. **Discover available donations**
3. **Reserve** desired products
4. **Pickup** at indicated addresses

## 🔧 Configuration

### Storage Mode
In `lib/core/config/app_config.dart`:
```dart
// Local mode (default)
static const String storageMode = 'local';

// Firebase mode
static const String storageMode = 'firebase';
```

### Customization
- **Theme**: `lib/core/theme/`
- **Localization**: French/English support
- **Permissions**: Geolocation, notifications

## 🤝 Contributing

1. Fork the project
2. Create a branch (`git checkout -b feature/new-feature`)
3. Commit changes (`git commit -m 'Add new feature'`)
4. Push to branch (`git push origin feature/new-feature`)
5. Open a Pull Request

## 📄 License

This project is under MIT license. See the `LICENSE` file for more details.

## 📞 Contact

- **Email**: contact@foodlink.app
- **GitHub**: [FoodLink Repository](https://github.com/acharbel54/foodlink)

## 🙏 Acknowledgments

Thanks to all contributors who make this application possible and who participate in the fight against food waste.

---

**Together, let's reduce food waste! 🌱**
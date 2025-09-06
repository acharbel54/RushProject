import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/simple_auth_provider.dart';
import 'features/onboarding/screens/splash_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/profile_screen.dart';
import 'shared/widgets/bottom_navigation.dart';
import 'features/donations/screens/create_donation_screen.dart';
import 'features/donations/screens/donations_list_screen.dart';
import 'features/reservations/screens/reservations_screen.dart';
import 'features/maps/screens/map_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/notifications/screens/notification_settings_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'core/providers/notification_provider.dart';

void main() {
  runApp(const FoodLinkSimpleApp());
}

class FoodLinkSimpleApp extends StatelessWidget {
  const FoodLinkSimpleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => SimpleAuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'FoodLink - Simple Auth',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const SplashScreen(),
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/home': (context) => const MainNavigationScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/create-donation': (context) => const CreateDonationScreen(),
          '/donations': (context) => const DonationsListScreen(),
          '/reservations': (context) => const ReservationsScreen(),
          '/map': (context) => const MapScreen(),
          '/notifications': (context) => const NotificationsScreen(),
          '/notification-settings': (context) => const NotificationSettingsScreen(),
          '/admin': (context) => const AdminDashboardScreen(),
        },
      ),
    );
  }
}
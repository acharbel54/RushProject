import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const FoodLinkApp());
}

class FoodLinkApp extends StatelessWidget {
  const FoodLinkApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'FoodLink',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          primaryColor: const Color(0xFF4CAF50),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4CAF50),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        
        // Route initiale vers l'onboarding
        initialRoute: OnboardingScreen.routeName,
        
        // Configuration des routes
        routes: {
          OnboardingScreen.routeName: (context) => const OnboardingScreen(),
          LoginScreen.routeName: (context) => const LoginScreen(),
          RegisterScreen.routeName: (context) => const RegisterScreen(),
          ForgotPasswordScreen.routeName: (context) => const ForgotPasswordScreen(),
          MainNavigationScreen.routeName: (context) => const MainNavigationScreen(),
          ProfileScreen.routeName: (context) => const ProfileScreen(),
          CreateDonationScreen.routeName: (context) => const CreateDonationScreen(),
          DonationsListScreen.routeName: (context) => const DonationsListScreen(),
          ReservationsScreen.routeName: (context) => const ReservationsScreen(),
          MapScreen.routeName: (context) => const MapScreen(),
          NotificationsScreen.routeName: (context) => const NotificationsScreen(),
          NotificationSettingsScreen.routeName: (context) => const NotificationSettingsScreen(),
          AdminDashboardScreen.routeName: (context) => const AdminDashboardScreen(),
        },
        
        // Gestionnaire de routes inconnues
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(
                child: Text(
                  'Page non trouvée',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
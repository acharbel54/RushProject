import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'core/providers/simple_auth_provider.dart';
import 'core/providers/local_auth_provider.dart';
import 'core/config/app_config.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart' show NotificationService, firebaseMessagingBackgroundHandler;
import 'features/onboarding/screens/splash_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/profile_screen.dart';
import 'shared/widgets/bottom_navigation.dart';
import 'features/donations/screens/create_donation_screen.dart';
import 'features/donations/screens/new_donation_design_screen.dart';
import 'features/donations/screens/donations_list_screen.dart';
import 'features/reservations/screens/reservations_screen.dart';
import 'features/maps/screens/map_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/notifications/screens/notification_settings_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/donations/screens/donation_detail_screen.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/donation_provider.dart';
import 'core/providers/reservation_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase (optionnel)
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Firebase non configuré, utilisation du mode local: $e');
  }
  
  // Configurer Firestore pour le développement
  if (kDebugMode) {
    try {
      // Désactiver la persistance pour éviter les conflits
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    } catch (e) {
      print('Erreur de configuration Firestore: $e');
    }
  }
  
  // Configurer le handler pour les messages en background
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialiser le service de notifications
  try {
    await NotificationService().initialize();
  } catch (e) {
    print('Erreur lors de l\'initialisation des notifications: $e');
  }
  
  runApp(const FoodLinkApp());
}

class FoodLinkApp extends StatelessWidget {
  const FoodLinkApp({Key? key}) : super(key: key);

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
        ChangeNotifierProvider(
          create: (context) => DonationProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => ReservationProvider(),
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
          
          // Configuration des thèmes des composants
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(AppConfig.primaryColorValue),
              side: BorderSide(
                color: Color(AppConfig.primaryColorValue),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4CAF50),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Color(AppConfig.primaryColorValue),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            labelStyle: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
          
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            elevation: 8,
            selectedItemColor: Color(0xFF4CAF50),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        
        // Configuration des localisations
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', 'US'), // Anglais
          Locale('fr', 'FR'), // Français
        ],
        locale: const Locale('fr', 'FR'), // Locale par défaut
        
        // Route initiale
        initialRoute: SplashScreen.routeName,
        
        // Configuration des routes
        routes: {
          SplashScreen.routeName: (context) => const SplashScreen(),
          OnboardingScreen.routeName: (context) => const OnboardingScreen(),
          LoginScreen.routeName: (context) => const LoginScreen(),
          RegisterScreen.routeName: (context) => const RegisterScreen(),
          ForgotPasswordScreen.routeName: (context) => const ForgotPasswordScreen(),
          MainNavigationScreen.routeName: (context) => const MainNavigationScreen(),
          ProfileScreen.routeName: (context) => const ProfileScreen(),
          CreateDonationScreen.routeName: (context) => const CreateDonationScreen(),
          '/new-donation-design': (context) => const NewDonationDesignScreen(),
          DonationsListScreen.routeName: (context) => const DonationsListScreen(),
          ReservationsScreen.routeName: (context) => const ReservationsScreen(),
          MapScreen.routeName: (context) => const MapScreen(),
          NotificationsScreen.routeName: (context) => const NotificationsScreen(),
          NotificationSettingsScreen.routeName: (context) => const NotificationSettingsScreen(),
          AdminDashboardScreen.routeName: (context) => const AdminDashboardScreen(),
          DonationDetailScreen.routeName: (context) {
            final donationId = ModalRoute.of(context)!.settings.arguments as String;
            return DonationDetailScreen(donationId: donationId);
          },
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
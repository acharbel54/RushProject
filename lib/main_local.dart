import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'core/providers/local_auth_provider.dart';
import 'core/providers/notification_provider.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pas besoin d'initialiser Firebase pour le stockage local
  if (kDebugMode) {
    print('Application démarrée en mode stockage local');
  }
  
  runApp(const FoodLinkLocalApp());
}

class FoodLinkLocalApp extends StatelessWidget {
  const FoodLinkLocalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => LocalAuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => NotificationProvider(),
        ),
        // TODO: Ajouter d'autres providers locaux (LocalDonationProvider, etc.)
      ],
      child: MaterialApp(
        title: 'FoodLink - Local Storage',
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4CAF50),
              side: const BorderSide(color: Color(0xFF4CAF50)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF4CAF50),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFF4CAF50),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            elevation: 8,
          ),
        ),
        
        // Route initiale vers le splash screen
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
          DonationsListScreen.routeName: (context) => const DonationsListScreen(),
          ReservationsScreen.routeName: (context) => const ReservationsScreen(),
          MapScreen.routeName: (context) => const MapScreen(),
          NotificationsScreen.routeName: (context) => const NotificationsScreen(),
          NotificationSettingsScreen.routeName: (context) => const NotificationSettingsScreen(),
          AdminDashboardScreen.routeName: (context) => const AdminDashboardScreen(),
        },
        
        // Gestionnaire de routes pour les routes dynamiques
        onGenerateRoute: (settings) {
          // Ici, vous pouvez gérer des routes avec des paramètres
          // Par exemple: '/donation/123' ou '/user/456'
          return null;
        },
        
        // Gestionnaire d'erreur de route
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(
                child: Text(
                  'Page non trouvée',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Classe pour le splash screen local
class LocalSplashScreen extends StatefulWidget {
  static const String routeName = '/local-splash';
  
  const LocalSplashScreen({Key? key}) : super(key: key);

  @override
  State<LocalSplashScreen> createState() => _LocalSplashScreenState();
}

class _LocalSplashScreenState extends State<LocalSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
    _initializeLocalApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocalApp() async {
    final authProvider = Provider.of<LocalAuthProvider>(context, listen: false);
    
    // Attendre que l'animation se termine
    await Future.delayed(const Duration(milliseconds: 3000));
    
    if (!mounted) return;
    
    try {
      // Vérifier si l'utilisateur est déjà connecté localement
      await authProvider.checkAuthState();
      
      if (!mounted) return;
      
      if (authProvider.isAuthenticated) {
        // Utilisateur connecté, aller à l'écran principal
        Navigator.of(context).pushReplacementNamed(MainNavigationScreen.routeName);
      } else {
        // Pas connecté, aller à l'onboarding
        Navigator.of(context).pushReplacementNamed(OnboardingScreen.routeName);
      }
    } catch (e) {
      // En cas d'erreur, aller à l'écran de connexion
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4CAF50),
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo de l'application
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        size: 60,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Nom de l'application
                    const Text(
                      'FoodLink',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Sous-titre
                    const Text(
                      'Mode Stockage Local',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Indicateur de chargement
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
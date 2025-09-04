import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../auth/screens/login_screen.dart';
import 'onboarding_screen.dart';
import '../../../shared/widgets/bottom_navigation.dart';

class SplashScreen extends StatefulWidget {
  static const String routeName = '/splash';
  
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
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
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));
    
    _animationController.forward();
    
    // Initialiser l'authentification et naviguer après 3 secondes
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Attendre que l'animation se termine
    await Future.delayed(const Duration(milliseconds: 3000));
    
    if (!mounted) return;
    
    try {
      // Vérifier si l'utilisateur est déjà connecté
      await authProvider.checkAuthState();
      
      if (!mounted) return;
      
      // Vérifier si c'est la première fois que l'utilisateur ouvre l'app
      final isFirstTime = await _checkFirstTime();
      
      if (authProvider.isAuthenticated) {
        // Utilisateur connecté, aller à l'écran principal
        Navigator.of(context).pushReplacementNamed(MainNavigationScreen.routeName);
      } else if (isFirstTime) {
        // Première fois, montrer l'onboarding
        Navigator.of(context).pushReplacementNamed(OnboardingScreen.routeName);
      } else {
        // Pas la première fois, aller directement à la connexion
        Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      }
    } catch (e) {
      // En cas d'erreur, aller à l'écran de connexion
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
      }
    }
  }

  Future<bool> _checkFirstTime() async {
    // TODO: Implémenter la vérification avec SharedPreferences
    // Pour l'instant, on considère que c'est toujours la première fois
    return true;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
                    // Logo principal
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        size: 60,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Nom de l'application
                    const Text(
                      'FoodLink',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Slogan
                    const Text(
                      'Moins de gaspillage, plus de solidarité.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 60),
                    
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
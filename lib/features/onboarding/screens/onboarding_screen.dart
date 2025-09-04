import 'package:flutter/material.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  static const String routeName = '/onboarding';
  
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Bienvenue sur FoodLink',
      description: 'Rejoignez une communauté engagée contre le gaspillage alimentaire. Donnez ou recevez de la nourriture facilement.',
      imagePath: 'assets/images/onboarding1.svg',
      backgroundColor: const Color(0xFF4CAF50),
    ),
    OnboardingPage(
      title: 'Partagez vos surplus',
      description: 'Vous avez trop de nourriture ? Partagez-la avec ceux qui en ont besoin. Chaque don compte pour réduire le gaspillage.',
      imagePath: 'assets/images/onboarding2.svg',
      backgroundColor: const Color(0xFFFF9800),
    ),
    OnboardingPage(
      title: 'Trouvez de la nourriture',
      description: 'Découvrez les dons disponibles près de chez vous. Réservez facilement et récupérez gratuitement.',
      imagePath: 'assets/images/onboarding3.svg',
      backgroundColor: const Color(0xFF2196F3),
    ),
    OnboardingPage(
      title: 'Ensemble, agissons',
      description: 'Rejoignez des milliers de personnes qui luttent contre le gaspillage alimentaire. Votre impact compte !',
      imagePath: 'assets/images/onboarding4.svg',
      backgroundColor: const Color(0xFF9C27B0),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() {
    // TODO: Marquer l'onboarding comme terminé dans SharedPreferences
    Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
  }

  void _skipOnboarding() {
    Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Pages de l'onboarding
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),
          
          // Bouton Skip en haut à droite
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _skipOnboarding,
              child: const Text(
                'Passer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          // Indicateurs de page et boutons de navigation
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicateurs de page
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Boutons de navigation
                  Row(
                    children: [
                      // Bouton Précédent
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousPage,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Précédent',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      
                      if (_currentPage > 0) const SizedBox(width: 16),
                      
                      // Bouton Suivant/Commencer
                      Expanded(
                        flex: _currentPage == 0 ? 1 : 1,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _pages[_currentPage].backgroundColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1 ? 'Commencer' : 'Suivant',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Lien vers l'inscription directe
                  if (_currentPage == _pages.length - 1)
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacementNamed(RegisterScreen.routeName);
                      },
                      child: const Text(
                        'Créer un compte maintenant',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            page.backgroundColor,
            page.backgroundColor.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 60),
              
              // Illustration
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  child: _buildIllustration(page),
                ),
              ),
              
              // Contenu textuel
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Text(
                      page.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Text(
                      page.description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 120), // Espace pour les boutons
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(OnboardingPage page) {
    // Pour l'instant, on utilise des icônes. Plus tard, on pourra remplacer par des SVG
    IconData icon;
    switch (_currentPage) {
      case 0:
        icon = Icons.restaurant;
        break;
      case 1:
        icon = Icons.volunteer_activism;
        break;
      case 2:
        icon = Icons.search;
        break;
      case 3:
        icon = Icons.people;
        break;
      default:
        icon = Icons.restaurant;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        icon,
        size: 120,
        color: Colors.white,
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String imagePath;
  final Color backgroundColor;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.backgroundColor,
  });
}
// Configuration de l'application pour choisir entre Firebase et stockage local

class AppConfig {
  // Mode de stockage : 'firebase' ou 'local'
  static const String storageMode = 'local'; // Changez en 'firebase' pour utiliser Firebase
  
  // Configuration Firebase
  static const bool useFirebase = storageMode == 'firebase';
  
  // Configuration du stockage local
  static const bool useLocalStorage = storageMode == 'local';
  
  // Nom de l'application selon le mode
  static String get appName {
    switch (storageMode) {
      case 'firebase':
        return 'FoodLink';
      case 'local':
        return 'FoodLink - Local';
      default:
        return 'FoodLink';
    }
  }
  
  // Titre de l'application
  static String get appTitle {
    switch (storageMode) {
      case 'firebase':
        return 'FoodLink';
      case 'local':
        return 'FoodLink - Stockage Local';
      default:
        return 'FoodLink';
    }
  }
  
  // Couleur principale selon le mode
  static int get primaryColorValue {
    switch (storageMode) {
      case 'firebase':
        return 0xFF4CAF50; // Vert normal
      case 'local':
        return 0xFF2E7D32; // Vert plus foncé pour le mode local
      default:
        return 0xFF4CAF50;
    }
  }
  
  // Configuration de debug
  static const bool enableDebugLogs = true;
  
  // Configuration des fonctionnalités
  static const bool enableNotifications = true;
  static const bool enableGoogleSignIn = useFirebase; // Seulement avec Firebase
  static const bool enableOfflineMode = useLocalStorage;
  
  // Chemins des fichiers de stockage local
  static const String localStorageDirectory = 'foodlink_data';
  static const String usersFileName = 'users.json';
  static const String donationsFileName = 'donations.json';
  static const String reservationsFileName = 'reservations.json';
  static const String notificationsFileName = 'notifications.json';
  
  // Configuration des timeouts (en millisecondes)
  static const int authTimeout = 30000; // 30 secondes
  static const int dataTimeout = 15000;  // 15 secondes
  
  // Configuration de la pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Configuration des images
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];
  
  // Configuration de la géolocalisation
  static const double defaultLatitude = 48.8566; // Paris
  static const double defaultLongitude = 2.3522;
  static const double searchRadius = 10.0; // km
  
  // Messages de configuration
  static String get storageInfo {
    switch (storageMode) {
      case 'firebase':
        return 'Utilisation de Firebase pour le stockage des données';
      case 'local':
        return 'Utilisation du stockage local (fichiers JSON)';
      default:
        return 'Mode de stockage non configuré';
    }
  }
  
  // Validation de la configuration
  static bool get isConfigValid {
    return storageMode == 'firebase' || storageMode == 'local';
  }
  
  // Méthode pour obtenir les informations de configuration
  static Map<String, dynamic> getConfigInfo() {
    return {
      'storageMode': storageMode,
      'useFirebase': useFirebase,
      'useLocalStorage': useLocalStorage,
      'appName': appName,
      'appTitle': appTitle,
      'primaryColor': primaryColorValue,
      'enableNotifications': enableNotifications,
      'enableGoogleSignIn': enableGoogleSignIn,
      'enableOfflineMode': enableOfflineMode,
      'isConfigValid': isConfigValid,
      'storageInfo': storageInfo,
    };
  }
  
  // Méthode pour imprimer la configuration (debug)
  static void printConfig() {
    if (enableDebugLogs) {
      print('=== Configuration de l\'application ===');
      final config = getConfigInfo();
      config.forEach((key, value) {
        print('$key: $value');
      });
      print('=====================================');
    }
  }
}
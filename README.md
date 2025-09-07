# FoodLink 🍎

**FoodLink** est une application mobile Flutter innovante qui lutte contre le gaspillage alimentaire en connectant donateurs et bénéficiaires. Notre plateforme géolocalisée facilite le partage de surplus alimentaires au sein de votre communauté.

## 🌟 Fonctionnalités principales

### 🔐 Authentification et gestion des utilisateurs
- **Inscription/Connexion sécurisée** avec validation d'email
- **Trois types d'utilisateurs** : Donateurs, Bénéficiaires, Administrateurs
- **Gestion de profil complète** avec statistiques personnalisées
- **Récupération de mot de passe**
- **Mode hors ligne** avec stockage local JSON

### 🍎 Gestion des dons alimentaires
- **Création de dons** avec photos et géolocalisation
- **Catégories variées** : Fruits, légumes, produits laitiers, viande, poisson, etc.
- **Informations détaillées** : quantité, date d'expiration, adresse de récupération
- **Statuts de suivi** : Disponible, réservé, récupéré, expiré
- **Gestion par le donateur** de ses propres publications

### 📋 Système de réservations
- **Réservation simple** pour les bénéficiaires
- **Gestion des créneaux** de récupération
- **Suivi en temps réel** des statuts de réservation
- **Historique complet** des transactions
- **Notifications automatiques** pour les mises à jour

### 🗺️ Géolocalisation et cartographie
- **Carte interactive** avec Google Maps
- **Localisation automatique** de l'utilisateur
- **Recherche par proximité** avec filtrage par distance
- **Navigation intégrée** vers les points de récupération

### 🔍 Découverte et recherche
- **Interface de découverte** intuitive
- **Filtres avancés** par catégorie, distance, disponibilité
- **Recherche textuelle** dans les titres et descriptions
- **Tri personnalisable** par date, proximité, urgence

### 🔔 Système de notifications
- **Notifications push** en temps réel
- **Alertes personnalisées** : nouvelles réservations, confirmations, expirations
- **Paramètres de notification** configurables
- **Historique des notifications**

### 👨‍💼 Administration
- **Tableau de bord administrateur** avec métriques globales
- **Gestion des utilisateurs** et modération
- **Supervision des dons** et réservations
- **Statistiques détaillées** de l'application

## 🛠️ Technologies utilisées

- **Framework** : Flutter (Dart)
- **Stockage** : JSON local + Firebase (optionnel)
- **Cartes** : Google Maps API
- **Géolocalisation** : Geolocator
- **Notifications** : Firebase Messaging
- **Gestion d'état** : Provider
- **Interface** : Material Design 3

## 📱 Plateformes supportées

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows

## 🚀 Installation et configuration

### Prérequis
- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code
- Compte Google Cloud (pour les cartes)

### Installation

1. **Cloner le projet**
   ```bash
   git clone https://github.com/votre-username/foodlink.git
   cd foodlink
   ```

2. **Installer les dépendances**
   ```bash
   flutter pub get
   ```

3. **Configuration Google Maps**
   - Créer un projet sur Google Cloud Console
   - Activer l'API Google Maps
   - Ajouter votre clé API dans :
     - `android/app/src/main/AndroidManifest.xml`
     - `ios/Runner/AppDelegate.swift`

4. **Configuration Firebase (optionnel)**
   ```bash
   # Installer Firebase CLI
   npm install -g firebase-tools
   
   # Configurer Firebase
   firebase login
   flutterfire configure
   ```

5. **Lancer l'application**
   ```bash
   flutter run
   ```

## 📁 Structure du projet

```
lib/
├── core/                    # Logique métier centrale
│   ├── models/             # Modèles de données
│   ├── providers/          # Gestion d'état
│   ├── services/           # Services métier
│   └── utils/              # Utilitaires
├── features/               # Fonctionnalités par module
│   ├── auth/              # Authentification
│   ├── donations/         # Gestion des dons
│   ├── reservations/      # Système de réservations
│   ├── maps/              # Cartographie
│   └── notifications/     # Notifications
├── services/              # Services de stockage
└── shared/                # Composants partagés
```

## 🎯 Utilisation

### Pour les donateurs
1. **S'inscrire** en tant que donateur
2. **Créer un don** avec photos et détails
3. **Gérer les réservations** reçues
4. **Confirmer les récupérations**

### Pour les bénéficiaires
1. **S'inscrire** en tant que bénéficiaire
2. **Découvrir les dons** disponibles
3. **Réserver** les produits souhaités
4. **Récupérer** aux adresses indiquées

## 🔧 Configuration

### Mode de stockage
Dans `lib/core/config/app_config.dart` :
```dart
// Mode local (par défaut)
static const String storageMode = 'local';

// Mode Firebase
static const String storageMode = 'firebase';
```

### Personnalisation
- **Thème** : `lib/core/theme/`
- **Localisation** : Support français/anglais
- **Permissions** : Géolocalisation, notifications

## 🤝 Contribution

1. Fork le projet
2. Créer une branche (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Commit les changements (`git commit -m 'Ajout nouvelle fonctionnalité'`)
4. Push vers la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. Ouvrir une Pull Request

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails.

## 📞 Contact

- **Email** : contact@foodlink.app
- **GitHub** : [FoodLink Repository](https://github.com/votre-username/foodlink)

## 🙏 Remerciements

Merci à tous les contributeurs qui rendent cette application possible et qui participent à la lutte contre le gaspillage alimentaire.

---

**Ensemble, réduisons le gaspillage alimentaire ! 🌱**
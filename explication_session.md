# Comment l'application détermine-t-elle si l'utilisateur junior est connecté ?

## Problème identifié 🔍

Après analyse du code, voici comment fonctionne actuellement la gestion de session :

### 1. Stockage des utilisateurs
- Les utilisateurs sont sauvegardés dans : `Documents/base_de_donnees/userinfo.json`
- Le fichier contient bien l'utilisateur junior@gmail.com avec le rôle "beneficiaire"

### 2. Gestion de la session (LE PROBLÈME)
```dart
// Dans SimpleAuthService
class SimpleAuthService {
  SimpleUser? _currentUser;  // ⚠️ STOCKÉ EN MÉMOIRE SEULEMENT
  
  // Lors de la connexion
  Future<SimpleUser?> signIn({required String email, required String password}) async {
    final user = _users.firstWhere(...);
    _currentUser = user;  // ✅ Défini lors de la connexion
    return user;
  }
  
  // Getter pour l'utilisateur actuel
  SimpleUser? get currentUser => _currentUser;  // ❌ null au redémarrage
}
```

### 3. Le problème au démarrage
```dart
// Dans SimpleAuthProvider
Future<void> _initializeAuth() async {
  await _authService.initialize();
  _currentUser = _authService.currentUser;  // ❌ Toujours null au démarrage !
}
```

## Pourquoi junior n'est pas "connecté" ?

1. **Au démarrage de l'app** : `_currentUser = null`
2. **L'utilisateur doit se reconnecter** à chaque fois
3. **Aucune persistance de session** n'est implémentée
4. **Le fichier userinfo.json** contient les utilisateurs mais pas la session active

## Solution nécessaire 🛠️

Pour que junior reste connecté, il faut :

1. **Sauvegarder la session** (ex: SharedPreferences)
2. **Restaurer automatiquement** la session au démarrage
3. **Ou implémenter un "Remember me"**

C'est pourquoi la navigation ne s'adapte pas : l'app pense qu'aucun utilisateur n'est connecté !
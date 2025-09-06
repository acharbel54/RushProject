import 'dart:convert';
import 'dart:io';
import 'lib/core/services/simple_auth_service.dart';
import 'lib/core/models/user_model.dart';

void main() async {
  print('=== DEBUG UTILISATEUR ACTUEL ===');
  
  final authService = SimpleAuthService();
  
  try {
    // Charger l'utilisateur actuel
    final user = await authService.getCurrentUser();
    
    if (user != null) {
      print('✅ Utilisateur trouvé:');
      print('   Email: ${user.email}');
      print('   Nom: ${user.displayName}');
      print('   Rôle: ${user.role}');
      print('   Rôle (string): ${user.role.name}');
      print('   Est donateur: ${user.role == UserRole.donateur}');
      print('   Est bénéficiaire: ${user.role == UserRole.beneficiaire}');
      print('   Est admin: ${user.role == UserRole.admin}');
      
      // Vérifier le fichier JSON
      final file = File('userinfo.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        print('\n📄 Contenu du fichier userinfo.json:');
        print(content);
        
        final json = jsonDecode(content);
        print('\n🔍 Analyse du JSON:');
        print('   role (brut): "${json['role']}"');
        print('   type: ${json['role'].runtimeType}');
      }
    } else {
      print('❌ Aucun utilisateur connecté');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
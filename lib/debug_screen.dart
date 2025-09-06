import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/simple_auth_provider.dart';
import 'core/services/simple_auth_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String debugInfo = 'Chargement...';

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    try {
      final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
      final users = authProvider.getAllUsers();
      
      String info = 'Informations de débogage:\n\n';
      info += 'Nombre d\'utilisateurs: ${users.length}\n\n';
      
      if (users.isEmpty) {
        info += 'Aucun utilisateur trouvé.\n';
      } else {
        info += 'Utilisateurs trouvés:\n';
        for (int i = 0; i < users.length; i++) {
          final user = users[i];
          info += '${i + 1}. ${user.displayName} (${user.email})\n';
          info += '   Rôle: ${user.role.toString().split('.').last}\n';
          info += '   ID: ${user.id}\n\n';
        }
      }
      
      final currentUser = authProvider.currentUser;
      if (currentUser != null) {
        info += 'Utilisateur connecté: ${currentUser.displayName}\n';
        info += 'Rôle: ${currentUser.role.toString().split('.').last}\n';
      } else {
        info += 'Aucun utilisateur connecté.\n';
      }
      
      setState(() {
        debugInfo = info;
      });
    } catch (e) {
      setState(() {
        debugInfo = 'Erreur: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Info'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                debugInfo,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadDebugInfo,
                child: const Text('Actualiser'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
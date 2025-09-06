import 'package:flutter/material.dart';
import 'lib/core/services/simple_auth_service.dart';

void main() {
  runApp(const TestLoginApp());
}

class TestLoginApp extends StatelessWidget {
  const TestLoginApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Connexion',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const TestLoginScreen(),
    );
  }
}

class TestLoginScreen extends StatefulWidget {
  const TestLoginScreen({Key? key}) : super(key: key);

  @override
  State<TestLoginScreen> createState() => _TestLoginScreenState();
}

class _TestLoginScreenState extends State<TestLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = SimpleAuthService();
  bool _isLoading = false;
  String? _message;
  SimpleUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    await _authService.initialize();
    
    // Pré-remplir avec l'utilisateur existant pour faciliter le test
    final users = _authService.getAllUsers();
    if (users.isNotEmpty) {
      _emailController.text = users.first.email;
      _passwordController.text = users.first.password;
    }
    setState(() {});
  }

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final result = await _authService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (result != null) {
        setState(() {
          _currentUser = result;
          _message = 'Connexion réussie ! Bienvenue ${result.displayName}';
          _isLoading = false;
        });
      } else {
        setState(() {
          _message = 'Email ou mot de passe incorrect';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  void _logout() {
    _authService.signOut();
    setState(() {
      _currentUser = null;
      _message = 'Déconnexion réussie';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de Connexion JSON'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_currentUser != null) ...[
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Utilisateur connecté:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Nom: ${_currentUser!.displayName}'),
                      Text('Email: ${_currentUser!.email}'),
                      Text('Rôle: ${_currentUser!.role}'),
                      Text('ID: ${_currentUser!.id}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Se déconnecter'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const Text(
                'Test de connexion avec le fichier JSON',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _testLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Tester la connexion',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
            const SizedBox(height: 20),
            if (_message != null)
              Card(
                color: _message!.contains('réussie')
                    ? Colors.green[50]
                    : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _message!.contains('réussie')
                          ? Colors.green[800]
                          : Colors.red[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            const Spacer(),
            FutureBuilder<List<SimpleUser>>(
              future: Future.value(_authService.getAllUsers()),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Utilisateurs disponibles:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...snapshot.data!.map(
                            (user) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '• ${user.email} (${user.role})',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
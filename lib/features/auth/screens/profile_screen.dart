import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/simple_auth_provider.dart';
import '../../../core/services/simple_auth_service.dart';
import '../../../core/models/user_model.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const String routeName = '/profile';
  
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _preferredZoneController = TextEditingController();
  
  List<String> _selectedDietaryPreferences = [];
  List<String> _selectedAllergies = [];
  
  final List<String> _availableDietaryPreferences = [
    'Végétarien',
    'Végétalien',
    'Sans gluten',
    'Halal',
    'Casher',
    'Bio uniquement',
    'Produits locaux',
  ];
  
  final List<String> _availableAllergies = [
    'Arachides',
    'Fruits à coque',
    'Lait',
    'Œufs',
    'Poisson',
    'Crustacés',
    'Soja',
    'Gluten',
    'Sésame',
  ];
  
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    
    print('DEBUG ProfileScreen: _loadUserData called');
    print('DEBUG ProfileScreen: user = $user');
    
    if (user != null) {
      print('DEBUG ProfileScreen: user.role = ${user.role}');
      print('DEBUG ProfileScreen: user.displayName = ${user.displayName}');
      print('DEBUG ProfileScreen: user.phoneNumber = ${user.phoneNumber}');
      print('DEBUG ProfileScreen: user.address = ${user.address}');
      print('DEBUG ProfileScreen: user.preferredPickupZone = ${user.preferredPickupZone}');
      print('DEBUG ProfileScreen: user.dietaryPreferences = ${user.dietaryPreferences}');
      print('DEBUG ProfileScreen: user.allergies = ${user.allergies}');
      
      _nameController.text = user.displayName ?? '';
      _phoneController.text = user.phoneNumber ?? '';
      _addressController.text = user.address ?? '';
      _preferredZoneController.text = user.preferredPickupZone ?? '';
      _selectedDietaryPreferences = List.from(user.dietaryPreferences ?? []);
      _selectedAllergies = List.from(user.allergies ?? []);
      
      print('DEBUG ProfileScreen: Controllers loaded');
      print('DEBUG ProfileScreen: _preferredZoneController.text = ${_preferredZoneController.text}');
      print('DEBUG ProfileScreen: _selectedDietaryPreferences = $_selectedDietaryPreferences');
      print('DEBUG ProfileScreen: _selectedAllergies = $_selectedAllergies');
    } else {
      print('DEBUG ProfileScreen: user is null!');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _preferredZoneController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    
    try {
      final success = await authProvider.updateProfile(
        displayName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        preferredPickupZone: _preferredZoneController.text.trim().isEmpty ? null : _preferredZoneController.text.trim(),
        dietaryPreferences: _selectedDietaryPreferences.isEmpty ? null : _selectedDietaryPreferences,
        allergies: _selectedAllergies.isEmpty ? null : _selectedAllergies,
      );
      
      if (mounted) {
        if (success) {
          setState(() {
            _isEditing = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil mis à jour avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Erreur lors de la mise à jour'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    await authProvider.signOut();
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          LoginScreen.routeName,
          (route) => false,
        );
      }
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront définitivement supprimées.\n\nÊtes-vous sûr de vouloir supprimer votre compte ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Suppression de compte non implémentée dans SimpleAuthProvider
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Suppression de compte non disponible en mode simple'),
        backgroundColor: Colors.orange,
      ),
    );
        
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            LoginScreen.routeName,
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mon Profil',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black87),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
        ],
      ),
      body: Consumer<SimpleAuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          
          if (user == null) {
            return const Center(
              child: Text('Utilisateur non connecté'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // En-tête du profil
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: user.role == UserRole.donateur
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF9800),
                        child: Icon(
                          user.role.toString().contains('donateur')
                              ? Icons.volunteer_activism
                              : Icons.people,
                          size: 50,
                                color: Colors.white,
                              ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Nom
                      Text(
                        user.displayName ?? 'Utilisateur',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Type d'utilisateur
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: user.role == UserRole.donateur
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF9800),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.role == UserRole.donateur ? 'Donateur' : 'Bénéficiaire',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Email
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Formulaire d'édition ou informations
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _isEditing ? _buildEditForm() : _buildInfoDisplay(user),
                ),
                
                const SizedBox(height: 16),
                
                // Statistiques (pour les donateurs)
                if (user.role == UserRole.donateur) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mes statistiques',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                  'Dons créés',
                                  '${user.totalDonations}',
                                  Icons.restaurant,
                                  const Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Kg donnés',
                                '${user.totalKgDonated.toStringAsFixed(1)} kg',
                                Icons.scale,
                                const Color(0xFFFF9800),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Statistiques (pour les bénéficiaires)
                if (user.role == UserRole.beneficiaire) ...[
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mes statistiques',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Réservations',
                                '${user.totalReservations ?? 0}',
                                Icons.bookmark,
                                const Color(0xFFFF9800),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Dons reçus',
                                '0', // TODO: Calculer depuis les dons reçus
                                Icons.card_giftcard,
                                const Color(0xFF9C27B0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Économies',
                                '0€', // TODO: Calculer les économies
                                Icons.savings,
                                const Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Impact CO₂',
                                '0kg', // TODO: Calculer l'impact CO₂
                                Icons.eco,
                                const Color(0xFF009688),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                 ],
                 
                 // Historique des réservations pour les bénéficiaires
                 if (user.role == UserRole.beneficiaire) ...[
                   Container(
                     margin: const EdgeInsets.symmetric(horizontal: 16),
                     padding: const EdgeInsets.all(20),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(12),
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.05),
                           blurRadius: 10,
                           offset: const Offset(0, 2),
                         ),
                       ],
                     ),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Row(
                           children: [
                             const Icon(Icons.history, color: Colors.black54),
                             const SizedBox(width: 8),
                             const Text(
                               'Historique des réservations',
                               style: TextStyle(
                                 fontSize: 18,
                                 fontWeight: FontWeight.w600,
                                 color: Colors.black87,
                               ),
                             ),
                           ],
                         ),
                         const SizedBox(height: 16),
                         _buildReservationHistory(),
                       ],
                     ),
                   ),
                   const SizedBox(height: 16),
                 ],
                 
                 // Actions
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Déconnexion
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _handleSignOut,
                          icon: const Icon(Icons.logout, color: Colors.orange),
                          label: const Text(
                            'Se déconnecter',
                            style: TextStyle(color: Colors.orange),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Supprimer le compte
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _handleDeleteAccount,
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          label: const Text(
                            'Supprimer mon compte',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Modifier mes informations',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Nom
          AuthTextField(
            controller: _nameController,
            labelText: 'Nom complet',
            prefixIcon: Icons.person_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre nom';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Téléphone
          AuthTextField(
            controller: _phoneController,
            labelText: 'Téléphone',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
          ),
          
          const SizedBox(height: 16),
          
          // Adresse
          AuthTextField(
            controller: _addressController,
            labelText: 'Adresse',
            prefixIcon: Icons.location_on_outlined,
            maxLines: 2,
          ),
          
          // Champs spécifiques aux bénéficiaires
          Consumer<SimpleAuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.currentUser;
              if (user?.role == UserRole.beneficiaire) {
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _preferredZoneController,
                      labelText: 'Zone de récupération préférée',
                      prefixIcon: Icons.place_outlined,
                    ),
                    
                    const SizedBox(height: 16),
                    _buildMultiSelectField(
                      'Préférences alimentaires',
                      _availableDietaryPreferences,
                      _selectedDietaryPreferences,
                      Icons.restaurant_outlined,
                      (selected) => setState(() => _selectedDietaryPreferences = selected),
                    ),
                    
                    const SizedBox(height: 16),
                    _buildMultiSelectField(
                      'Allergies',
                      _availableAllergies,
                      _selectedAllergies,
                      Icons.warning_outlined,
                      (selected) => setState(() => _selectedAllergies = selected),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          const SizedBox(height: 24),
          
          // Boutons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                    });
                    _loadUserData(); // Recharger les données originales
                  },
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AuthButton(
                  text: 'Sauvegarder',
                  onPressed: _isLoading ? null : _handleUpdateProfile,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDisplay(SimpleUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mes informations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 20),
        
        _buildInfoRow('Téléphone', user.phoneNumber ?? 'Non renseigné', Icons.phone_outlined),
        const SizedBox(height: 16),
        _buildInfoRow('Adresse', user.address ?? 'Non renseignée', Icons.location_on_outlined),
        
        // Informations spécifiques aux bénéficiaires
        if (user.role == UserRole.beneficiaire) ...[
          const SizedBox(height: 16),
          _buildInfoRow('Zone préférée', user.preferredPickupZone ?? 'Non renseignée', Icons.place_outlined),
          if (user.dietaryPreferences != null && user.dietaryPreferences!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow('Préférences alimentaires', user.dietaryPreferences!.join(', '), Icons.restaurant_outlined),
          ],
          if (user.allergies != null && user.allergies!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow('Allergies', user.allergies!.join(', '), Icons.warning_outlined),
          ],
        ],
        
        const SizedBox(height: 16),
        _buildInfoRow('Membre depuis', _formatDate(user.createdAt), Icons.calendar_today_outlined),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.black54,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectField(
    String label,
    List<String> availableOptions,
    List<String> selectedOptions,
    IconData icon,
    Function(List<String>) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.black54),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableOptions.map((option) {
            final isSelected = selectedOptions.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                final newSelection = List<String>.from(selectedOptions);
                if (selected) {
                  newSelection.add(option);
                } else {
                  newSelection.remove(option);
                }
                onChanged(newSelection);
              },
              selectedColor: const Color(0xFF4CAF50).withOpacity(0.2),
              checkmarkColor: const Color(0xFF4CAF50),
            );
          }).toList(),
        ),
      ],
    );
  }
 
   Widget _buildReservationHistory() {
     // TODO: Récupérer les vraies réservations depuis le service
     final mockReservations = [
       {
         'title': 'Légumes frais',
         'date': DateTime.now().subtract(const Duration(days: 2)),
         'status': 'Récupéré',
         'location': 'Marché Central',
         'savings': '12€',
       },
       {
         'title': 'Pain et viennoiseries',
         'date': DateTime.now().subtract(const Duration(days: 5)),
         'status': 'Récupéré',
         'location': 'Boulangerie Dupont',
         'savings': '8€',
       },
       {
         'title': 'Produits laitiers',
         'date': DateTime.now().subtract(const Duration(days: 8)),
         'status': 'Annulé',
         'location': 'Supermarché Bio',
         'savings': '0€',
       },
     ];
 
     if (mockReservations.isEmpty) {
       return Container(
         padding: const EdgeInsets.all(20),
         child: Column(
           children: [
             Icon(
               Icons.inbox_outlined,
               size: 48,
               color: Colors.grey[400],
             ),
             const SizedBox(height: 12),
             Text(
               'Aucune réservation pour le moment',
               style: TextStyle(
                 color: Colors.grey[600],
                 fontSize: 16,
               ),
             ),
             const SizedBox(height: 8),
             Text(
               'Vos réservations apparaîtront ici',
               style: TextStyle(
                 color: Colors.grey[500],
                 fontSize: 14,
               ),
             ),
           ],
         ),
       );
     }
 
     return Column(
       children: mockReservations.map((reservation) {
         final isLast = mockReservations.indexOf(reservation) == mockReservations.length - 1;
         return Column(
           children: [
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.grey[50],
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: Colors.grey[200]!),
               ),
               child: Row(
                 children: [
                   Container(
                     width: 40,
                     height: 40,
                     decoration: BoxDecoration(
                       color: reservation['status'] == 'Récupéré' 
                           ? Colors.green.withOpacity(0.1)
                           : Colors.red.withOpacity(0.1),
                       borderRadius: BorderRadius.circular(20),
                     ),
                     child: Icon(
                       reservation['status'] == 'Récupéré' 
                           ? Icons.check_circle
                           : Icons.cancel,
                       color: reservation['status'] == 'Récupéré' 
                           ? Colors.green
                           : Colors.red,
                       size: 20,
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           reservation['title'] as String,
                           style: const TextStyle(
                             fontWeight: FontWeight.w600,
                             fontSize: 16,
                           ),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           reservation['location'] as String,
                           style: TextStyle(
                             color: Colors.grey[600],
                             fontSize: 14,
                           ),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           _formatDate(reservation['date'] as DateTime),
                           style: TextStyle(
                             color: Colors.grey[500],
                             fontSize: 12,
                           ),
                         ),
                       ],
                     ),
                   ),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.end,
                     children: [
                       Container(
                         padding: const EdgeInsets.symmetric(
                           horizontal: 8,
                           vertical: 4,
                         ),
                         decoration: BoxDecoration(
                           color: reservation['status'] == 'Récupéré' 
                               ? Colors.green.withOpacity(0.1)
                               : Colors.red.withOpacity(0.1),
                           borderRadius: BorderRadius.circular(12),
                         ),
                         child: Text(
                           reservation['status'] as String,
                           style: TextStyle(
                             color: reservation['status'] == 'Récupéré' 
                                 ? Colors.green[700]
                                 : Colors.red[700],
                             fontSize: 12,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                       ),
                       const SizedBox(height: 4),
                       Text(
                         'Économie: ${reservation['savings']}',
                         style: TextStyle(
                           color: Colors.grey[600],
                           fontSize: 12,
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                     ],
                   ),
                 ],
               ),
             ),
             if (!isLast) const SizedBox(height: 12),
           ],
         );
       }).toList(),
     );
   }
 
   String _formatDate(DateTime date) {
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
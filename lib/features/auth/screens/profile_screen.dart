import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/simple_auth_provider.dart';
import '../../../core/services/simple_auth_service.dart';
import '../../../core/models/user_model.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';
import 'login_screen.dart';
import '../../donations/screens/donor_reservations_screen.dart';

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
    'Vegetarian',
    'Vegan',
    'Gluten-free',
    'Halal',
    'Kosher',
    'Organic only',
    'Local products',
  ];
  
  final List<String> _availableAllergies = [
    'Peanuts',
    'Tree nuts',
    'Milk',
    'Eggs',
    'Fish',
    'Shellfish',
    'Soy',
    'Gluten',
    'Sesame',
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
              content: Text('Profile updated successfully'),
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
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sign Out'),
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
        title: const Text('Delete Account'),
        content: const Text(
          'This action is irreversible. All your data will be permanently deleted.\n\nAre you sure you want to delete your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Account deletion not implemented in SimpleAuthProvider
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account deletion not available in simple mode'),
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
    print('DEBUG ProfileScreen: build() called');
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'My Profile',
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
          print('DEBUG ProfileScreen: Consumer builder called');
          print('DEBUG ProfileScreen: user = $user');
          print('DEBUG ProfileScreen: user?.role = ${user?.role}');
          
          if (user == null) {
            print('DEBUG ProfileScreen: user is null, showing not connected message');
            return const Center(
              child: Text('User not connected'),
            );
          }

          print('DEBUG ProfileScreen: Building SingleChildScrollView for user: ${user.displayName}');
          print('DEBUG ProfileScreen: User role: ${user.role}');
          print('DEBUG ProfileScreen: Is editing: $_isEditing');
          
          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile header
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
                      
                      // Name
                      Text(
                        user.displayName ?? 'User',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // User type
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
                          user.role == UserRole.donateur ? 'Donor' : 'Beneficiary',
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
                
                // Edit form or information
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
                
                // Statistics (for donors)
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
                          'My Statistics',
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
                                  'Donations Created',
                                  '${user.totalDonations}',
                                  Icons.restaurant,
                                  const Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Kg Donated',
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
                
                // Statistics (for beneficiaries)
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
                          'My Statistics',
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
                                'Reservations',
                                '${user.totalReservations ?? 0}',
                                Icons.bookmark,
                                const Color(0xFFFF9800),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Donations Received',
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
                                'Savings',
                                '0€', // TODO: Calculate savings
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
                 

                 
                 // Actions
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Reservation management (for donors)
                      if (user.role == UserRole.donateur) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, DonorReservationsScreen.routeName);
                            },
                            icon: const Icon(Icons.assignment, color: Color(0xFF4CAF50)),
                            label: const Text(
                              'Manage My Reservations',
                              style: TextStyle(color: Color(0xFF4CAF50)),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF4CAF50)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      // Sign out
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _handleSignOut,
                          icon: const Icon(Icons.logout, color: Colors.orange),
                          label: const Text(
                            'Sign Out',
                            style: TextStyle(color: Colors.orange),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Delete account
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _handleDeleteAccount,
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          label: const Text(
                            'Delete My Account',
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
            'Edit My Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Name
          AuthTextField(
            controller: _nameController,
            labelText: 'Full Name',
            prefixIcon: Icons.person_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Phone
          AuthTextField(
            controller: _phoneController,
            labelText: 'Phone',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
          ),
          
          const SizedBox(height: 16),
          
          // Address
          AuthTextField(
            controller: _addressController,
            labelText: 'Address',
            prefixIcon: Icons.location_on_outlined,
            maxLines: 2,
          ),
          
          // Beneficiary-specific fields
          Consumer<SimpleAuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.currentUser;
              if (user?.role == UserRole.beneficiaire) {
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _preferredZoneController,
                      labelText: 'Preferred Pickup Zone',
                      prefixIcon: Icons.place_outlined,
                    ),
                    
                    const SizedBox(height: 16),
                    _buildMultiSelectField(
                      'Dietary Preferences',
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
          
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                    });
                    _loadUserData(); // Reload original data
                  },
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AuthButton(
                  text: 'Save',
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
          'My Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 20),
        
        _buildInfoRow('Phone', user.phoneNumber ?? 'Not provided', Icons.phone_outlined),
        const SizedBox(height: 16),
        _buildInfoRow('Address', user.address ?? 'Not provided', Icons.location_on_outlined),
        
        // Beneficiary-specific information
        if (user.role == UserRole.beneficiaire) ...[
          const SizedBox(height: 16),
          _buildInfoRow('Preferred Zone', user.preferredPickupZone ?? 'Not provided', Icons.place_outlined),
          if (user.dietaryPreferences != null && user.dietaryPreferences!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow('Dietary Preferences', user.dietaryPreferences!.join(', '), Icons.restaurant_outlined),
          ],
          if (user.allergies != null && user.allergies!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoRow('Allergies', user.allergies!.join(', '), Icons.warning_outlined),
          ],
        ],
        
        const SizedBox(height: 16),
        _buildInfoRow('Member since', _formatDate(user.createdAt), Icons.calendar_today_outlined),
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
     // TODO: Get real reservations from service
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
         'location': 'Dupont Bakery',
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
               'No reservations at the moment',
               style: TextStyle(
                 color: Colors.grey[600],
                 fontSize: 16,
               ),
             ),
             const SizedBox(height: 8),
             Text(
               'Your reservations will appear here',
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
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
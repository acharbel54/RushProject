import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/donation_model.dart';
import '../../../core/providers/donation_provider.dart';
import '../../donations/widgets/donation_card.dart';
import '../../donations/screens/donation_detail_screen.dart';

class DiscoverScreen extends StatefulWidget {
  static const String routeName = '/discover';
  
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Toutes';
  List<DonationModel> _filteredDonations = [];
  bool _isLoading = true;

  final List<String> _categories = [
    'Toutes',
    'Fruits',
    'Légumes', 
    'Produits laitiers',
    'Viande',
    'Poisson',
    'Céréales',
    'Conserves',
    'Boulangerie',
    'Autre',
  ];



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDonations();
    });
  }

  Future<void> _loadDonations() async {
    final donationProvider = Provider.of<DonationProvider>(context, listen: false);
    await donationProvider.loadDonations();
    _filterDonations();
  }

  void _filterDonations() {
    final donationProvider = Provider.of<DonationProvider>(context, listen: false);
    final allDonations = donationProvider.donations;
    
    setState(() {
      _filteredDonations = allDonations.where((donation) {
        bool matchesCategory = _selectedCategory == 'Toutes' || 
                              _getCategoryDisplayName(donation.category) == _selectedCategory;
        bool matchesSearch = _searchController.text.isEmpty ||
                            donation.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                            donation.description.toLowerCase().contains(_searchController.text.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  String _getCategoryDisplayName(DonationCategory category) {
    switch (category) {
      case DonationCategory.fruits:
        return 'Fruits';
      case DonationCategory.legumes:
        return 'Légumes';
      case DonationCategory.produits_laitiers:
        return 'Produits laitiers';
      case DonationCategory.viande:
        return 'Viande';
      case DonationCategory.poisson:
        return 'Poisson';
      case DonationCategory.cereales:
        return 'Céréales';
      case DonationCategory.conserves:
        return 'Conserves';
      case DonationCategory.boulangerie:
        return 'Boulangerie';
      case DonationCategory.autre:
        return 'Autre';
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Découvrir',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<DonationProvider>(
        builder: (context, donationProvider, child) {
          return Column(
            children: [
              // Barre de recherche et filtres
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Barre de recherche
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => _filterDonations(),
                      decoration: InputDecoration(
                        hintText: 'Rechercher des dons...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Filtres par catégorie
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = category == _selectedCategory;
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                category,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                                _filterDonations();
                              },
                              backgroundColor: Colors.grey[200],
                              selectedColor: const Color(0xFFFF9800),
                              checkmarkColor: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // Liste des dons
              Expanded(
                child: donationProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredDonations.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Aucun don trouvé',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Essayez de modifier vos critères de recherche',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadDonations,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredDonations.length,
                              itemBuilder: (context, index) {
                                final donation = _filteredDonations[index];
                                return _buildDonationCard(donation);
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDonationCard(DonationModel donation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: DonationCard(
        donation: donation,
        onTap: () {
          Navigator.pushNamed(
            context,
            DonationDetailScreen.routeName,
            arguments: donation.id,
          );
        },
        onReserve: () {
          // Callback optionnel pour rafraîchir la liste après réservation
          _loadDonations();
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
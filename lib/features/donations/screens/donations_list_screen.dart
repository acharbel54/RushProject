import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/donation_provider.dart';
import '../../../core/providers/simple_auth_provider.dart';
import '../../../core/models/donation_model.dart';
import '../../../core/models/user_model.dart';
import '../widgets/donation_card.dart';
import '../../../shared/widgets/loading_overlay.dart';
import 'create_donation_screen.dart';

class DonationsListScreen extends StatefulWidget {
  static const String routeName = '/donations-list';
  
  const DonationsListScreen({Key? key}) : super(key: key);

  @override
  State<DonationsListScreen> createState() => _DonationsListScreenState();
}

class _DonationsListScreenState extends State<DonationsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  bool _showMyDonations = false;
  
  final List<Map<String, String>> _categories = [
    {'value': 'all', 'label': 'Toutes'},
    {'value': 'fruits_legumes', 'label': 'Fruits et légumes'},
    {'value': 'produits_laitiers', 'label': 'Produits laitiers'},
    {'value': 'viandes_poissons', 'label': 'Viandes et poissons'},
    {'value': 'cereales_feculents', 'label': 'Céréales et féculents'},
    {'value': 'conserves_pates', 'label': 'Conserves et pâtes'},
    {'value': 'boulangerie', 'label': 'Boulangerie'},
    {'value': 'boissons', 'label': 'Boissons'},
    {'value': 'autres', 'label': 'Autres'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDonations();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() {
      _showMyDonations = _tabController.index == 1;
    });
    _loadDonations();
  }

  Future<void> _loadDonations() async {
    final donationProvider = Provider.of<DonationProvider>(context, listen: false);
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    
    if (_showMyDonations && authProvider.currentUser != null) {
      await donationProvider.fetchUserDonations(authProvider.currentUser!.id);
    } else {
      if (_selectedCategory == 'all') {
        await donationProvider.fetchDonations();
      } else {
        await donationProvider.searchDonationsByCategory(_selectedCategory);
      }
    }
  }

  Future<void> _refreshDonations() async {
    await _loadDonations();
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    if (!_showMyDonations) {
      _loadDonations();
    }
  }

  void _onSearchChanged(String query) {
    // Implémentation de la recherche en temps réel
    // Pour l'instant, on peut filtrer localement
    setState(() {});
  }

  List<DonationModel> _getFilteredDonations(List<DonationModel> donations) {
    if (_searchController.text.isEmpty) {
      return donations;
    }
    
    final query = _searchController.text.toLowerCase();
    return donations.where((donation) {
      return donation.title.toLowerCase().contains(query) ||
             donation.description.toLowerCase().contains(query) ||
             donation.category.name.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<SimpleAuthProvider>(context);
    final isDonor = authProvider.currentUser?.role == UserRole.donateur;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dons disponibles'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(
              icon: Icon(Icons.list),
              text: 'Tous les dons',
            ),
            if (isDonor)
              const Tab(
                icon: Icon(Icons.person),
                text: 'Mes dons',
              )
            else
              const Tab(
                icon: Icon(Icons.bookmark),
                text: 'Mes réservations',
              ),
          ],
        ),
        actions: [
          if (isDonor && _showMyDonations)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).pushNamed(CreateDonationScreen.routeName);
              },
            ),
        ],
      ),
      body: Consumer<DonationProvider>(
        builder: (context, donationProvider, child) {
          return LoadingOverlay(
            isLoading: donationProvider.isLoading,
            child: Column(
              children: [
                // Barre de recherche et filtres
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.grey[50],
                  child: Column(
                    children: [
                      // Barre de recherche
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Rechercher des dons...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchChanged('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: _onSearchChanged,
                      ),
                      
                      if (!_showMyDonations) ...[
                        const SizedBox(height: 12),
                        
                        // Filtres par catégorie
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              final isSelected = _selectedCategory == category['value'];
                              
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: FilterChip(
                                  label: Text(category['label']!),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    _onCategoryChanged(category['value']!);
                                  },
                                  backgroundColor: Colors.white,
                                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                  checkmarkColor: Theme.of(context).primaryColor,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Liste des donations
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshDonations,
                    child: _buildDonationsList(donationProvider),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: isDonor && !_showMyDonations
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).pushNamed(CreateDonationScreen.routeName);
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildDonationsList(DonationProvider donationProvider) {
    List<DonationModel> donations;
    
    if (_showMyDonations) {
      donations = donationProvider.userDonations;
    } else {
      donations = donationProvider.donations;
    }
    
    final filteredDonations = _getFilteredDonations(donations);
    
    if (donationProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              donationProvider.error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshDonations,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    
    if (filteredDonations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showMyDonations ? Icons.inventory_2_outlined : Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _showMyDonations 
                  ? 'Aucun don créé'
                  : _searchController.text.isNotEmpty
                      ? 'Aucun résultat trouvé'
                      : 'Aucun don disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showMyDonations
                  ? 'Créez votre premier don pour aider la communauté'
                  : _searchController.text.isNotEmpty
                      ? 'Essayez avec d\'autres mots-clés'
                      : 'Revenez plus tard ou créez un don',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            if (_showMyDonations) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(CreateDonationScreen.routeName);
                },
                child: const Text('Créer un don'),
              ),
            ],
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredDonations.length,
      itemBuilder: (context, index) {
        final donation = filteredDonations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: DonationCard(
            donation: donation,
            showActions: _showMyDonations,
            onReserve: _showMyDonations ? null : () => _reserveDonation(donation),
            onEdit: _showMyDonations ? () => _editDonation(donation) : null,
            onDelete: _showMyDonations ? () => _deleteDonation(donation) : null,
          ),
        );
      },
    );
  }

  Future<void> _reserveDonation(DonationModel donation) async {
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    final donationProvider = Provider.of<DonationProvider>(context, listen: false);
    
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour réserver un don'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la réservation'),
          content: Text(
            'Voulez-vous réserver "${donation.title}" ?\n\n'
            'Vous devrez récupérer ce don à l\'adresse indiquée.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Réserver'),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      final success = await donationProvider.reserveDonation(
        donation.id,
        authProvider.currentUser!.id,
      );
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Don réservé avec succès!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(donationProvider.error ?? 'Erreur lors de la réservation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _editDonation(DonationModel donation) {
    // TODO: Naviguer vers l'écran d'édition
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité d\'édition à venir'),
      ),
    );
  }

  Future<void> _deleteDonation(DonationModel donation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
            'Voulez-vous vraiment supprimer "${donation.title}" ?\n\n'
            'Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      final donationProvider = Provider.of<DonationProvider>(context, listen: false);
      final success = await donationProvider.deleteDonation(donation.id);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Don supprimé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(donationProvider.error ?? 'Erreur lors de la suppression'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
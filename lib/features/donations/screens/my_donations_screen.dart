import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/simple_auth_provider.dart';
import '../../../core/providers/donation_provider.dart';
import '../../../core/models/donation_model.dart';
import '../../../shared/widgets/loading_overlay.dart';
import 'create_donation_screen.dart';
import 'donation_detail_screen.dart';

class MyDonationsScreen extends StatefulWidget {
  const MyDonationsScreen({Key? key}) : super(key: key);

  @override
  State<MyDonationsScreen> createState() => _MyDonationsScreenState();
}

class _MyDonationsScreenState extends State<MyDonationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMyDonations();
    });
  }

  Future<void> _loadMyDonations() async {
    final donationProvider = Provider.of<DonationProvider>(context, listen: false);
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      await donationProvider.fetchUserDonations(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes dons'),
        elevation: 0,
        actions: [
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
            child: RefreshIndicator(
              onRefresh: _loadMyDonations,
              child: _buildDonationsList(donationProvider),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(CreateDonationScreen.routeName);
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDonationsList(DonationProvider donationProvider) {
    final donations = donationProvider.userDonations;

    if (donations.isEmpty && !donationProvider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun don créé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez par créer votre premier don',
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(CreateDonationScreen.routeName);
              },
              icon: const Icon(Icons.add),
              label: const Text('Créer un don'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: donations.length,
      itemBuilder: (context, index) {
        final donation = donations[index];
        return _buildDonationCard(donation);
      },
    );
  }

  Widget _buildDonationCard(DonationModel donation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            DonationDetailScreen.routeName,
            arguments: donation.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      donation.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(donation.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(donation.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                donation.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      donation.address,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.schedule_outlined,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${donation.createdAt.day}/${donation.createdAt.month}/${donation.createdAt.year}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(DonationStatus status) {
    switch (status) {
      case DonationStatus.disponible:
        return const Color(0xFF4CAF50);
      case DonationStatus.reserve:
        return const Color(0xFFFF9800);
      case DonationStatus.recupere:
        return const Color(0xFF2196F3);
      case DonationStatus.expire:
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(DonationStatus status) {
    switch (status) {
      case DonationStatus.disponible:
        return 'Disponible';
      case DonationStatus.reserve:
        return 'Réservé';
      case DonationStatus.recupere:
        return 'Récupéré';
      case DonationStatus.expire:
        return 'Expiré';
      default:
        return status.name;
    }
  }
}
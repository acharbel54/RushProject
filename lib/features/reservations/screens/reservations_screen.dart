import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/reservation_provider.dart';
import '../../../core/providers/simple_auth_provider.dart';
import '../../../core/models/reservation_model.dart';
import '../../../core/models/donation_model.dart';
import '../../../core/utils/date_utils.dart';
import '../widgets/reservation_card.dart';
import '../../donations/screens/donation_detail_screen.dart';

class ReservationsScreen extends StatefulWidget {
  static const String routeName = '/reservations';
  
  const ReservationsScreen({Key? key}) : super(key: key);

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadReservations() {
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
    
    if (authProvider.currentUser != null) {
      reservationProvider.fetchUserReservations(authProvider.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mes Réservations',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (index) {
            setState(() {
              switch (index) {
                case 0:
                  _selectedStatus = 'all';
                  break;
                case 1:
                  _selectedStatus = 'pending';
                  break;
                case 2:
                  _selectedStatus = 'confirmed';
                  break;
                case 3:
                  _selectedStatus = 'completed';
                  break;
                case 4:
                  _selectedStatus = 'cancelled';
                  break;
              }
            });
          },
          tabs: const [
            Tab(text: 'Toutes'),
            Tab(text: 'En attente'),
            Tab(text: 'Confirmées'),
            Tab(text: 'Terminées'),
            Tab(text: 'Annulées'),
          ],
        ),
      ),
      body: Consumer<ReservationProvider>(
        builder: (context, reservationProvider, child) {
          if (reservationProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            );
          }

          if (reservationProvider.error != null) {
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
                    reservationProvider.error!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadReservations,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          final filteredReservations = _getFilteredReservations(
            reservationProvider.userReservations,
          );

          if (filteredReservations.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadReservations();
            },
            color: const Color(0xFF4CAF50),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredReservations.length,
              itemBuilder: (context, index) {
                final reservation = filteredReservations[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FutureBuilder<Map<String, dynamic>?>(
                    future: _getReservationWithDonation(reservation),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError || !snapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final data = snapshot.data!;
                      final donation = data['donation'] as DonationModel;

                      return ReservationCard(
                        reservation: reservation,
                        donation: donation,
                        onTap: () => _navigateToDetail(reservation, donation),
                        onCancel: reservation.status == 'pending'
                            ? () => _cancelReservation(reservation.id)
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  List<ReservationModel> _getFilteredReservations(List<ReservationModel> reservations) {
    if (_selectedStatus == 'all') {
      return reservations;
    }
    return reservations.where((r) => r.status == _selectedStatus).toList();
  }

  Future<Map<String, dynamic>?> _getReservationWithDonation(
    ReservationModel reservation,
  ) async {
    try {
      final reservationProvider = Provider.of<ReservationProvider>(
        context,
        listen: false,
      );
      
      final results = await reservationProvider.getReservationsWithDonations(
        reservation.beneficiaryId,
      );
      
      final result = results.firstWhere(
        (item) => (item['reservation'] as ReservationModel).id == reservation.id,
        orElse: () => {},
      );
      
      return result.isNotEmpty ? result : null;
    } catch (e) {
      return null;
    }
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;
    IconData icon;

    switch (_selectedStatus) {
      case 'pending':
        message = 'Aucune réservation en attente';
        subtitle = 'Vos nouvelles réservations apparaîtront ici';
        icon = Icons.schedule;
        break;
      case 'confirmed':
        message = 'Aucune réservation confirmée';
        subtitle = 'Les réservations confirmées par les donateurs apparaîtront ici';
        icon = Icons.check_circle_outline;
        break;
      case 'completed':
        message = 'Aucune réservation terminée';
        subtitle = 'Vos dons récupérés apparaîtront ici';
        icon = Icons.done_all;
        break;
      case 'cancelled':
        message = 'Aucune réservation annulée';
        subtitle = 'Les réservations annulées apparaîtront ici';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'Aucune réservation';
        subtitle = 'Commencez par réserver un don disponible';
        icon = Icons.bookmark_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (_selectedStatus == 'all') ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/donations');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Découvrir les dons'),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToDetail(ReservationModel reservation, DonationModel donation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DonationDetailScreen(
          donationId: donation.id,
        ),
      ),
    );
  }

  Future<void> _cancelReservation(String reservationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette réservation ? '
          'Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reservationProvider = Provider.of<ReservationProvider>(
        context,
        listen: false,
      );
      
      final success = await reservationProvider.cancelReservation(reservationId);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réservation annulée avec succès'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                reservationProvider.error ?? 'Erreur lors de l\'annulation',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/simple_auth_provider.dart';
import '../../../core/providers/reservation_provider.dart';
import '../../../core/models/donation_model.dart';
import '../../../core/models/reservation_model.dart';
import '../../donations/screens/donation_detail_screen.dart';

import '../screens/reservation_detail_screen.dart';

class ReservationsScreen extends StatefulWidget {
  static const String routeName = '/reservations';
  
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  List<Map<String, dynamic>> _userReservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserReservations();
    });
  }

  Future<void> _loadUserReservations() async {
    print('DEBUG ReservationsScreen: _loadUserReservations appelée');
    setState(() {
      _isLoading = true;
    });
    
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
    
    final currentUser = authProvider.currentUser;
    print('DEBUG ReservationsScreen: currentUser = ${currentUser?.id}');
    
    if (currentUser != null) {
      print('DEBUG ReservationsScreen: Appel de getReservationsWithDonations pour ${currentUser.id}');
      final reservationsWithDonations = await reservationProvider.getReservationsWithDonations(currentUser.id);
      print('DEBUG ReservationsScreen: Réservations reçues: ${reservationsWithDonations.length}');
      
      setState(() {
        _userReservations = reservationsWithDonations;
        _isLoading = false;
      });
      
      print('DEBUG ReservationsScreen: État mis à jour, _userReservations.length = ${_userReservations.length}');
    } else {
      print('DEBUG ReservationsScreen: Aucun utilisateur connecté');
      setState(() {
        _userReservations = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Réservations',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            )
          : _userReservations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadUserReservations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _userReservations.length,
                    itemBuilder: (context, index) {
                      final reservationData = _userReservations[index];
                      final reservation = reservationData['reservation'] as ReservationModel;
                      final donation = reservationData['donation'] as DonationModel;
                      return _buildReservationCard(reservation, donation);
                    },
                  ),
                ),
    );
  }

  Widget _buildReservationCard(ReservationModel reservation, DonationModel donation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DonationDetailScreen(
                  donationId: donation.id,
                ),
              ),
            );
          },
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
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(reservation.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        reservation.statusDisplayText,
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
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        donation.address,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Réservé le ${_formatDate(reservation.createdAt)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (reservation.status == ReservationStatus.pending) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _cancelReservation(reservation.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Annuler la réservation'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune réservation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par réserver un don dans la section Découvrir',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
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
      if (!mounted) return;
      
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
          _loadUserReservations(); // Recharger la liste
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

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.confirmed:
        return Colors.blue;
      case ReservationStatus.completed:
        return Colors.green;
      case ReservationStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../../../core/providers/reservation_provider.dart';
import '../../../core/providers/simple_auth_provider.dart';
import '../../../core/models/reservation_model.dart';
import '../../../core/models/donation_model.dart';
import '../../../shared/utils/date_utils.dart';
import '../../donations/screens/donation_detail_screen.dart';
import '../../../services/local_image_service.dart';

class ReservationDetailScreen extends StatefulWidget {
  final String reservationId;

  const ReservationDetailScreen({
    Key? key,
    required this.reservationId,
  }) : super(key: key);

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  ReservationModel? _reservation;
  DonationModel? _donation;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReservationDetails();
  }

  Future<void> _loadReservationDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final reservationProvider = Provider.of<ReservationProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);

      // Récupérer la réservation
      final reservation = await reservationProvider.getReservationById(
        widget.reservationId,
      );

      if (reservation == null) {
        setState(() {
          _error = 'Réservation introuvable';
          _isLoading = false;
        });
        return;
      }

      // Récupérer les détails avec le don
      final results = await reservationProvider.getReservationsWithDonations(
        authProvider.currentUser!.id,
      );

      final result = results.firstWhere(
        (item) => (item['reservation'] as ReservationModel).id == reservation.id,
        orElse: () => {},
      );

      if (result.isNotEmpty) {
        setState(() {
          _reservation = result['reservation'] as ReservationModel;
          _donation = result['donation'] as DonationModel;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Impossible de charger les détails';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Détails de la réservation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_reservation != null && _donation != null)
            IconButton(
              onPressed: () => _navigateToDonationDetail(),
              icon: const Icon(Icons.info_outline),
              tooltip: 'Voir le don',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
        ),
      );
    }

    if (_error != null) {
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
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadReservationDetails,
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

    if (_reservation == null || _donation == null) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildDonationCard(),
          const SizedBox(height: 16),
          _buildReservationInfoCard(),
          const SizedBox(height: 16),
          _buildPickupInfoCard(),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    Color backgroundColor;
    Color textColor;
    String statusText;
    IconData icon;
    String description;

    switch (_reservation!.status) {
      case 'pending':
        backgroundColor = Colors.orange[50]!;
        textColor = Colors.orange[800]!;
        statusText = 'En attente de confirmation';
        icon = Icons.schedule;
        description = 'Votre réservation a été envoyée au donateur. '
            'Vous recevrez une notification dès qu\'elle sera confirmée.';
        break;
      case 'confirmed':
        backgroundColor = Colors.blue[50]!;
        textColor = Colors.blue[800]!;
        statusText = 'Réservation confirmée';
        icon = Icons.check_circle;
        description = 'Le donateur a confirmé votre réservation. '
            'Vous pouvez maintenant organiser la récupération.';
        break;
      case 'completed':
        backgroundColor = Colors.green[50]!;
        textColor = Colors.green[800]!;
        statusText = 'Don récupéré';
        icon = Icons.done_all;
        description = 'Vous avez récupéré ce don avec succès. '
            'Merci de contribuer à la lutte contre le gaspillage !';
        break;
      case 'cancelled':
        backgroundColor = Colors.red[50]!;
        textColor = Colors.red[800]!;
        statusText = 'Réservation annulée';
        icon = Icons.cancel;
        description = 'Cette réservation a été annulée.';
        break;
      default:
        backgroundColor = Colors.grey[50]!;
        textColor = Colors.grey[800]!;
        statusText = 'Statut inconnu';
        icon = Icons.help;
        description = 'Statut de la réservation non reconnu.';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: textColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Don réservé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildDonationImage(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _donation!.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _donation!.category.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.scale,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _donation!.quantity,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Expire ${AppDateUtils.formatDate(_donation!.expirationDate)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_donation!.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _donation!.description,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReservationInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations de réservation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.schedule,
              'Date de réservation',
              AppDateUtils.formatDateTime(_reservation!.createdAt),
            ),
            if (_reservation!.notes != null && _reservation!.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.note,
                'Notes',
                _reservation!.notes!,
              ),
            ],
            if (_reservation!.completedAt != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.check_circle,
                'Date de récupération',
                AppDateUtils.formatDateTime(_reservation!.completedAt!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPickupInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lieu de récupération',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _donation!.address,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openMap,
                icon: const Icon(Icons.map),
                label: const Text('Voir sur la carte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final buttons = <Widget>[];

    if (_reservation!.status == 'pending') {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _cancelReservation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Annuler la réservation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    if (_reservation!.status == 'confirmed') {
      buttons.add(
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _markAsCompleted,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Marquer comme récupéré',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: buttons,
    );
  }

  Widget _buildDonationImage() {
    if (_donation!.imageUrls.isNotEmpty) {
      final String imageUrl = _donation!.imageUrls.first;
      
      // Vérifier si c'est un chemin local (commence par assets/) ou une URL
      if (imageUrl.startsWith('assets/')) {
        // Image locale dans le dossier assets
        return FutureBuilder<String>(
          future: LocalImageService.getAbsolutePath(imageUrl),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.file(
                File(snapshot.data!),
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage();
                },
              );
            } else if (snapshot.hasError) {
              return _buildPlaceholderImage();
            } else {
              return Container(
                width: 100,
                height: 100,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
          },
        );
      } else {
        // Image réseau (URL)
        return Image.network(
          imageUrl,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholderImage();
          },
        );
      }
    }
    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.fastfood,
        size: 40,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToDonationDetail() {
    Navigator.of(context).pushNamed(
      DonationDetailScreen.routeName,
      arguments: _donation!.id,
    );
  }

  void _openMap() async {
    final address = Uri.encodeComponent(_donation!.address);
    final url = 'https://www.google.com/maps/search/?api=1&query=$address';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir la carte'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelReservation() async {
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
      
      final success = await reservationProvider.cancelReservation(
        _reservation!.id,
      );
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réservation annulée avec succès'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          Navigator.of(context).pop();
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

  Future<void> _markAsCompleted() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la récupération'),
        content: const Text(
          'Confirmez-vous avoir récupéré ce don ? '
          'Cette action marquera la réservation comme terminée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('Oui, confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reservationProvider = Provider.of<ReservationProvider>(
        context,
        listen: false,
      );
      
      final success = await reservationProvider.completeReservation(
        _reservation!.id,
      );
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Don marqué comme récupéré !'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
          _loadReservationDetails(); // Recharger les détails
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                reservationProvider.error ?? 'Erreur lors de la confirmation',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
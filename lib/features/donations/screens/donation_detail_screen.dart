import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/donation_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/donation.dart';
import '../../../core/models/user_model.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/utils/date_utils.dart';

class DonationDetailScreen extends StatefulWidget {
  static const String routeName = '/donation-detail';
  
  final String donationId;
  
  const DonationDetailScreen({
    Key? key,
    required this.donationId,
  }) : super(key: key);

  @override
  State<DonationDetailScreen> createState() => _DonationDetailScreenState();
}

class _DonationDetailScreenState extends State<DonationDetailScreen> {
  Donation? donation;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadDonation();
  }

  Future<void> _loadDonation() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final donationProvider = Provider.of<DonationProvider>(context, listen: false);
      final loadedDonation = await donationProvider.getDonationById(widget.donationId);
      
      if (mounted) {
        setState(() {
          donation = loadedDonation;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Détails du don'),
        ),
        body: const LoadingOverlay(
          isLoading: true,
          child: SizedBox.expand(),
        ),
      );
    }

    if (error != null || donation == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Détails du don'),
        ),
        body: Center(
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
                'Don introuvable',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error ?? 'Ce don n\'existe plus ou a été supprimé',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer2<AuthProvider, DonationProvider>(
      builder: (context, authProvider, donationProvider, child) {
        final currentUser = authProvider.currentUser;
        final isOwner = currentUser?.id == donation!.donorId;
        final canReserve = currentUser != null && 
                          !isOwner && 
                          donation!.status == 'available' &&
                          currentUser.role == UserRole.beneficiaire;
        
        return Scaffold(
          body: LoadingOverlay(
            isLoading: donationProvider.isLoading,
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: _buildContent(context, isOwner, canReserve),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomActions(
            context, 
            authProvider, 
            donationProvider, 
            isOwner, 
            canReserve
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar() {
    final isExpired = AppDateUtils.isExpired(donation!.expirationDate);
    final isExpiringSoon = AppDateUtils.isExpiringSoon(donation!.expirationDate);
    
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            (donation!.imageUrl?.isNotEmpty ?? false)
                ? Image.network(
                    donation!.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderImage();
                    },
                  )
                : _buildPlaceholderImage(),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            
            // Status badges
            Positioned(
              top: 100,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusBadge(),
                  if (isExpired || isExpiringSoon) ...[
                    const SizedBox(height: 8),
                    _buildExpirationBadge(isExpired),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 64,
            color: Colors.grey[500],
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune image',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isOwner, bool canReserve) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre et catégorie
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  donation!.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _buildCategoryChip(theme),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Informations principales
          _buildInfoSection(
            'Informations',
            [
              _buildInfoRow(
                Icons.inventory_2_outlined,
                'Quantité',
                '${donation!.quantity} ${donation!.unit}',
                theme.colorScheme.primary,
              ),
              _buildInfoRow(
                Icons.schedule,
                'Date d\'expiration',
                DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(donation!.expirationDate),
                AppDateUtils.isExpired(donation!.expirationDate)
                    ? Colors.red
                    : AppDateUtils.isExpiringSoon(donation!.expirationDate)
                        ? Colors.orange
                        : Colors.grey[600],
              ),
              _buildInfoRow(
                Icons.access_time,
                'Publié',
                AppDateUtils.getRelativeTime(donation!.createdAt),
                Colors.grey[600],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Description
          if (donation!.description.isNotEmpty) ...[
            _buildInfoSection(
              'Description',
              [
                Text(
                  donation!.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          
          // Localisation
          _buildInfoSection(
            'Lieu de récupération',
            [
              _buildInfoRow(
                Icons.location_on,
                'Adresse',
                donation!.address,
                Colors.grey[600],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openMaps,
                  icon: const Icon(Icons.map),
                  label: const Text('Voir sur la carte'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Informations du donateur (si pas propriétaire)
          if (!isOwner) ...[
            _buildInfoSection(
              'Donateur',
              [
                _buildInfoRow(
                  Icons.person,
                  'Publié par',
                  'Donateur anonyme', // TODO: Récupérer le nom du donateur si autorisé
                  Colors.grey[600],
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          
          // Actions du propriétaire
          if (isOwner) ...[
            _buildOwnerActions(),
            const SizedBox(height: 24),
          ],
          
          // Espace pour le bottom navigation
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color? color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: color ?? Colors.grey[600],
          ),
          const SizedBox(width: 12),
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
                  style: TextStyle(
                    fontSize: 14,
                    color: color ?? Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    switch (donation!.status) {
      case 'available':
        backgroundColor = Colors.green;
        textColor = Colors.white;
        text = 'Disponible';
        icon = Icons.check_circle;
        break;
      case 'reserved':
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        text = 'Réservé';
        icon = Icons.bookmark;
        break;
      case 'collected':
        backgroundColor = Colors.grey;
        textColor = Colors.white;
        text = 'Récupéré';
        icon = Icons.done_all;
        break;
      default:
        backgroundColor = Colors.grey;
        textColor = Colors.white;
        text = 'Inconnu';
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpirationBadge(bool isExpired) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red : Colors.orange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Icons.warning : Icons.schedule,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            isExpired ? 'Expiré' : 'Expire bientôt',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(ThemeData theme) {
    final categoryLabels = {
      'fruits_legumes': 'Fruits & Légumes',
      'produits_laitiers': 'Produits laitiers',
      'viandes_poissons': 'Viandes & Poissons',
      'cereales_feculents': 'Céréales & Féculents',
      'conserves_pates': 'Conserves & Pâtes',
      'boulangerie': 'Boulangerie',
      'boissons': 'Boissons',
      'autres': 'Autres',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Text(
        categoryLabels[donation!.type.name] ?? donation!.type.name,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildOwnerActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _editDonation,
                icon: const Icon(Icons.edit),
                label: const Text('Modifier'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _deleteDonation,
                icon: const Icon(Icons.delete),
                label: const Text('Supprimer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
        if (donation!.status == DonationStatus.reserve) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _markAsCollected,
              icon: const Icon(Icons.done_all),
              label: const Text('Marquer comme récupéré'),
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildBottomActions(
    BuildContext context,
    AuthProvider authProvider,
    DonationProvider donationProvider,
    bool isOwner,
    bool canReserve,
  ) {
    if (!canReserve) return null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _reserveDonation(authProvider, donationProvider),
          icon: const Icon(Icons.bookmark_add),
          label: const Text('Réserver ce don'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Future<void> _openMaps() async {
    final address = Uri.encodeComponent(donation!.address);
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

  Future<void> _reserveDonation(
    AuthProvider authProvider,
    DonationProvider donationProvider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la réservation'),
          content: Text(
            'Voulez-vous réserver "${donation!.title}" ?\n\n'
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
        donation!.id,
        authProvider.currentUser!.id,
      );
      
      if (success) {
        setState(() {
          donation = donation!.copyWith(status: DonationStatus.reserve);
        });
        
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

  void _editDonation() {
    // TODO: Naviguer vers l'écran d'édition
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité d\'édition à venir'),
      ),
    );
  }

  Future<void> _deleteDonation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text(
            'Voulez-vous vraiment supprimer "${donation!.title}" ?\n\n'
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
      final success = await donationProvider.deleteDonation(donation!.id);
      
      if (success) {
        if (mounted) {
          Navigator.of(context).pop();
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

  Future<void> _markAsCollected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Marquer comme récupéré'),
          content: const Text(
            'Confirmez-vous que ce don a été récupéré par le bénéficiaire ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      final donationProvider = Provider.of<DonationProvider>(context, listen: false);
      final success = await donationProvider.markAsCollected(donation!.id);
      
      if (success) {
        setState(() {
          donation = donation!.copyWith(status: DonationStatus.recupere);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Don marqué comme récupéré'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(donationProvider.error ?? 'Erreur lors de la mise à jour'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
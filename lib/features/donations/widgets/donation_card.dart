import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/donation_model.dart';
import '../../../shared/utils/date_utils.dart';

class DonationCard extends StatelessWidget {
  final DonationModel donation;
  final bool showActions;
  final VoidCallback? onReserve;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const DonationCard({
    Key? key,
    required this.donation,
    this.showActions = false,
    this.onReserve,
    this.onEdit,
    this.onDelete,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpiringSoon = _isExpiringSoon();
    final isExpired = _isExpired();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isExpiringSoon && !isExpired
            ? BorderSide(color: Colors.orange, width: 1)
            : isExpired
                ? BorderSide(color: Colors.red, width: 1)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image et statut
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: donation.imageUrls.isNotEmpty
                        ? Image.network(
                            donation.imageUrls.first,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderImage();
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _buildLoadingImage();
                            },
                          )
                        : _buildPlaceholderImage(),
                  ),
                ),
                
                // Badge de statut
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildStatusBadge(theme),
                ),
                
                // Badge d'expiration
                if (isExpiringSoon || isExpired)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _buildExpirationBadge(isExpired),
                  ),
              ],
            ),
            
            // Contenu
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre et catégorie
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          donation.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryChip(theme),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Quantité et unité
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        donation.quantity,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  if (donation.description.isNotEmpty) ...[
                    Text(
                      donation.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Date d'expiration
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: isExpired
                            ? Colors.red
                            : isExpiringSoon
                                ? Colors.orange
                                : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Expire le ${DateFormat('dd/MM/yyyy').format(donation.expirationDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isExpired
                              ? Colors.red
                              : isExpiringSoon
                                  ? Colors.orange
                                  : Colors.grey[600],
                          fontWeight: isExpired || isExpiringSoon
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Localisation
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          donation.address,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  // Date de création
                  const SizedBox(height: 4),
                  Text(
                    'Publié ${AppDateUtils.getRelativeTime(donation.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  
                  // Actions
                  if (showActions || onReserve != null) ...[
                    const SizedBox(height: 16),
                    _buildActionButtons(theme),
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
      width: double.infinity,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'Aucune image',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Container(
      width: double.infinity,
      color: Colors.grey[100],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    switch (donation.status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpirationBadge(bool isExpired) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isExpired ? Colors.red : Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Icons.warning : Icons.schedule,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isExpired ? 'Expiré' : 'Expire bientôt',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Text(
        categoryLabels[donation.category] ?? donation.category.name,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    if (showActions) {
      // Actions pour le propriétaire du don
      return Row(
        children: [
          if (onEdit != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Modifier'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          if (onEdit != null && onDelete != null) const SizedBox(width: 8),
          if (onDelete != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Supprimer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
        ],
      );
    } else if (onReserve != null && donation.status == 'available') {
      // Action pour réserver le don
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onReserve,
          icon: const Icon(Icons.bookmark_add, size: 16),
          label: const Text('Réserver'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  bool _isExpiringSoon() {
    final now = DateTime.now();
    final difference = donation.expirationDate.difference(now).inDays;
    return difference <= 2 && difference >= 0;
  }

  bool _isExpired() {
    final now = DateTime.now();
    return donation.expirationDate.isBefore(now);
  }
}
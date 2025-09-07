import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../core/models/donation_model.dart';
import '../../../core/providers/reservation_provider.dart';
import '../../../core/providers/simple_auth_provider.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../services/local_image_service.dart';

class DonationCard extends StatefulWidget {
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
  State<DonationCard> createState() => _DonationCardState();
}

class _DonationCardState extends State<DonationCard> {
  bool _isReserving = false;
  bool _isReserved = false;

  @override
  void initState() {
    super.initState();
    _checkReservationStatus();
  }

  void _checkReservationStatus() async {
    final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
    final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
    
    final currentUser = authProvider.currentUser;
    if (currentUser != null) {
      // Load user reservations if not already done
      if (reservationProvider.userReservations.isEmpty) {
        await reservationProvider.fetchUserReservations(currentUser.id);
      }
      
      if (mounted) {
        setState(() {
          _isReserved = reservationProvider.isDonationReservedByUser(
            widget.donation.id, 
            currentUser.id
          );
        });
      }
    }
  }

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
        onTap: widget.onTap,
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
                    child: widget.donation.imageUrls.isNotEmpty
                        ? _buildDonationImage()
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
                  // Title and category
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.donation.title,
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
                  
                  // Quantity and unit
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.donation.quantity,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  if (widget.donation.description.isNotEmpty) ...[
                    Text(
                      widget.donation.description,
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
                        'Expires on ${DateFormat('dd/MM/yyyy').format(widget.donation.expirationDate)}',
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
                          widget.donation.address,
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
                    'Published ${AppDateUtils.getRelativeTime(widget.donation.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  
                  // Actions
                  if (widget.showActions || widget.onReserve != null) ...[
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

  Widget _buildDonationImage() {
    final String imageUrl = widget.donation.imageUrls.first;
    
    // Check if it's a local path (starts with assets/) or a URL
    if (imageUrl.startsWith('assets/')) {
      // Local image in assets folder - use FutureBuilder to get absolute path
      return FutureBuilder<String>(
        future: LocalImageService.getAbsolutePath(imageUrl),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Image.file(
              File(snapshot.data!),
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholderImage();
              },
            );
          } else if (snapshot.hasError) {
            return _buildPlaceholderImage();
          } else {
            return _buildLoadingImage();
          }
        },
      );
    } else {
      // Network image (URL)
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingImage();
        },
      );
    }
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
            'No image',
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

    switch (widget.donation.status) {
      case DonationStatus.disponible:
        backgroundColor = Colors.green;
        textColor = Colors.white;
        text = 'Available';
        icon = Icons.check_circle;
        break;
      case DonationStatus.reserve:
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        text = 'Reserved';
        icon = Icons.bookmark;
        break;
      case DonationStatus.recupere:
        backgroundColor = Colors.grey;
        textColor = Colors.white;
        text = 'Collected';
        icon = Icons.done_all;
        break;
      default:
        backgroundColor = Colors.grey;
        textColor = Colors.white;
        text = 'Unknown';
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
            isExpired ? 'Expired' : 'Expires soon',
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
      'fruits_legumes': 'Fruits & Vegetables',
      'produits_laitiers': 'Dairy Products',
      'viandes_poissons': 'Meat & Fish',
      'cereales_feculents': 'Cereals & Starches',
      'conserves_pates': 'Canned & Pasta',
      'boulangerie': 'Bakery',
      'boissons': 'Beverages',
      'autres': 'Others',
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
        categoryLabels[widget.donation.category] ?? widget.donation.category.name,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    if (widget.showActions) {
      // Actions for donation owner
      return Row(
        children: [
          if (widget.onEdit != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onEdit,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          if (widget.onEdit != null && widget.onDelete != null) const SizedBox(width: 8),
          if (widget.onDelete != null)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Delete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
        ],
      );
    } else if (widget.onReserve != null && widget.donation.status == DonationStatus.disponible) {
      // Action to reserve the donation
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isReserving || _isReserved ? null : _handleReservation,
          icon: Icon(
            _isReserved ? Icons.schedule : Icons.bookmark_add, 
            size: 16
          ),
          label: Text(
            _isReserving ? 'Reserving...' : (_isReserved ? 'Pending' : 'Reserve')
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            backgroundColor: _isReserved ? Colors.orange : null,
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Future<void> _handleReservation() async {
    if (_isReserved || _isReserving) return;
    
    setState(() {
      _isReserving = true;
    });
    
    try {
      final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
      final authProvider = Provider.of<SimpleAuthProvider>(context, listen: false);
      
      final currentUser = authProvider.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You must be logged in to reserve'),
              backgroundColor: Colors.red,
            ),
        );
        setState(() {
          _isReserving = false;
        });
        return;
      }
      
      final success = await reservationProvider.createReservation(
        donationId: widget.donation.id,
        beneficiaryId: currentUser.id,
      );
      
      if (mounted) {
        if (success) {
          setState(() {
            _isReserving = false;
            _isReserved = true;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reservation created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Call the callback if provided
          if (widget.onReserve != null) {
            widget.onReserve!();
          }
        } else {
          setState(() {
            _isReserving = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reservationProvider.error ?? 'Error during reservation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isReserving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isExpiringSoon() {
    final now = DateTime.now();
    final difference = widget.donation.expirationDate.difference(now).inDays;
    return difference <= 2 && difference >= 0;
  }

  bool _isExpired() {
    final now = DateTime.now();
    return widget.donation.expirationDate.isBefore(now);
  }
}
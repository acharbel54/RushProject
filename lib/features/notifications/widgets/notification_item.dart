import 'package:flutter/material.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;
  final bool showActions;

  const NotificationItem({
    Key? key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.onDelete,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: notification.isRead ? 1 : 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: notification.isRead
            ? BorderSide.none
            : BorderSide(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: notification.isRead
                ? Colors.white
                : AppColors.primary.withOpacity(0.05),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec icône, titre et actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icône de type
                  _buildTypeIcon(),
                  const SizedBox(width: 12),
                  // Contenu principal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre et badge non lu
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!notification.isRead) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Corps du message
                        Text(
                          notification.body,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  if (showActions) _buildActions(context),
                ],
              ),
              const SizedBox(height: 12),
              // Pied avec temps et badges
              Row(
                children: [
                  // Temps relatif
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    notification.timeAgo,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  // Badges
                  ..._buildBadges(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIcon() {
    Color iconColor;
    IconData iconData;

    switch (notification.type) {
      case NotificationType.newReservation:
        iconColor = Colors.blue;
        iconData = Icons.bookmark_add;
        break;
      case NotificationType.reservationConfirmed:
        iconColor = Colors.green;
        iconData = Icons.check_circle;
        break;
      case NotificationType.reservationCancelled:
        iconColor = Colors.red;
        iconData = Icons.cancel;
        break;
      case NotificationType.reservationCompleted:
        iconColor = Colors.green;
        iconData = Icons.task_alt;
        break;
      case NotificationType.newDonation:
        iconColor = Colors.orange;
        iconData = Icons.restaurant;
        break;
      case NotificationType.donationExpiring:
        iconColor = Colors.deepOrange;
        iconData = Icons.schedule;
        break;
      case NotificationType.donationExpired:
        iconColor = Colors.grey;
        iconData = Icons.schedule;
        break;
      case NotificationType.donationUpdated:
        iconColor = Colors.blue;
        iconData = Icons.edit;
        break;
      case NotificationType.systemMessage:
        iconColor = Colors.blueGrey;
        iconData = Icons.info;
        break;
      case NotificationType.reminder:
        iconColor = Colors.purple;
        iconData = Icons.notifications;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleAction(context, value),
      icon: Icon(
        Icons.more_vert,
        color: AppColors.textSecondary,
        size: 20,
      ),
      itemBuilder: (context) => [
        if (!notification.isRead)
          const PopupMenuItem(
            value: 'mark_read',
            child: Row(
              children: [
                Icon(Icons.mark_email_read, size: 18),
                SizedBox(width: 8),
                Text('Marquer comme lue'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Supprimer', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBadges() {
    List<Widget> badges = [];

    // Badge important
    if (notification.isImportant) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.priority_high,
                size: 12,
                color: Colors.red,
              ),
              const SizedBox(width: 2),
              Text(
                'Important',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Badge récent
    if (notification.isRecent && !notification.isRead) {
      if (badges.isNotEmpty) badges.add(const SizedBox(width: 8));
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Text(
            'Nouveau',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return badges;
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'mark_read':
        onMarkAsRead?.call();
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la notification'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette notification ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

// Widget pour afficher une notification compacte (pour les listes courtes)
class CompactNotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const CompactNotificationItem({
    Key? key,
    required this.notification,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Indicateur non lu
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: notification.isRead
                    ? Colors.transparent
                    : AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            // Contenu
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Temps
            Text(
              notification.timeAgo,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
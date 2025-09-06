import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/notification_item.dart';
import '../widgets/notification_filter_chip.dart';

class NotificationsScreen extends StatefulWidget {
  static const String routeName = '/notifications';

  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  NotificationType? _selectedFilter;
  bool _showOnlyUnread = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Charger les notifications au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: AppTextStyles.heading2,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          // Bouton pour marquer toutes comme lues
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              final hasUnread = provider.notifications
                  .any((notification) => !notification.isRead);
              
              if (!hasUnread) return const SizedBox.shrink();
              
              return IconButton(
                onPressed: () => _markAllAsRead(context),
                icon: const Icon(Icons.done_all),
                tooltip: 'Marquer toutes comme lues',
              );
            },
          ),
          // Menu d'options
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20),
                    SizedBox(width: 8),
                    Text('Supprimer toutes'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 8),
                    Text('Paramètres'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(
              child: Consumer<NotificationProvider>(
                builder: (context, provider, child) {
                  final count = provider.notifications.length;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Toutes'),
                      if (count > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            Tab(
              child: Consumer<NotificationProvider>(
                builder: (context, provider, child) {
                  final count = provider.notifications
                      .where((n) => !n.isRead)
                      .length;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Non lues'),
                      if (count > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            const Tab(text: 'Importantes'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filtres
          _buildFilters(),
          // Liste des notifications
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsList(NotificationFilter.all),
                _buildNotificationsList(NotificationFilter.unread),
                _buildNotificationsList(NotificationFilter.important),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            NotificationFilterChip(
              label: 'Toutes',
              isSelected: _selectedFilter == null,
              onTap: () => setState(() => _selectedFilter = null),
            ),
            const SizedBox(width: 8),
            ...NotificationType.values.map(
              (type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: NotificationFilterChip(
                  label: _getTypeLabel(type),
                  isSelected: _selectedFilter == type,
                  onTap: () => setState(() => _selectedFilter = type),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(NotificationFilter filter) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.fetchNotifications(),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        List<NotificationModel> filteredNotifications = _filterNotifications(
          provider.notifications,
          filter,
        );

        if (filteredNotifications.isEmpty) {
          return _buildEmptyState(filter);
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchNotifications(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredNotifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notification = filteredNotifications[index];
              return NotificationItem(
                notification: notification,
                onTap: () => _handleNotificationTap(context, notification),
                onMarkAsRead: () => _markAsRead(context, notification),
                onDelete: () => _deleteNotification(context, notification),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(NotificationFilter filter) {
    String title;
    String subtitle;
    IconData icon;

    switch (filter) {
      case NotificationFilter.unread:
        title = 'Aucune notification non lue';
        subtitle = 'Toutes vos notifications ont été lues';
        icon = Icons.mark_email_read;
        break;
      case NotificationFilter.important:
        title = 'Aucune notification importante';
        subtitle = 'Les notifications importantes apparaîtront ici';
        icon = Icons.priority_high;
        break;
      default:
        title = 'Aucune notification';
        subtitle = 'Vous recevrez ici vos notifications';
        icon = Icons.notifications_none;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<NotificationModel> _filterNotifications(
    List<NotificationModel> notifications,
    NotificationFilter filter,
  ) {
    List<NotificationModel> filtered = notifications;

    // Filtrer par onglet
    switch (filter) {
      case NotificationFilter.unread:
        filtered = filtered.where((n) => !n.isRead).toList();
        break;
      case NotificationFilter.important:
        filtered = filtered.where((n) => n.isImportant).toList();
        break;
      case NotificationFilter.all:
        break;
    }

    // Filtrer par type si sélectionné
    if (_selectedFilter != null) {
      filtered = filtered.where((n) => n.type == _selectedFilter).toList();
    }

    // Trier par date (plus récent en premier)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return filtered;
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.newReservation:
        return 'Réservations';
      case NotificationType.reservationConfirmed:
        return 'Confirmées';
      case NotificationType.reservationCancelled:
        return 'Annulées';
      case NotificationType.reservationCompleted:
        return 'Terminées';
      case NotificationType.newDonation:
        return 'Nouveaux dons';
      case NotificationType.donationExpiring:
        return 'Expirent';
      case NotificationType.donationExpired:
        return 'Expirés';
      case NotificationType.donationUpdated:
        return 'Modifiés';
      case NotificationType.systemMessage:
        return 'Système';
      case NotificationType.reminder:
        return 'Rappels';
    }
  }

  void _handleNotificationTap(BuildContext context, NotificationModel notification) {
    // Marquer comme lue si pas encore lu
    if (!notification.isRead) {
      _markAsRead(context, notification);
    }

    // Naviguer selon le type de notification
    _navigateBasedOnNotification(context, notification);
  }

  void _navigateBasedOnNotification(BuildContext context, NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.newReservation:
        // Pour les donateurs, naviguer vers l'écran de gestion des réservations
        Navigator.pushNamed(context, '/donor-reservations');
        break;
      case NotificationType.reservationConfirmed:
      case NotificationType.reservationCancelled:
      case NotificationType.reservationCompleted:
        // Naviguer vers les détails de la réservation
        if (notification.data.containsKey('reservationId')) {
          Navigator.pushNamed(
            context,
            '/reservation-details',
            arguments: notification.data['reservationId'],
          );
        }
        break;
      case NotificationType.newDonation:
      case NotificationType.donationExpiring:
      case NotificationType.donationExpired:
      case NotificationType.donationUpdated:
        // Naviguer vers les détails du don
        if (notification.data.containsKey('donationId')) {
          Navigator.pushNamed(
            context,
            '/donation-details',
            arguments: notification.data['donationId'],
          );
        }
        break;
      default:
        // Afficher les détails de la notification
        _showNotificationDetails(context, notification);
    }
  }

  void _showNotificationDetails(BuildContext context, NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 16),
            Text(
              'Reçue ${notification.timeAgo}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _markAsRead(BuildContext context, NotificationModel notification) {
    context.read<NotificationProvider>().markAsRead(notification.id);
  }

  void _markAllAsRead(BuildContext context) {
    context.read<NotificationProvider>().markAllAsRead();
  }

  void _deleteNotification(BuildContext context, NotificationModel notification) {
    context.read<NotificationProvider>().deleteNotification(notification.id);
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'clear_all':
        _showClearAllDialog(context);
        break;
      case 'settings':
        Navigator.pushNamed(context, '/notification-settings');
        break;
    }
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer toutes les notifications'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer toutes vos notifications ? '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<NotificationProvider>().clearAllNotifications();
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

enum NotificationFilter {
  all,
  unread,
  important,
}
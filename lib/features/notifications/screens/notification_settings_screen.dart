import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/providers/simple_auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/notification_toggle_filter.dart';

class NotificationSettingsScreen extends StatefulWidget {
  static const String routeName = '/notification-settings';

  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // États locaux pour les paramètres
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _smsNotificationsEnabled = false;
  
  // Paramètres par type de notification
  bool _newReservationNotifications = true;
  bool _reservationUpdatesNotifications = true;
  bool _newDonationNotifications = true;
  bool _donationExpiringNotifications = true;
  bool _systemMessagesNotifications = true;
  bool _reminderNotifications = true;
  
  // Paramètres de timing
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 8, minute: 0);
  bool _quietHoursEnabled = false;
  
  // Paramètres de fréquence
  String _notificationFrequency = 'immediate'; // immediate, hourly, daily
  bool _groupSimilarNotifications = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    // Charger les paramètres depuis les préférences ou le provider
    // Pour l'instant, on utilise les valeurs par défaut
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Paramètres de notifications',
          style: AppTextStyles.heading2,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Enregistrer',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section générale
          _buildSection(
            title: 'Général',
            children: [
              _buildSwitchTile(
                title: 'Notifications push',
                subtitle: 'Recevoir des notifications sur cet appareil',
                value: _pushNotificationsEnabled,
                onChanged: (value) => setState(() => _pushNotificationsEnabled = value),
                icon: Icons.notifications,
              ),
              _buildSwitchTile(
                title: 'Notifications par email',
                subtitle: 'Recevoir des notifications par email',
                value: _emailNotificationsEnabled,
                onChanged: (value) => setState(() => _emailNotificationsEnabled = value),
                icon: Icons.email,
              ),
              _buildSwitchTile(
                title: 'Notifications SMS',
                subtitle: 'Recevoir des notifications par SMS',
                value: _smsNotificationsEnabled,
                onChanged: (value) => setState(() => _smsNotificationsEnabled = value),
                icon: Icons.sms,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Section types de notifications
          _buildSection(
            title: 'Types de notifications',
            children: [
              _buildSwitchTile(
                title: 'New Reservations',
                subtitle: 'Quand quelqu\'un réserve vos dons',
                value: _newReservationNotifications,
                onChanged: (value) => setState(() => _newReservationNotifications = value),
                icon: Icons.bookmark_add,
              ),
              _buildSwitchTile(
                title: 'Reservation Updates',
                subtitle: 'Confirmations, annulations, etc.',
                value: _reservationUpdatesNotifications,
                onChanged: (value) => setState(() => _reservationUpdatesNotifications = value),
                icon: Icons.update,
              ),
              _buildSwitchTile(
                title: 'Nouveaux dons',
                subtitle: 'Quand de nouveaux dons sont disponibles',
                value: _newDonationNotifications,
                onChanged: (value) => setState(() => _newDonationNotifications = value),
                icon: Icons.restaurant,
              ),
              _buildSwitchTile(
                title: 'Dons expirant',
                subtitle: 'Rappels avant expiration',
                value: _donationExpiringNotifications,
                onChanged: (value) => setState(() => _donationExpiringNotifications = value),
                icon: Icons.schedule,
              ),
              _buildSwitchTile(
                title: 'Messages système',
                subtitle: 'Mises à jour de l\'application',
                value: _systemMessagesNotifications,
                onChanged: (value) => setState(() => _systemMessagesNotifications = value),
                icon: Icons.info,
              ),
              _buildSwitchTile(
                title: 'Rappels',
                subtitle: 'Rappels personnalisés',
                value: _reminderNotifications,
                onChanged: (value) => setState(() => _reminderNotifications = value),
                icon: Icons.alarm,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Section heures silencieuses
          _buildSection(
            title: 'Heures silencieuses',
            children: [
              _buildSwitchTile(
                title: 'Activer les heures silencieuses',
                subtitle: 'Pas de notifications pendant ces heures',
                value: _quietHoursEnabled,
                onChanged: (value) => setState(() => _quietHoursEnabled = value),
                icon: Icons.bedtime,
              ),
              if (_quietHoursEnabled) ...[
                _buildTimeTile(
                  title: 'Début',
                  time: _quietHoursStart,
                  onChanged: (time) => setState(() => _quietHoursStart = time),
                ),
                _buildTimeTile(
                  title: 'Fin',
                  time: _quietHoursEnd,
                  onChanged: (time) => setState(() => _quietHoursEnd = time),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Section fréquence
          _buildSection(
            title: 'Fréquence et groupement',
            children: [
              _buildDropdownTile(
                title: 'Fréquence des notifications',
                subtitle: 'À quelle fréquence recevoir les notifications',
                value: _notificationFrequency,
                items: const [
                  DropdownMenuItem(value: 'immediate', child: Text('Immédiate')),
                  DropdownMenuItem(value: 'hourly', child: Text('Every hour')),
                  DropdownMenuItem(value: 'daily', child: Text('Quotidienne')),
                ],
                onChanged: (value) => setState(() => _notificationFrequency = value!),
                icon: Icons.schedule_send,
              ),
              _buildSwitchTile(
                title: 'Grouper les notifications similaires',
                subtitle: 'Combiner les notifications du même type',
                value: _groupSimilarNotifications,
                onChanged: (value) => setState(() => _groupSimilarNotifications = value),
                icon: Icons.group_work,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Section actions
          _buildSection(
            title: 'Actions',
            children: [
              _buildActionTile(
                title: 'Tester les notifications',
                subtitle: 'Envoyer une notification de test',
                icon: Icons.send,
                onTap: _sendTestNotification,
              ),
              _buildActionTile(
                title: 'Clear all notifications',
        subtitle: 'Delete all existing notifications',
                icon: Icons.clear_all,
                onTap: _clearAllNotifications,
                isDestructive: true,
              ),
              _buildActionTile(
                title: 'Réinitialiser les paramètres',
                subtitle: 'Remettre les paramètres par défaut',
                icon: Icons.restore,
                onTap: _resetSettings,
                isDestructive: true,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.primary,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge,
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildTimeTile({
    required String title,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onChanged,
  }) {
    return ListTile(
      leading: Icon(
        Icons.access_time,
        color: AppColors.primary,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge,
      ),
      trailing: TextButton(
        onPressed: () async {
          final newTime = await showTimePicker(
            context: context,
            initialTime: time,
          );
          if (newTime != null) {
            onChanged(newTime);
          }
        },
        child: Text(
          time.format(context),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required String subtitle,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.primary,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge,
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: DropdownButton<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.primary,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyLarge.copyWith(
          color: isDestructive ? AppColors.error : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  void _saveSettings() {
    // Sauvegarder les paramètres
    // Ici on pourrait utiliser SharedPreferences ou Firestore
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Paramètres sauvegardés'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    Navigator.pop(context);
  }

  void _sendTestNotification() {
    final authProvider = context.read<SimpleAuthProvider>();
    final currentUser = authProvider.currentUser;
    
    if (currentUser != null) {
      context.read<NotificationProvider>().sendTestNotification(currentUser.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification de test envoyée'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to delete all your notifications? '
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All notifications have been deleted'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
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

  void _resetSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser les paramètres'),
        content: const Text(
          'Êtes-vous sûr de vouloir remettre tous les paramètres '
          'de notification par défaut ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetToDefaults();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Paramètres réinitialisés'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      _pushNotificationsEnabled = true;
      _emailNotificationsEnabled = true;
      _smsNotificationsEnabled = false;
      _newReservationNotifications = true;
      _reservationUpdatesNotifications = true;
      _newDonationNotifications = true;
      _donationExpiringNotifications = true;
      _systemMessagesNotifications = true;
      _reminderNotifications = true;
      _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
      _quietHoursEnd = const TimeOfDay(hour: 8, minute: 0);
      _quietHoursEnabled = false;
      _notificationFrequency = 'immediate';
      _groupSimilarNotifications = true;
    });
  }
}
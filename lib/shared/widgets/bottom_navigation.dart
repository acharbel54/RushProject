import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/simple_auth_provider.dart';
import '../../core/services/simple_auth_service.dart';
import '../../core/models/user_model.dart';
import '../../core/models/reservation_model.dart';
import '../../core/services/user_service.dart';
import '../../services/json_reservation_service.dart';
import '../../services/json_auth_service.dart';
import '../../features/donations/screens/donations_list_screen.dart';
import '../../features/donations/screens/my_donations_screen.dart';
import '../../features/donations/screens/create_donation_screen.dart';
import '../../features/donations/screens/new_donation_design_screen.dart';
import '../../features/maps/screens/map_screen.dart';
import '../../features/discover/screens/discover_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/reservations/screens/reservations_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../core/providers/notification_provider.dart';

class MainNavigationScreen extends StatefulWidget {
  static const String routeName = '/home';
  
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleAuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
        
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Different pages based on user type
        print('DEBUG: User role detected: ${user.role}');
        print('DEBUG: User role string: ${user.role.toString()}');
        print('DEBUG: Is donor: ${user.role == UserRole.donateur}');
        print('DEBUG: UserRole.donateur: ${UserRole.donateur}');
        print('DEBUG: UserRole.beneficiaire: ${UserRole.beneficiaire}');
        final pages = _getPages(user.role);
        final bottomNavItems = _getBottomNavItems(user.role);

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: user.role == UserRole.donateur
                ? const Color(0xFF4CAF50)
                : const Color(0xFFFF9800),
            unselectedItemColor: Colors.grey[600],
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
            items: bottomNavItems,
          ),
          // FloatingActionButton supprimé
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        );
      },
    );
  }

  List<Widget> _getPages(UserRole userType) {
    print('DEBUG: _getPages called with userType: $userType');
    if (userType == UserRole.donateur) {
      print('DEBUG: Returning donor pages (3 pages)');
      return [
        DashboardScreen(onTabChanged: (index) => setState(() => _currentIndex = index)), // Donor home
        const MyDonationsScreen(), // My donations
        const ProfileScreen(), // Profile
      ];
    } else {
      print('DEBUG: Returning beneficiary pages (4 pages)');
      return [
        DashboardScreen(onTabChanged: (index) => setState(() => _currentIndex = index)), // Beneficiary home
        const DiscoverScreen(), // Discover (donations list)
        const ReservationsScreen(), // Reservations
        const ProfileScreen(), // Profile
      ];
    }
  }

  List<BottomNavigationBarItem> _getBottomNavItems(UserRole userType) {
    if (userType == UserRole.donateur) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_outlined),
          activeIcon: Icon(Icons.restaurant),
          label: 'My Donations',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outlined),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore_outlined),
          activeIcon: Icon(Icons.explore),
          label: 'Discover',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark_outlined),
          activeIcon: Icon(Icons.bookmark),
          label: 'Reservations',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outlined),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }
  }

  // Fonction _buildFloatingActionButton supprimée
}

// Temporary dashboard screen
class DashboardScreen extends StatelessWidget {
  final Function(int)? onTabChanged;
  
  const DashboardScreen({Key? key, this.onTabChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SimpleAuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.currentUser;
        
        if (user == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(
              'Hello ${(user.displayName ?? user.email).split(' ').first}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  final unreadCount = notificationProvider.notifications
                      .where((n) => !n.isRead)
                      .length;
                  
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.black87,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, NotificationsScreen.routeName);
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Carte de bienvenue
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: user.role == UserRole.donateur
                          ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
                          : [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (user.role == UserRole.donateur
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFFF9800))
                            .withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            user.role == UserRole.donateur
                                ? Icons.volunteer_activism
                                : Icons.people,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.role == UserRole.donateur
                                      ? 'Donor Dashboard'
                                      : 'Beneficiary Dashboard',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.role == UserRole.donateur
                                      ? 'Share your food surplus'
                                      : 'Discover available donations',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Statistiques rapides
                if (user.role == UserRole.donateur) ...[
                  const Text(
                    'My Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Donations Created',
                          user.totalDonations.toString(),
                          Icons.restaurant,
                          const Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Kg Donated',
                          '${user.totalKgDonated.toStringAsFixed(1)} kg',
                          Icons.scale,
                          const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Quick actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (user.role == UserRole.donateur) ...[
                  _buildActionCard(
                    'New Donation',
                    'Create a new food donation',
                    Icons.add_circle_outline,
                    const Color(0xFF4CAF50),
                    () {
                      Navigator.of(context).pushNamed(CreateDonationScreen.routeName);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    'My Donations',
                    'Manage my existing donations',
                    Icons.restaurant_outlined,
                    const Color(0xFF2196F3),
                    () {
                      onTabChanged?.call(1); // Navigate to My Donations section
                    },
                  ),
                ] else ...[
                  _buildActionCard(
                    'Discover',
                    'View available donations',
                    Icons.explore_outlined,
                    const Color(0xFF4CAF50),
                    () {
                      onTabChanged?.call(1); // Navigate to Discover section
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    'My Reservations',
                    'View my current reservations',
                    Icons.bookmark_outlined,
                    const Color(0xFFFF9800),
                    () {
                      onTabChanged?.call(2); // Navigate to Reservations tab
                    },
                  ),
                ],
                
                // Reservation history for beneficiaries
                if (user.role == UserRole.beneficiaire) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'Reservation History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildReservationHistory(authProvider),
                  ),
                ],
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.black26,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationHistory(SimpleAuthProvider authProvider) {
    return FutureBuilder<List<ReservationModel>>(
      future: _getReservationHistory(authProvider),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading history',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }
        
        final reservations = snapshot.data ?? [];
        
        if (reservations.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'No reservations in history',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: reservations.asMap().entries.map((entry) {
            final index = entry.key;
            final reservation = entry.value;
            final isLast = index == reservations.length - 1;

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _getStatusColor(reservation.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Icon(
                          _getStatusIcon(reservation.status),
                          color: _getStatusColor(reservation.status),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reservation.donationTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reservation.pickupAddress,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(reservation.createdAt),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            if (reservation.historyMessage != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  reservation.historyMessage!,
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(reservation.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              reservation.statusDisplayText,
                              style: TextStyle(
                                color: _getStatusColor(reservation.status),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Qty: ${reservation.donationQuantity}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isLast) const SizedBox(height: 12),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Future<List<ReservationModel>> _getReservationHistory(SimpleAuthProvider authProvider) async {
    final reservationService = JsonReservationService();
    
    try {
      print('DEBUG _getReservationHistory: Starting to load');
      
      // Utiliser SimpleAuthProvider passé en paramètre
      final currentUser = authProvider.currentUser;
      print('DEBUG _getReservationHistory: Current user: ${currentUser?.id}');
      
      if (currentUser != null) {
        print('DEBUG _getReservationHistory: Calling getUserReservations for ${currentUser.id}');
        final reservations = await reservationService.getUserReservations(currentUser.id);
        print('DEBUG _getReservationHistory: Reservations retrieved: ${reservations.length}');
        
        // Sort by creation date (most recent first)
        reservations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return reservations;
      } else {
        print('DEBUG _getReservationHistory: No user logged in');
      }
    } catch (e) {
      print('Error loading history: $e');
      print('Stack trace: ${StackTrace.current}');
    }
    
    return [];
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
  
  IconData _getStatusIcon(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Icons.schedule;
      case ReservationStatus.confirmed:
        return Icons.check_circle_outline;
      case ReservationStatus.completed:
        return Icons.check_circle;
      case ReservationStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}